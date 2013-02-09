------------------------------------------------------------------------------
-- HOW IT WORKS:
-- 	After firing, set ammo to 0 and look for a pad
--	Find first combat order and queue rearm order before it
--	If bomber idle and out of ammo (UnitIdle), give it rearm order
-- 	When bomber is in range of airpad (GameFrame), set fuel to zero	
--
--	See also: scripts/bombers.lua
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- TODO:
-- Handle planes waiting around if no airpads exist at all - send to pad once one is built
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Aircraft Command",
    desc      = "Handles aircraft repair/rearm",
    author    = "KingRaptor",
    date      = "22 Jan 2011",
    license   = "GNU LGPL, v2.1 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
-- speedups
--------------------------------------------------------------------------------
local spGetUnitTeam		= Spring.GetUnitTeam
local spGetUnitAllyTeam	= Spring.GetUnitAllyTeam
local spGetUnitDefID	= Spring.GetUnitDefID
local spGetUnitIsDead	= Spring.GetUnitIsDead
local spGetUnitRulesParam	= Spring.GetUnitRulesParam
local spGetUnitFuel		= Spring.GetUnitFuel


include "LuaRules/Configs/customcmds.h.lua"

local bomberNames = {
	armstiletto_laser = {},
	corshad = {},
	corhurc2 = {},
	armcybr = {},
}

local airpadNames = {
	factoryplane = {mobile = false, cap = 1},
	armasp = {mobile = false, cap = 4},
	armcarry = {mobile = true, cap = 9},
}

local bomberDefs = {}
local airpadDefs = {}

for name, data in pairs(bomberNames) do
	if UnitDefNames[name] then bomberDefs[UnitDefNames[name].id] = data end
end
for name,data in pairs(airpadNames) do
	if UnitDefNames[name] then airpadDefs[UnitDefNames[name].id] = data end
end

for i=1,#UnitDefs do
  if UnitDefs[i].canFly then
    bomberDefs[i] = {}
  end
end

if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------
local spGiveOrderToUnit = Spring.GiveOrderToUnit

--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------
local combatCommands = {	-- commands that require ammo to execute
	[CMD.ATTACK] = true,
	[CMD.AREA_ATTACK] = true,
	[CMD.FIGHT] = true,
	[CMD.PATROL] = true,
	[CMD.GUARD] = true,
	[CMD.MANUALFIRE] = true,
}

local padRadius = 400 -- land if pad is within this range
local MAX_FUEL = 1000000 * 0.9	-- not exact to allow some fudge

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local rearmCMD = {
    id      = CMD_REARM,
    name    = "Rearm",
    action  = "rearm",
	cursor  = 'Repair',
    type    = CMDTYPE.ICON_UNIT,
	tooltip = "Select an airpad to return to for rearm",
	hidden	= true,
}

local findPadCMD = {
    id      = CMD_FIND_PAD,
    name    = "Rearm",
    action  = "rearm",
	cursor  = 'Repair',
    type    = CMDTYPE.ICON,
	tooltip = "Search for nearest available airpad to return to for rearm",
	hidden	= false,
}

local bomberUnitIDs = {}
local bomberToPad = {}	-- [bomberID] = detination pad ID
local refuelling = {} -- [bomberID] = true
local airpads = {}	-- stores data
local airpadsPerAllyTeam = {}	-- [allyTeam] = {[pad1ID] = true, [pad2ID] = true, ..}
local allyteams = Spring.GetAllyTeamList()
for i=1,#allyteams do
	airpadsPerAllyTeam[allyteams[i]] = {}
end
local scheduleRearmRequest = {} -- [bomberID] = true	(used to avoid recursion in UnitIdle)

_G.airpads = airpads

function gadget:Initialize()
	local unitList = Spring.GetAllUnits()
	for i=1,#(unitList) do
		local ud = spGetUnitDefID(unitList[i])
		local team = spGetUnitTeam(unitList[i])
		gadget:UnitCreated(unitList[i], ud, team)
		gadget:UnitFinished(unitList[i], ud, team)
	end
end

