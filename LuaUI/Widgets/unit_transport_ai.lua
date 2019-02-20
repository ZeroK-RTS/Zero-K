-- $Id: unit_transport_ai.lua 4460 2009-04-20 20:36:16Z licho $
include("keysym.h.lua")

function widget:GetInfo()
	return {
		name    = "Transport AI",
		desc    = "Automatically transports units going to factory waypoint.\n" ..
		          "Adds embark=call for transport and disembark=unload from transport command",
		author  = "Licho, xponen, GoogleFrog",
		date    = "1.11.2007, 9.7.2014",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true,
		handler = true
	}
end

local floatDefs = VFS.Include("LuaRules/Configs/float_defs.lua") --list of unit able to float for pickup at sea
VFS.Include("LuaRules/Configs/customcmds.h.lua")

local CONST_HEIGHT_MULTIPLIER = 3 -- how many times to multiply height difference when evaluating distance
local CONST_TRANSPORT_PICKUPTIME = 9 -- how long (in seconds) does transport land and takeoff with unit
local CONST_PRIORITY_BENEFIT = 10000 -- how much more important are priority transfers
local CONST_TRANSPORT_STOPDISTANCE = 350 -- how close by has transport be to stop the unit
local CONST_UNLOAD_RADIUS = 100 -- how big is the radious for unload command for factory transports

local idleTransports = {} -- list of idle transports key = id, value = {defid}
local activeTransports = {} -- list of transports with AI enabled
local allMyTransports = {} -- list of all transports key = id, value = {defid}
local waitingUnits = {} -- list of units waiting for traqnsport - key = unitID, {unit state, unitDef, factory}
local priorityUnits = {} -- lists of priority units waiting for key= unitId, value = state
local autoCallTransportUnits = {} -- map of units that want to be automatically transported
local toGuard = {} -- list of transports which need to guard something at the end of their queue. key = id, value = guardieeID
local toPick = {} -- list of units waiting to be picked - key = transportID, value = {id, stoppedState}
local toPickRev = {} -- list of units waiting to be picked - key = unitID, value=transportID
local storedQueue = {} -- unit keyed stored queues
local hackIdle ={} -- temp field to overcome unitIdle problem
local areaTarget = {} -- indexed by ID, used to match area command targets

local ST_ROUTE = 1 -- unit is enroute from factory
local ST_PRIORITY = 2 -- unit is in need of priority transport
local ST_STOPPED = 3 -- unit is enroute from factory but stopped

local MAX_UNITS = Game.maxUnits

local timer = 0
local myTeamID

local spGetUnitPosition       = Spring.GetUnitPosition
local spGetUnitDefID          = Spring.GetUnitDefID
local spEcho                  = Spring.Echo
local spGetPlayerInfo         = Spring.GetPlayerInfo
local spGetCommandQueue       = Spring.GetCommandQueue
local spGetUnitSeparation     = Spring.GetUnitSeparation
local spGiveOrderToUnit       = Spring.GiveOrderToUnit
local spGetUnitDefDimensions  = Spring.GetUnitDefDimensions
local spGetTeamUnits          = Spring.GetTeamUnits
local spGetSelectedUnits      = Spring.GetSelectedUnits
local spGetUnitIsTransporting = Spring.GetUnitIsTransporting
local spGetGroundHeight       = Spring.GetGroundHeight
local spSetActiveCommand      = Spring.SetActiveCommand

local EMPTY_TABLE = {}

local autoCallTransportCmdDesc = {
	id      = CMD_AUTO_CALL_TRANSPORT,
	type    = CMDTYPE.ICON_MODE,
	tooltip = 'Allows the unit to automatically call for transportation',
	name    = 'Auto Call Transport',
	cursor  = 'Repair',
	action  = 'autocalltransport',
	params  = {0, 'off', 'on'},
	pos = {CMD.ONOFF, CMD.REPEAT, CMD.MOVE_STATE, CMD.FIRE_STATE, CMD_RETREAT},
}

local unitAICmdDesc = {
	id      = CMD_UNIT_AI,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Unit AI',
	action  = 'unitai',
	tooltip	= 'Toggles smart unit AI for the unit',
	params 	= {0, 'AI Off','AI On'}
}

options_path = 'Settings/Unit Behaviour/Transport AI'
options = {
	transportFromFactory = {
		name = "Transport From Factory",
		type = "bool",
		value = false,
		desc = "When enabled newly completed units will be transported to the waypoint of their parent factory.",
		noHotkey = true,
	},
	lingerOnConstructorTransport = {
		name = "Linger on Constructor Transport",
		type = "bool",
		value = true,
		desc = "Enable to make transports sit next to constructors after transporting them.",
		noHotkey = true,
	},
	ignoreBuilders = {
		name = "Ignore Constructors From Factory",
		type = "bool",
		value = false,
		desc = "Enable to not transport newly completed constructors.",
		noHotkey = true,
	},
	minimumTransportBenefit = {
		name = 'Factory transport benefit threshold (s)',
		type = 'number',
		value = 2,
		min = -10, max = 10, step = 0.1,
		noHotkey = true,
	},
}