local function MakeOptsWithShift(cmdOpt)
	local opts = {"shift"} -- appending
	if (cmdOpt.alt)   then opts[#opts+1] = "alt"   end
	if (cmdOpt.ctrl)  then opts[#opts+1] = "ctrl"  end
	if (cmdOpt.right) then opts[#opts+1] = "right" end
	return opts
end

--[[
local function InsertCommandAfter(unitID, afterCmd, cmdID, params, opts)
	-- workaround for STOP not clearing attack order due to auto-attack
	-- we set it to hold fire temporarily, revert once commands have been reset
	local queue = Spring.GetUnitCommands(unitID)
	local firestate = Spring.GetUnitStates(unitID).firestate
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {})
	Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, {})
	if queue then
		opts = opts or {}
		local i = 1
		local toInsert = nil
		local commands = #queue
		while i <= commands do
			
			if toInsert then
				Spring.GiveOrderToUnit(unitID, cmdID, params, MakeOptsWithShift(opts))
				toInsert = false
			else
				local cmd = queue[i]
				Spring.GiveOrderToUnit(unitID, cmd.id, cmd.params, MakeOptsWithShift(cmd.options))
				if cmd.id == afterCmd and toInsert == nil then
					toInsert = true
				end
				i = i + 1
			end
			--local cq = Spring.GetUnitCommands(unitID) for i = 1, #cq do Spring.Echo(cq[i].id) end
		end
		if toInsert then
			Spring.GiveOrderToUnit(unitID, cmdID, params, MakeOptsWithShift(opts))
		end
	end
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, {})
end
--]]

local function InsertCommand(unitID, index, cmdID, params, opts)
	-- workaround for STOP not clearing attack order due to auto-attack
	-- we set it to hold fire temporarily, revert once commands have been reset
	local queue = Spring.GetUnitCommands(unitID)
	local firestate = Spring.GetUnitStates(unitID).firestate
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {})
	Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, {})
	if queue then
		opts = opts or {}
		local i = 1
		local toInsert = (index >= 0)
		local commands = #queue
		while i <= commands do
			if i-1 == index and toInsert then
				Spring.GiveOrderToUnit(unitID, cmdID, params, MakeOptsWithShift(opts))
				toInsert = false
			else
				local cmd = queue[i]
				Spring.GiveOrderToUnit(unitID, cmd.id, cmd.params, MakeOptsWithShift(cmd.options))
				i = i + 1
			end
			--local cq = Spring.GetUnitCommands(unitID) for i = 1, #cq do Spring.Echo(cq[i].id) end
		end
		if toInsert or index < 0 then
			Spring.GiveOrderToUnit(unitID, cmdID, params, MakeOptsWithShift(opts))
		end
	end
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, {})
end
GG.InsertCommand = InsertCommand

local function FindNearestAirpad(unitID, team)
	--Spring.Echo(unitID.." checking for closest pad")
	local allyTeam = spGetUnitAllyTeam(unitID)
	local freePads = {}
	local freePadCount = 0
	-- first go through all the pads to see which ones are unbooked
	for airpadID in pairs(airpadsPerAllyTeam[allyTeam]) do
		if not spGetUnitIsDead(airpadID) and airpads[airpadID].reservations.count < airpads[airpadID].cap then
			freePads[airpadID] = true
			freePadCount = freePadCount + 1
		end
	end
	-- if no free pads, just use all of them
	if freePadCount == 0 then
		--Spring.Echo("No free pads, directing to closest one")
		freePads = airpadsPerAllyTeam[allyTeam]
	end
	
	local minDist = 999999
	local closestPad
	for airpadID in pairs(freePads) do
		local dist = Spring.GetUnitSeparation(unitID, airpadID, true) or minDist
		if (dist < minDist) then
			minDist = dist
			closestPad = airpadID
		end
	end
	return closestPad
end

local function RequestRearm(unitID, team, forceNow)
	team = team or spGetUnitTeam(unitID)
	if spGetUnitRulesParam(unitID, "noammo") ~= 1 then
		local health, maxHealth = Spring.GetUnitHealth(unitID)
		if health > maxHealth - 1 then
			return
		end
	end
	--Spring.Echo(unitID.." requesting rearm")
	local queue = Spring.GetUnitCommands(unitID) or {}
	local index = #queue + 1
	for i=1, #queue do
		if combatCommands[queue[i].id] then
			index = i-1
			break
		elseif queue[i].id == CMD_REARM or queue[i].id == CMD_FIND_PAD then	-- already have manually set rearm point, we have nothing left to do here
			return
		end
	end
	if forceNow then
		index = 0
	end
	local targetPad = FindNearestAirpad(unitID, team)
	if targetPad then
		--Spring.Echo(unitID.." directed to airpad "..targetPad)
		InsertCommand(unitID, index, CMD_REARM, {targetPad})
		--spGiveOrderToUnit(unitID, CMD.INSERT, {index, CMD_REARM, 0, targetPad}, {"alt"})
		return targetPad
	end
end
GG.RequestRearm = RequestRearm

function gadget:UnitCreated(unitID, unitDefID, team)
	if bomberDefs[unitDefID] then
		Spring.InsertUnitCmdDesc(unitID, 400, rearmCMD)
		Spring.InsertUnitCmdDesc(unitID, 401, findPadCMD)
		bomberUnitIDs[unitID] = true
	end
	--[[
	local id = Spring.FindUnitCmdDesc(unitID, CMD.WAIT)
	local desc = Spring.GetUnitCmdDescs(unitID, id, id)
	for i,v in ipairs(desc) do
		if type(v) == "table" then
			for a,b in pairs(v) do
				Spring.Echo(a,b)
			end
		end
	end
	]]--
end

function gadget:UnitFinished(unitID, unitDefID, team)
	if airpadDefs[unitDefID] then
		--Spring.Echo("Adding unit "..unitID.." to airpad list")
		local allyTeam = spGetUnitAllyTeam(unitID)
		airpads[unitID] = Spring.Utilities.CopyTable(airpadDefs[unitDefID], true)
		airpads[unitID].reservations = {count = 0, units = {}}
		airpadsPerAllyTeam[allyTeam][unitID] = true
	end
end

-- we don't need the airpad for now, free up a slot
local function CancelAirpadReservation(unitID)	
	local targetPad = bomberToPad[unitID]
	if not targetPad then return end
	
	--Spring.Echo("Clearing reservation by "..unitID.." at pad "..targetPad)
	bomberToPad[unitID] = nil
	if not airpads[targetPad] then return end
	local reservations = airpads[targetPad].reservations
	if reservations.units[unitID] then
		reservations.units[unitID] = nil
		reservations.count = math.max(reservations.count - 1, 0)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, team)
	if airpads[unitID] then
		local allyTeam = spGetUnitAllyTeam(unitID)
		--Spring.Echo("Removing unit "..unitID.." from airpad list")
		airpadsPerAllyTeam[allyTeam][unitID] = nil
		for bomberID in pairs(airpads[unitID].reservations.units) do
			CancelAirpadReservation(bomberID)	-- send anyone who was going here elsewhere
		end
		airpads[unitID] = nil
	elseif bomberDefs[unitDefID] then
		CancelAirpadReservation(unitID)
		bomberUnitIDs[unitID] = nil
		refuelling[unitID] = nil
	end
end

function gadget:AllowUnitTransfer(unitID, unitDefID, oldteam, newteam)
	gadget:UnitDestroyed(unitID, unitDefID, oldteam)
	gadget:UnitFinished(unitID, unitDefID, newteam)
	return true
end

function gadget:GameFrame(n)
	if n%10 == 2 then
		for bomberID in pairs(refuelling) do
			local fuel = spGetUnitFuel(bomberID) or 0
			if fuel >= MAX_FUEL then
				refuelling[bomberID] = nil
				Spring.SetUnitRulesParam(bomberID, "noammo", 0)	-- ready to go
				Spring.GiveOrderToUnit(bomberID,CMD.WAIT, {}, {})
				Spring.GiveOrderToUnit(bomberID,CMD.WAIT, {}, {})
			end
		end	
	end
	-- track proximity to bombers
	if n%10 == 0 then
		for bomberID in pairs(scheduleRearmRequest) do
			RequestRearm(bomberID, nil, true)
		end
		scheduleRearmRequest = {}
		for bomberID, padID in pairs(bomberToPad) do
			local queue = Spring.GetUnitCommands(bomberID, 1)
			if (queue and queue[1] and queue[1].id == CMD_REARM) and (Spring.GetUnitSeparation(bomberID, padID, true) < padRadius) then
				local tag = queue[1].tag
				--Spring.Echo("Bomber "..bomberID.." cleared for landing")
				CancelAirpadReservation(bomberID)
				spGiveOrderToUnit(bomberID, CMD.REMOVE, {tag}, {})	-- clear rearm order
				if Spring.GetUnitStates(bomberID)["repeat"] then 
					--spGiveOrderToUnit(bomberID, CMD_REARM, {padID}, {"shift"})
					InsertCommand(bomberID, 99999, CMD_REARM, {targetPad})
				end
				Spring.SetUnitFuel(bomberID, 0)	-- set fuel to zero
				Spring.GiveOrderToUnit(bomberID,CMD.WAIT, {}, {})
				Spring.GiveOrderToUnit(bomberID,CMD.WAIT, {}, {})
				bomberToPad[bomberID] = nil
				refuelling[bomberID] = true
				Spring.SetUnitRulesParam(bomberID, "noammo", 2)	-- refuelling
			end
		end
		
		for unitID in pairs(bomberUnitIDs) do -- CommandFallback doesn't seem to activate for inbuilt commands!!!
			if spGetUnitRulesParam(unitID, "noammo") == 1 then
				local queue = Spring.GetUnitCommands(unitID, 1)
				if queue and #queue > 0 and combatCommands[queue[1].id] then
					RequestRearm(unitID, nil, true)
				end
			end
		end
	end
end

function gadget:UnitIdle(unitID, unitDefID, team)
	if bomberDefs[unitDefID] then
		scheduleRearmRequest[unitID] = true
	end