-- Keep synced with unit_transport_ai_auto_call
local autoCallTransportDef = {}
local transportDef = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if (Spring.Utilities.getMovetype(ud) == 2 and ud.isBuilder and not ud.cantBeTransported) or (ud.isFactory and not ud.customParams.nongroundfac) then
		autoCallTransportDef[i] = true
	end
	if (ud.transportCapacity >= 1) and ud.canFly then
		transportDef[i] = true
	end
end

local function TableInsert(tab, toInsert)
	tab[#tab+1] = toInsert
end

local function ExtractModifiedOptions(options) --FIXME: pls check again if I'm really needed. This is a respond to https://code.google.com/p/zero-k/issues/detail?id=1824 (options in online game coded different than in local game)
	local alt,ctrl,shift,internal,right
	for i,value in pairs(options) do
		if value == "alt" then
			alt = true
		elseif value== "ctrl" then
			ctrl = true
		elseif value == "shift" then
			shift =true
		elseif value == "internal" then
			internal = true
		elseif value == "right" then
			right = true
		end
	end
	return alt,ctrl,shift,internal,right
end

local goodCommand = {
	[CMD.MOVE] = true,
	[CMD_RAW_MOVE] = true,
	[CMD_RAW_BUILD] = true,
	[CMD.WAIT] = true,
	[CMD.SET_WANTED_MAX_SPEED or 70] = true,
	[CMD.GUARD] = true,
	[CMD.RECLAIM] = true,
	[CMD.REPAIR] = true,
	[CMD.RESURRECT] = true,
	[CMD_JUMP] = true,
}

local ignoredCommand = {
	[CMD.ONOFF] = true,
	[CMD.FIRE_STATE] = true,
	[CMD.MOVE_STATE] = true,
	[CMD.REPEAT] = true,
	[CMD.CLOAK] = true,
	[CMD.STOCKPILE] = true,
	[CMD.TRAJECTORY] = true,
	[CMD.IDLEMODE] = true,
	[CMD_GLOBAL_BUILD] = true,
	[CMD_STEALTH] = true,
	[CMD_CLOAK_SHIELD] = true,
	[CMD_UNIT_FLOAT_STATE] = true,
	[CMD_PRIORITY] = true,
	[CMD_MISC_PRIORITY] = true,
	[CMD_RETREAT] = true,
	[CMD_UNIT_BOMBER_DIVE_STATE] = true,
	[CMD_AP_FLY_STATE] = true,
	[CMD_AP_AUTOREPAIRLEVEL] = true,
	[CMD_UNIT_SET_TARGET] = true,
	[CMD_UNIT_CANCEL_TARGET] = true,
	[CMD_UNIT_SET_TARGET_CIRCLE] = true,
	[CMD_ABANDON_PW] = true,
	[CMD_RECALL_DRONES] = true,
	[CMD_UNIT_KILL_SUBORDINATES] = true,
	[CMD_PUSH_PULL] = true,
	[CMD_UNIT_AI] = true,
	[CMD_WANT_CLOAK] = true,
	[CMD_DONT_FIRE_AT_RADAR] = true,
	[CMD_AIR_STRAFE] = true,
	[CMD_PREVENT_OVERKILL] = true,
	[CMD_SELECTION_RANK] = true,
}

local function ProcessCommand(unitID, cmdID, params, noUsefuless, noPosition)
	if noUsefuless then
		return false
	end
	if not (goodCommand[cmdID] or cmdID < 0) then
		return false
	end
	local halting = not (cmdID == CMD.MOVE or cmdID == CMD_RAW_MOVE or cmdID == CMD_RAW_BUILD or cmdID == CMD.WAIT or cmdID == CMD.SET_WANTED_MAX_SPEED)
	if noPosition or cmdID == CMD.WAIT or cmdID == CMD.SET_WANTED_MAX_SPEED then
		return true, halting
	end

	local targetOverride
	if #params == 5 and (cmdID == CMD.RESURRECT or cmdID == CMD.RECLAIM or cmdID == CMD.REPAIR) then
		areaTarget[unitID] = {
			x = params[2],
			z = params[4],
			objectID = params[1]
		}
	elseif areaTarget[unitID] and #params == 4 then
		if params[1] == areaTarget[unitID].x and params[3] == areaTarget[unitID].z then
			targetOverride = areaTarget[unitID].objectID
		end
		areaTarget[unitID] = nil
	elseif areaTarget[unitID] then
		areaTarget[unitID] = nil
	end

	if not targetOverride then
		if #params == 3 or #params == 4 then
			return true, halting, params[1], params[2], params[3]
		elseif not params[1] then
			return true, halting
		end
	end

	if cmdID == CMD.RESURRECT or cmdID == CMD.RECLAIM then
		local x, y, z = Spring.GetFeaturePosition((targetOverride or params[1] or 0) - MAX_UNITS)
		return true, halting, x, y, z
	else
		local x, y, z = Spring.GetUnitPosition(targetOverride or params[1])
		return true, halting, x, y, z
	end
end

function IsTransportable(unitDefID, unitID)
	ud = UnitDefs[unitDefID]
	if (ud == nil) then
		return false
	end
	udc = ud.springCategories
	local _,_,_,_,y = spGetUnitPosition(unitID,true)
	y = y + Spring.GetUnitRadius(unitID)
	return (udc~= nil and ud.isGroundUnit and (y>-20 or floatDefs[unitDefID]))
end

function IsDisembark(cmd)
	local alt,ctrl = ExtractModifiedOptions(cmd.options)
	if (cmd.id == CMD.WAIT and (cmd.options.alt or alt) and (cmd.options.ctrl or ctrl)) then
		return true
	end
	return false
end

function IsWaitCommand(unitID)
	local queue = spGetCommandQueue(unitID, 1);
	local alt
	if queue and queue[1] then
		alt = ExtractModifiedOptions(queue[1].options)
	end
	if (queue and queue[1] and queue[1].id == CMD.WAIT and not (queue[1].options.alt or alt)) then
		return true
	end
	return false
end

function IsIdle(unitID)
	local queue = spGetCommandQueue(unitID, 1)
	if (queue == nil or #queue==0) then
		return true
	else
		return false
	end
end

function GetToPickTransport(unitID)
	local x = toPickRev[unitID]
	if x~= nil then
		return x
	else
		return 0
	end
end

function GetToPickUnit(transportID)
	local x = toPick[transportID]
	if (x~=nil) then
		if x[1] ~= nil then
			return x[1]
		else
			return 0
		end
	end
	return 0
end

function DeleteToPickTran(transportID)
	local tr = toPick[transportID]
	if (tr ~= nil) then
		local uid = tr[1]
		if (uid ~= nil) then
			toPickRev[uid]=nil
		end
	end
	toPick[transportID] = nil
end

function DeleteToPickUnit(unitID)
	local tr = toPickRev[unitID]
	if (tr~=nil) then
		toPick[tr] = nil
	end
	toPickRev[unitID] = nil
end

function AddToPick(transportID, unitID, stopped, fact)
	toPick[transportID] = {unitID, stopped, fact}
	toPickRev[unitID] = transportID
end

local function GetAutoCallTransportState(unitID)
	return autoCallTransportUnits[unitID]
end

local function SetAutoCallTransportState(unitID, unitDefID, newState)
	if autoCallTransportDef[unitDefID] then
		autoCallTransportUnits[unitID] = newState
	end
end

function widget:UnitCreated(unitID, unitDefID, teamID)
	if teamID == myTeamID and transportDef[unitDefID] then
		allMyTransports[unitID] = unitDefID
	end
end

function widget:Shutdown()
	WG.GetAutoCallTransportState = nil
	widgetHandler:DeregisterGlobal(widget, 'taiEmbark')
end

function widget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	widget:UnitCreated(unitID, unitDefID, teamID)
end

function RemoveUnit(unitID, unitDefID)
	--spEcho("unit destroyed " ..unitID)
	idleTransports[unitID] = nil
	priorityUnits[unitID] = nil
	waitingUnits[unitID] = nil
	local tuid = GetToPickUnit(unitID)
	if (tuid ~= 0) then -- transport which was about to pick something was destroyed
		local state = toPick[unitID][2]
		local fact = toPick[unitID][3]
		if (state == ST_PRIORITY) then
			waitingUnits[tuid] = {ST_PRIORITY, spGetUnitDefID(tuid)}
		else
			waitingUnits[tuid] = {ST_ROUTE, spGetUnitDefID(tuid), fact}
			if (state == ST_STOPPED) then
				spGiveOrderToUnit(tuid, CMD.WAIT, EMPTY_TABLE, 0)
			end
		end
		DeleteToPickTran(unitID)
		AssignTransports(0, tuid)
	else -- unit which was about to be picked was destroyed
		local pom = GetToPickTransport(unitID)
		if (pom~=0) then
			DeleteToPickUnit(unitID)
			spGiveOrderToUnit(pom, CMD.STOP, EMPTY_TABLE, 0)

			if toGuard[pom] then
				spGiveOrderToUnit(pom, CMD.GUARD, {toGuard[pom]}, 0)
			end
		end	-- delete form toPick list
	end
end

function AddTransportToIdle(unitID, unitDefID)
	if activeTransports[unitID] then
		idleTransports[unitID] = unitDefID
		--spEcho ("transport added " .. unitID)
		return true
	end
	return false
end

local function RemoveTransport(unitID, unitDefID)
	activeTransports[unitID] = nil
	toGuard[unitID] = nil
	autoCallTransportUnits[unitID] = false
	RemoveUnit(unitID, unitDefID)
end

local function AddTransport(unitID, unitDefID)
	if transportDef[unitDefID] then
		activeTransports[unitID] = unitDefID
		local queueCount = Spring.GetCommandQueue(unitID, 0)
		if queueCount == 0 then
			AddTransportToIdle(unitID, unitDefID)
		end
	end
end

local function PossiblyTransferAutoCallThroughMorph(unitID)
	if not autoCallTransportUnits[unitID] then
		return
	end

	local morphedTo = Spring.GetUnitRulesParam(unitID, "wasMorphedTo")
	if not morphedTo then
		return
	end

	local morphedToDefID = Spring.GetUnitDefID(morphedTo)
	if morphedToDefID then
		SetAutoCallTransportState(morphedTo, morphedToDefID, autoCallTransportUnits[unitID])
	end
end

local function GiveUnloadOrder(transportID, x, y, z)
	spGiveOrderToUnit(transportID, CMD.UNLOAD_UNIT, {x - 2, y, z - 2}, CMD.OPT_SHIFT)
	spGiveOrderToUnit(transportID, CMD.UNLOAD_UNIT, {x + 2, y, z + 2, CONST_UNLOAD_RADIUS}, CMD.OPT_SHIFT)
	spGiveOrderToUnit(transportID, CMD.UNLOAD_UNIT, {x - 2, y, z + 2, CONST_UNLOAD_RADIUS*2}, CMD.OPT_SHIFT)
	spGiveOrderToUnit(transportID, CMD.UNLOAD_UNIT, {x + 2, y, z - 2, CONST_UNLOAD_RADIUS*4}, CMD.OPT_SHIFT)
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	if teamID == myTeamID then
		PossiblyTransferAutoCallThroughMorph(unitID)
		RemoveTransport(unitID, unitDefID)
	end
	if allMyTransports[unitID] then
		allMyTransports[unitID] = nil
	end
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	widget:UnitDestroyed(unitID, unitDefID, teamID)
end


function widget:UnitIdle(unitID, unitDefID, teamID)
	if (teamID ~= myTeamID) or (WG.FerryUnits and WG.FerryUnits[unitID]) then
		return
	end
	if (hackIdle[unitID] ~= nil) then
		hackIdle[unitID] = nil
		return
	end
	if (AddTransportToIdle(unitID, unitDefID)) then
		AssignTransports(unitID, 0)
	else
		if (IsTransportable(unitDefID, unitID)) then
			priorityUnits[unitID] = nil

			local marked = GetToPickTransport(unitID)
			if (waitingUnits[unitID] ~= nil) then	-- unit was waiting for transport and now its suddenly idle (stopped) - delete it
--				spEcho("waiting unit idle "..unitID)
				waitingUnits[unitID] = nil
			end

			if (marked ~= 0) then
--				spEcho("to pick unit idle "..unitID)
				DeleteToPickTran(marked)
				spGiveOrderToUnit(marked, CMD.STOP, EMPTY_TABLE, 0)	-- and stop it (when it becomes idle it will be assigned)
			end
		end
	end
end

function widget:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
	if unitTeam == myTeamID then
		local ud = UnitDefs[unitDefID]
		if (options.ignoreBuilders.value and ud.isBuilder and ud.canAssist) then
			return
		end
		if (IsTransportable(unitDefID, unitID) and not userOrders) then
			--spEcho ("new unit from factory "..unitID)
			waitingUnits[unitID] = {ST_ROUTE, unitDefID, factID}
			local foundTransport = AssignTransports(0, unitID, factID, not options.transportFromFactory.value)

			-- Transport was not found so remove the unit. Factory guard transport only works
			-- on units newly exiting the factory (too chaotic otherwise).
			if (not options.transportFromFactory.value) and (not foundTransport) then
				waitingUnits[unitID] = nil
			end
		end
	end
end

function widget:CommandNotify(id, params, options)
	if id == CMD_AUTO_CALL_TRANSPORT then
		local selectedUnits = Spring.GetSelectedUnits()
		local newState = (params[1] == 1)
		for i = 1, #selectedUnits do
			local unitID = selectedUnits[i]
			local unitDefID = Spring.GetUnitDefID(unitID)
			SetAutoCallTransportState(unitID, unitDefID, newState)
		end
		return true
	end

	if id == CMD_UNIT_AI then
		local selectedUnits = Spring.GetSelectedUnits()
		local newState = (params[1] == 1)
		for i = 1, #selectedUnits do
			local unitID = selectedUnits[i]
			local unitDefID = Spring.GetUnitDefID(unitID)
			if transportDef[unitDefID] then
				if newState then
					AddTransport(unitID, unitDefID)
				else
					RemoveTransport(unitID, unitDefID)
				end
			end
		end
		return false
	end

	if ignoredCommand[id] then
		return false
	end

	local sel = nil
	local alt,ctrl,shift = ExtractModifiedOptions(options)
	if not (options.shift or shift) then
		sel = spGetSelectedUnits()
		for i = 1, #sel do
			local uid = sel[i]
			RemoveUnit(uid, spGetUnitDefID(uid))
		end
	end

	if (id == CMD.WAIT and (options.alt or alt)) then
		if (sel == nil) then sel = spGetSelectedUnits() end
		for i=1,#sel do
			local uid = sel[i]
			priorityUnits[uid] = spGetUnitDefID(uid)
		end
	end

	return false
end

function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag)
	if autoCallTransportUnits[unitID] then
		local useful, halting = ProcessCommand(unitID, cmdID, params, false, true)
		local queue = Spring.GetCommandQueue(unitID, 0)
		if useful and halting and queue >= 1 then
			spGiveOrderToUnit(unitID, CMD_EMBARK, EMPTY_TABLE, CMD.OPT_ALT)
		else
			RemoveUnit(unitDefID, spGetUnitDefID(unitDefID))
		end
	end
end

function widget:CommandsChanged()
	local selectedSorted = Spring.GetSelectedUnitsSorted()
	local searchCall, searchTransport = true, true
	for unitDefID, units in pairs(selectedSorted) do
		if searchCall and autoCallTransportDef[unitDefID] then
			local customCommands = widgetHandler.customCommands
			local order = 0
			if autoCallTransportUnits[units[1]] then
				order = 1
			end
			autoCallTransportCmdDesc.params[1] = order
			table.insert(customCommands, autoCallTransportCmdDesc)
			searchCall = false
		end

		if searchTransport and transportDef[unitDefID] then
			local customCommands = widgetHandler.customCommands
			local order = 0
			if activeTransports[units[1]] then
				order = 1
			end
			unitAICmdDesc.params[1] = order
			table.insert(customCommands, unitAICmdDesc)
			searchTransport = false
		end
	end
end

function widget:Update(deltaTime)
	timer = timer + deltaTime
	if (timer < 1) then
		return
	end
	StopCloseUnits()

	local todel = {}
	for unitID, unitDefID in pairs(priorityUnits) do
		waitingUnits[unitID] = {ST_PRIORITY, unitDefID}
		AssignTransports(0, unitID)
		TableInsert(todel, unitID)
	end
	for i = 1, #todel do
		priorityUnits[todel[i]] = nil
	end

	timer = 0
end

function StopCloseUnits() -- stops dune units which are close to transport
	for transportID, val in pairs(toPick) do
		local unitID = val[1]
		local state = val[2]
		if (state == ST_ROUTE or state == ST_PRIORITY) then
			local dist = spGetUnitSeparation(transportID, unitID, true)
			if (dist ~= nil and dist < CONST_TRANSPORT_STOPDISTANCE) then
				local canStop = true
				if (val[3] ~= nil) then
					local fd = spGetUnitDefID(val[3])
					local ud = spGetUnitDefID(unitID)
					if (fd ~= nil and ud ~= nil) then
						local fd = spGetUnitDefDimensions(fd)
						local ud = spGetUnitDefDimensions(ud)
						if (fd ~= nil and ud ~= nil) then
							if (spGetUnitSeparation(unitID, val[3], true) < fd.radius + ud.radius) then
--								spEcho ("Cant stop - too close to factory")
								canStop = false
							end
						end
					end
				end
				if canStop then
					if not IsWaitCommand(unitID) then
						spGiveOrderToUnit(unitID, CMD.WAIT, EMPTY_TABLE, 0)
					end
					toPick[transportID][2] = ST_STOPPED
				end
			end
		end
	end
end

function widget:Initialize()
	local _, _, spec, teamID = spGetPlayerInfo(Spring.GetMyPlayerID())
	 if spec then
		widgetHandler:RemoveWidget(widget)
		return false
	end
	WG.GetAutoCallTransportState = GetAutoCallTransportState
	WG.SetAutoCallTransportState = SetAutoCallTransportState
	WG.AddTransport = AddTransport

	myTeamID = teamID
	widgetHandler:RegisterGlobal(widget, 'taiEmbark', taiEmbark)

	local units = spGetTeamUnits(teamID)
	for i = 1, #units do	-- init existing transports
		local unitID = units[i]
		widget:UnitCreated(unitID, spGetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
		if AddTransportToIdle(unitID, spGetUnitDefID(unitID)) then
			AssignTransports(unitID, 0)
		end
	end
end

local function ReturnToPickupLocation(unitDefID)
	if not options.lingerOnConstructorTransport.value then
		return false
	end
	local ud = unitDefID and UnitDefs[unitDefID]
	return not (ud and ud.isBuilder)
end

function widget:UnitLoaded(unitID, unitDefID, teamID, transportID)
	if (teamID ~= myTeamID or toPick[transportID]==nil) then
		return
	end

	local queue = spGetCommandQueue(unitID, -1);
	if (queue == nil) then
		return
	end

	--spEcho("unit loaded " .. transportID .. " " ..unitID)
	local torev = {}
	local lastX, lastY, lastZ

	local ender = false

	storedQueue[unitID] = {}
	DeleteToPickTran(transportID)
	hackIdle[transportID] = true
	local cnt = 0
	for k = 1, #queue do
		local v = queue[k]
		local alt,ctrl,shift,internal,right = ExtractModifiedOptions(v.options)
		if not (v.options.internal or internal) then	--not other widget's command
			local usefulCommand, haltingCommand, cx, cy, cz = ProcessCommand(unitID, v.id, v.params, ender)
			if usefulCommand then
				cnt = cnt +1
				if cx then
					if queue[k + 1] then
						-- Do not give move order to the last waypoint.
						spGiveOrderToUnit(transportID, CMD_RAW_MOVE, {cx, cy, cz}, CMD.OPT_SHIFT)
						TableInsert(torev, {cx, cy, cz + 20})
					end
					lastX, lastY, lastZ = cx, cy, cz
				end
				if haltingCommand or (IsDisembark(v)) then
					ender = true
					if haltingCommand then
						local opts = CMD.OPT_SHIFT
						if (v.options.alt or alt)	 then opts = opts + CMD.OPT_ALT	 end
						if (v.options.ctrl or ctrl)	then opts = opts + CMD.OPT_CTRL	end
						if (v.options.right or right) then opts = opts + CMD.OPT_RIGHT end
						TableInsert(storedQueue[unitID], {v.id, v.params, opts})
					end
				end
			else
				if (not ender) then
					ender = true
				end
				if (v.ID ~= CMD.WAIT) then
					local opts = CMD.OPT_SHIFT
					if (v.options.alt or alt)	 then opts = opts + CMD.OPT_ALT	 end
					if (v.options.ctrl or ctrl)	then opts = opts + CMD.OPT_CTRL	end
					if (v.options.right or right) then opts = opts + CMD.OPT_RIGHT end
					TableInsert(storedQueue[unitID], {v.id, v.params, opts})
				end
			end
		end
	end

	spGiveOrderToUnit(unitID, CMD.STOP, EMPTY_TABLE, 0)

	if lastX then
		GiveUnloadOrder(transportID, lastX, lastY, lastZ)

		if toGuard[transportID] or ReturnToPickupLocation(unitDefID) then
			local i = #torev
			while (i > 0) do
				spGiveOrderToUnit(transportID, CMD_RAW_MOVE, torev[i], CMD.OPT_SHIFT) -- move in zig zaq (if queued)
				i = i -1
			end

			local x,y,z = spGetUnitPosition(transportID)
			spGiveOrderToUnit(transportID, CMD_RAW_MOVE, {x,y,z}, CMD.OPT_SHIFT)

			--unload 2nd time at loading point incase transport refuse to drop unit at the intended destination (ie: in water)
			GiveUnloadOrder(transportID, x, y, z)

			if toGuard[transportID] then
				spGiveOrderToUnit(transportID, CMD.GUARD, {toGuard[transportID]}, CMD.OPT_SHIFT)
			end
		end
	else
		local x,y,z = Spring.GetUnitPosition(transportID)
		GiveUnloadOrder(transportID, x, y, z)
	end
end

function widget:UnitUnloaded(unitID, unitDefID, teamID, transportID)
	if (teamID ~= myTeamID or storedQueue[unitID] == nil) then
		return
	end
	spGiveOrderToUnit(unitID, CMD.STOP, EMPTY_TABLE, 0)
	for i=1, #storedQueue[unitID] do
		local x = storedQueue[unitID][i]
		spGiveOrderToUnit(unitID, x[1], x[2], x[3])
	end
	storedQueue[unitID] = nil
	local queue = spGetCommandQueue(unitID, 1)
	if (queue and queue[1] and queue[1].id == CMD.WAIT) then
		-- workaround: clears wait order if STOP fails to do so
		spGiveOrderToUnit(unitID, CMD.WAIT, EMPTY_TABLE, 0)
	end 
end

function CanTransport(transportID, unitID)
	local udef = spGetUnitDefID(unitID)
	local tdef = spGetUnitDefID(transportID)

	if (not udef or not tdef) then
		return false
	end

	if (UnitDefs[udef].xsize > UnitDefs[tdef].transportSize * 2) then	-- unit size check
--		spEcho ("size failed")
		return false
	end

	local trans = spGetUnitIsTransporting(transportID) -- capacity check
	if (UnitDefs[tdef].transportCapacity <= #trans) then
--		spEcho ("count failed")
		return false
	end


	local mass = UnitDefs[udef].mass -- mass check
	for i=1, #trans do
		mass = mass + UnitDefs[spGetUnitDefID(trans[i])].mass
	end
	if (mass > UnitDefs[tdef].transportMass) then
--		spEcho ("mass failed")
		return false
	end
	return true
end

local function GetTransportBenefit(unitID, pathLength, transporter, transDef, unitspeed, unitmass, priorityState)
	local transpeed = UnitDefs[transDef].speed
	local transMass = UnitDefs[transDef].mass
	local speedMod  = math.min(1, 3 * unitmass/(transMass +unitmass )) --see unit_transport_speed.lua gadget

	local transportDist = spGetUnitSeparation(unitID, transporter, true)

	local ttime = (transportDist + pathLength) / (transpeed*speedMod) + CONST_TRANSPORT_PICKUPTIME
	local utime = pathLength / unitspeed
	local benefit = utime - ttime

	--spEcho ("	 "..transporter.. " " .. unitID .. "	" .. benefit)

	if (benefit > options.minimumTransportBenefit.value) then
		if priorityState then
			benefit = benefit + CONST_PRIORITY_BENEFIT
		end
		return {benefit, transporter, unitID}
	end
end

function AssignTransports(transportID, unitID, guardID, guardOnly)
	local best = {}
	--spEcho ("assigning " .. transportID .. " " ..unitID)
	if (transportID~=0) then
		 local unitDefID = spGetUnitDefID(transportID)
		 local transpeed = UnitDefs[unitDefID].speed
		 local transMass = UnitDefs[unitDefID].mass
		 local speedMod = 1
		 for id, val in pairs(waitingUnits) do
		 local waitDefID = val[2]
			 if CanTransport(transportID, id) and IsTransportable(waitDefID, id)	then
				local unitspeed = UnitDefs[waitDefID].speed
				local unitmass = UnitDefs[waitDefID].mass
				speedMod =	math.min(1, 3 * unitmass/(transMass +unitmass )) --see unit_transport_speed.lua gadget

				local pathLength = GetPathLength(id)
				local transportDist = spGetUnitSeparation(id, transportID, true)

				local ttime = (transportDist + pathLength) / (transpeed*speedMod) + CONST_TRANSPORT_PICKUPTIME
				local utime = pathLength / unitspeed
				local benefit = utime-ttime
				--spEcho ("	 "..transportID .. " " .. id .. "	" .. benefit)

				if (benefit > options.minimumTransportBenefit.value) then
					if (val[1]==ST_PRIORITY) then
						 benefit = benefit + CONST_PRIORITY_BENEFIT
					end
					TableInsert(best, {benefit, transportID, id})
				end
			 end
		 end
	elseif (unitID ~=0) then
		local unitDefID = spGetUnitDefID(unitID)
		local unitspeed = UnitDefs[unitDefID].speed
		local unitmass = UnitDefs[unitDefID].mass
		local priorityState = (waitingUnits[unitID][1] == ST_PRIORITY)
		local pathLength = GetPathLength(unitID)

		if not guardOnly then
			for id, def in pairs(idleTransports) do
				if CanTransport(id, unitID) and IsTransportable(unitDefID, unitID) then
					local benefit = GetTransportBenefit(unitID, pathLength, id, def, unitspeed, unitmass, priorityState)
					if benefit then
						toGuard[id] = nil
						TableInsert(best, benefit)
					end
				end
			end
		end

		if guardID then
			for id, def in pairs(allMyTransports) do
				if CanTransport(id, unitID) and IsTransportable(unitDefID, unitID) then
					local queue = spGetCommandQueue(id, 1)
					if queue and queue[1] and queue[1].id == CMD.GUARD and queue[1].params[1] == guardID then
						local benefit = GetTransportBenefit(unitID, pathLength, id, def, unitspeed, unitmass, priorityState)
						if benefit then
							toGuard[id] = guardID
							TableInsert(best, benefit)
						end
					end
				end
			end
		end
	end

	table.sort(best, function(a,b) return a[1]>b[1] end)
	local i = 1
	local it = #best
	local used = {}
	while i <= it do
		local tid = best[i][2]
		local uid = best[i][3]
		i = i +1
		if (used[tid]==nil and used[uid]==nil) then --check if already given transport order in same loop
			used[tid] = 1
			used[uid] = 1
			--spEcho ("ordering " .. tid .. " " .. uid )

			if (waitingUnits[uid][1] == ST_PRIORITY) then
				AddToPick(tid, uid, ST_PRIORITY)
			else
				AddToPick(tid, uid, ST_ROUTE, waitingUnits[uid][3])
			end
			waitingUnits[uid] = nil
			idleTransports[tid] = nil
			spGiveOrderToUnit(tid, CMD.LOAD_UNITS, {uid}, 0)

			return true -- Transport was matched with the unit
		end
	end

	return false -- Unit/Transport is still idle
end

function Dist(x,y,z, x2, y2, z2)
	local xd = x2-x
	local yd = y2-y
	local zd = z2-z
	return math.sqrt(xd*xd + yd*yd + zd*zd)
end

function GetPathLength(unitID)
	local mini = math.huge
	local maxi = -math.huge
	local px,py,pz= spGetUnitPosition(unitID)

	local h = spGetGroundHeight(px,pz)
	if (h < mini) then mini = h end
	if (h > maxi) then maxi = h end

	local d = 0
	local queue = spGetCommandQueue(unitID, -1);
	local udid = spGetUnitDefID(unitID)
	local moveID = UnitDefs[udid].moveDef.id
	if (queue == nil) then return 0 end
	for k = 1, #queue do
		local v = queue[k]
		local usefulCommand, haltingCommand, cx, cy, cz = ProcessCommand(unitID, v.id, v.params)
		if usefulCommand then
			if cx then
				local reachable = true --always assume target reachable
				local waypoints
				if moveID then --unit has compatible moveID?
					local result, lastwaypoint
					result, lastwaypoint, waypoints = IsTargetReachable(moveID, px, py, pz, cx, cy, cz, 128)
					if result == "outofreach" then --abit out of reach?
						reachable=false --target is unreachable!
					end
				end
				if reachable then
					if waypoints then --we have waypoint to destination?
						local way1,way2,way3 = px,py,pz
						for i=1, #waypoints do --sum all distance in waypoints
							d = d + Dist(way1,way2,way3, waypoints[i][1],waypoints[i][2],waypoints[i][3])
							way1,way2,way3 = waypoints[i][1],waypoints[i][2],waypoints[i][3]
						end
					else --so we don't have waypoint?
						d = d + Dist(px,py, pz, cx, cy, cz) --we don't have waypoint then measure straight line
					end
				else --pathing says target unreachable?!
					d = d + Dist(px,py, pz, cx, cy, cz) + 9999 --target unreachable!
				end
				px, py, pz = cx, cy, cz
				local h = spGetGroundHeight(px,pz)
				if (h < mini) then mini = h end
				if (h > maxi) then maxi = h end
				if haltingCommand then
					break
				end
			end
		else
			break
		end
	end

	d = d + (maxi - mini) * CONST_HEIGHT_MULTIPLIER
	return d
end

--This function process result of Spring.PathRequest() to say whether target is reachable or not
function IsTargetReachable (moveID, ox,oy,oz,tx,ty,tz,radius)
	local result,lastcoordinate, waypoints
	local path = Spring.RequestPath( moveID,ox,oy,oz,tx,ty,tz, radius)
	if path then
		local waypoint = path:GetPathWayPoints() --get crude waypoint (low chance to hit a 10x10 box). NOTE; if waypoint don't hit the 'dot' is make reachable build queue look like really far away to the GetWorkFor() function.
		local finalCoord = waypoint[#waypoint]
		if finalCoord then --unknown why sometimes NIL
			local dx, dz = finalCoord[1]-tx, finalCoord[3]-tz
			local dist = math.sqrt(dx*dx + dz*dz)
			if dist <= radius+20 then --is within radius?
				result = "reach"
				lastcoordinate = finalCoord
				waypoints = waypoint
			else
				result = "outofreach"
				lastcoordinate = finalCoord
				waypoints = waypoint
			end
		end
	else
		result = "noreturn"
		lastcoordinate = nil
		waypoints = nil
	end
	return result, lastcoordinate, waypoints
end

--[[
function widget:KeyPress(key, modifier, isRepeat)
	if (key == KEYSYMS.Q and not modifier.ctrl) then
		if (not modifier.alt) then
			local opts = CMD.OPT_ALT
			if (modifier.shift) then opts = opts + CMD.OPT_SHIFT end

			for _, id in ipairs(spGetSelectedUnits()) do -- embark
				local def = spGetUnitDefID(id)
				if (IsTransportable(def) or UnitDefs[def].isFactory) then
					spGiveOrderToUnit(id, CMD.WAIT, EMPTY_TABLE, opts)
					if (not UnitDefs[def].isFactory) then priorityUnits[id] = def end
				end
			end
		else
			local opts = CMD.OPT_ALT + CMD.OPT_CTRL
			if (modifier.shift) then opts = opts + CMD.OPT_SHIFT end
			for _, id in ipairs(spGetSelectedUnits()) do --disembark
				local def = spGetUnitDefID(id)
				if (IsTransportable(def)	or UnitDefs[def].isFactory) then spGiveOrderToUnit(id, CMD.WAIT, EMPTY_TABLE, opts) end
			end

		end
	end
end ]]--

function taiEmbark(unitID, teamID, embark, shift, internal) -- called by gadget
	if (teamID ~= myTeamID) then
		return
	end

	if (not shift) then
		RemoveUnit(unitID, spGetUnitDefID(unitID)) --remove existing command ASAP
	end

	if not internal then
		local queue = spGetCommandQueue(unitID, -1)
		if (not queue or #queue == 0) and (not shift) then --unit has no command at all and not queueing embark/disembark command
			return false
		else
			local hasMoveCommand
			for k = 1, #queue do
				local v = queue[k]
				local usefulCommand, haltingCommand, cx, cy, cz = ProcessCommand(unitID, v.id, v.params, false, true)
				if usefulCommand then
					hasMoveCommand = true
					break
				end
			end
			if (not hasMoveCommand) and (not shift) then --unit has no move command and not queueing embark/disembark command
				return false
			end
		end
	end

	if (embark) then
		local def = spGetUnitDefID(unitID)
		local ud = UnitDefs[def]
		if (ud ~= nil and not ud.isFactory) and not waitingUnits[unitID] then
			priorityUnits[unitID] = def --add to priority list (will be read in Widget:Update())
		end
	end
end