end

--[[
function gadget:UnitCmdDone(unitID, unitDefID, team, cmdID, cmdTag)
	if bomberDefs[unitDefID] then RequestRearm(unitID) end
end
]]--

function gadget:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_REARM then	-- return to pad
		if spGetUnitRulesParam(unitID, "noammo") == 2 then
			return true, true -- attempting to rearm while already rearming, abort
		end
		--Spring.Echo("Returning to base")
		local targetPad = cmdParams[1]
		if not airpads[targetPad] then
			return true, true	-- trying to land on an unregistered (probably under construction) pad, abort
		end
		bomberToPad[unitID] = targetPad
		if not airpads[targetPad] then return false end
		local reservations = airpads[targetPad].reservations
		if not reservations.units[unitID] then
			reservations.units[unitID] = true
			reservations.count = reservations.count + 1
		end
		local x, y, z = Spring.GetUnitPosition(targetPad)
		Spring.SetUnitMoveGoal(unitID, x, y, z)
		return true, false	-- command used, don't remove
	elseif cmdID == CMD_FIND_PAD then
		scheduleRearmRequest[unitID] = true
		return true, true	-- command used, remove
	end
	return false -- command not used
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if spGetUnitRulesParam(unitID, "noammo") ~= 1 then
		local health, maxHealth = Spring.GetUnitHealth(unitID)
		if ((cmdID == CMD_REARM or cmdID == CMD_FIND_PAD) and not cmdOptions.shift and health > maxHealth - 1) then -- don't allow rearming unless damaged or need ammo
			return false 
		end	
	else
		if combatCommands[cmdID] and not bomberDefs[unitDefID].noAutoRearm then	-- trying to fight without ammo, go get ammo first!
			scheduleRearmRequest[unitID] = true
		end
	end
	if bomberToPad[unitID] then
		if cmdID ~= CMD_REARM and not cmdOptions.shift then
			CancelAirpadReservation(unitID)
		end
	end
	return true
end

-- not worth the system resources until bombers using reverse built pads is fixed for real
--[[
function gadget:AllowUnitBuildStep(builderID, teamID, unitID, unitDefID, step) 
	if step < 0 and airpads[unitID] and select(5,Spring.GetUnitHealth(unitID)) == 1 then
		gadget:UnitDestroyed(unitID, unitDefID, teamID)
	end
	return true
end
]]--

else
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
local airpads = SYNCED.airpads
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetLocalTeamID = Spring.GetLocalTeamID
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetSpectatingState = Spring.GetSpectatingState
local spValidUnitID = Spring.ValidUnitID

function gadget:DefaultCommand(type, targetID)
	if (type == 'unit') then
		local targetTeam = spGetUnitTeam(targetID)
		local selfTeam = spGetLocalTeamID()
		if not (spAreTeamsAllied(targetTeam, selfTeam)) then
			return
		end

		local selUnits = Spring.GetSelectedUnits()
		if (not selUnits[1]) then
			return  -- no selected units
		end

		local unitID, unitDefID
		for i = 1, #selUnits do
			unitID    = selUnits[i]
			unitDefID = spGetUnitDefID(unitID)
			if (not bomberDefs[unitDefID]) then
				return
			end
		end

		if airpads[targetID] then
			return CMD_REARM
		end
		return
	end
end

--[[ widget
local noAmmoTexture = 'LuaUI/Images/noammo.png'

local function DrawUnitFunc(yshift)
	gl.Translate(0,yshift,0)
	gl.Billboard()
	gl.TexRect(-10, -10, 10, 10)
end

local phase = 0

function gadget:DrawWorld()
	if Spring.IsGUIHidden() then return end
	local myAllyID = Spring.GetMyAllyTeamID()
	local isSpec, fullView = spGetSpectatingState()

	gl.Texture(noAmmoTexture)
	local units = Spring.GetVisibleUnits()
	for i=1,#units do
		local id = units[i]
		if spValidUnitID(id) and bomberDefs[spGetUnitDefID(id)] and ((isSpec and fullView) or spGetUnitAllyTeam(id) == myAllyID) then
			local ammoState = spGetUnitRulesParam(id, "noammo") or 0
			if (ammoState ~= 0)  then
				gl.DrawFuncAtUnit(id, false, DrawUnitFunc, UnitDefs[spGetUnitDefID(id)].height + 30)
			end
		end
	end
	gl.Texture("")
end
--]]
function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_REARM)
	Spring.SetCustomCommandDrawData(CMD_REARM, "Repair", {0, 1, 1, 1})
	Spring.SetCustomCommandDrawData(CMD_FIND_PAD, "Guard", {0, 1, 1, 1})
end

end