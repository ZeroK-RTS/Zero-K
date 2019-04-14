------------------------------------------------------------------------------
-- HOW IT WORKS:
-- 	After firing, set ammo to 0 and look for a pad
--	Find first combat order and queue rearm order before it
--	If bomber idle and out of ammo (UnitIdle), give it rearm order
-- 	When bomber is in range of airpad (GameFrame), call GG.SendBomberToPad(bomberID, padID, padPiece)
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
    author    = "xponen, KingRaptor, GoogleFrog",
    date      = "20 April 2014, 25 Feb 2011",
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
local spSetUnitRulesParam	= Spring.SetUnitRulesParam
local spAreTeamsAllied = Spring.AreTeamsAllied

include "LuaRules/Configs/customcmds.h.lua"

local airpadDefs = {
	[UnitDefNames["factoryplane"].id] = {
		mobile = false, 
		cap = 1, 
		padPieceName={"land"}
	},
	[UnitDefNames["staticrearm"].id] = {
		mobile = false, 
		cap = 4, 
		padPieceName={"land1","land2","land3","land4"}
	},
	[UnitDefNames["shipcarrier"].id] = {
		mobile = true, 
		cap = 2, 
		padPieceName={"LandingFore","LandingAft"}
	},
}

 -- land if pad is within this range
local fixedwingPadRadius = 600
local gunshipPadRadius = 160
local DEFAULT_PAD_RADIUS = 300

local airDefs = {}
local boolAirDefs = {}
for i = 1, #UnitDefs do
	local unitDef = UnitDefs[i]
	local movetype = Spring.Utilities.getMovetype(unitDef)
	if (movetype == 1 or movetype == 0) and (not Spring.Utilities.tobool(unitDef.customParams.cantuseairpads)) then
		airDefs[i] = {
			builder   = unitDef.isBuilder,
			fixedwing = (movetype == 0),
			padRadius = ((movetype == 0) and fixedwingPadRadius) or gunshipPadRadius
		}
		boolAirDefs[i] = true
	end
end

local bomberDefs = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	bomberDefs[i] = (ud.isBomber or ud.customParams.reallyabomber)
end

if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetUnitsInBox	= Spring.GetUnitsInBox
local spGetUnitPieceMap = Spring.GetUnitPieceMap
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitPiecePosition = Spring.GetUnitPiecePosition 
local spGetUnitVectors = Spring.GetUnitVectors
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetCommandQueue = Spring.GetCommandQueue

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

local defaultCommands = { -- commands that is processed by gadget
	[CMD.ATTACK] = true,
	[CMD.AREA_ATTACK] = true,
	[CMD.FIGHT] = true,
	[CMD.PATROL] = true,
	[CMD.GUARD] = true,
	[CMD.MANUALFIRE] = true,
	[CMD_REARM] = true,
	[CMD_FIND_PAD] = true,
	[CMD.MOVE] = true,
	[CMD_RAW_MOVE] = true,
	[CMD_RAW_BUILD] = true,
	[CMD.REMOVE] = true,
	[CMD.INSERT] = true,
}

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
    action  = "find_pad",
	cursor  = 'Repair',
    type    = CMDTYPE.ICON,
	tooltip = "Search for nearest available airpad to return to for rearm",
	hidden	= false,
}

local emptyTable = {}

local airpadsData = {}	-- stores data
local airpadsPerAllyteam = {}	-- [allyTeam] = {[pad1ID] = unitDefID1, [pad2ID] = unitDefID2, ..}
local bomberUnitIDs = {}
local bomberToPad = {}	-- [bomberID] = detination pad ID
local bomberLanding = {} -- [bomberID] = true
local rearmRequest = {} -- [bomberID] = true	(used to avoid recursion in UnitIdle)
local rearmRemove = {}
local cmdIgnoreSelf = false
-- local totalReservedPad = 0

_G.airpadsData = airpadsData

function gadget:Initialize()
	local allyteams = Spring.GetAllyTeamList()
	for i=1,#allyteams do
		airpadsPerAllyteam[allyteams[i]] = {}
	end
	local unitList = Spring.GetAllUnits()
	for i=1,#(unitList) do
		local ud = spGetUnitDefID(unitList[i])
		local team = spGetUnitTeam(unitList[i])
		gadget:UnitCreated(unitList[i], ud, team)
		gadget:UnitFinished(unitList[i], ud, team)
	end
end

local function MakeOptsWithShift(opts)
	return opts.coded + (opts.shift and 0 or CMD.OPT_SHIFT)
end

local function InsertCommand(unitID, index, cmdID, params, opts, toReplace)
	--Note: 'toReplace==true' means command at 'index' is replaced with 'cmdID' instead of being sandwiched between old commands at 'index'
	
	-- workaround for STOP not clearing attack order due to auto-attack
	-- we set it to hold fire temporarily, revert once commands have been reset
	local queue = spGetCommandQueue(unitID, -1)
	local firestate = Spring.Utilities.GetUnitFireState(unitID)
	spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, 0)
	spGiveOrderToUnit(unitID, CMD.STOP, emptyTable, 0)
	if queue then
		local cmdOpt = opts and MakeOptsWithShift(opts) or CMD.OPT_SHIFT
		local i = 1
		local toInsert = (index >= 0)
		local commands = #queue
		while i <= commands do
			if i-1 == index and toInsert then
				spGiveOrderToUnit(unitID, cmdID, params, cmdOpt)
				toInsert = false
				if toReplace then
					i = i + 1
				end
			else
				local cmd = queue[i]
				spGiveOrderToUnit(unitID, cmd.id, cmd.params, MakeOptsWithShift(cmd.options))
				i = i + 1
			end
			--local cq = spGetCommandQueue(unitID) for i = 1, #cq do Spring.Echo(cq[i].id) end
		end
		if toInsert or index < 0 then
			spGiveOrderToUnit(unitID, cmdID, params, cmdOpt)
		end
	end
	spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, 0)
end
GG.InsertCommand = InsertCommand

local function RefreshEmptyPad(airpadID,airpadDefID)
	if airpadDefs[airpadDefID] then
		local piecesList = spGetUnitPieceMap(airpadID)
		local padPieceName = airpadDefs[airpadDefID].padPieceName
		local ux,uy,uz = spGetUnitPosition(airpadID)
		local front, top, right = spGetUnitVectors(airpadID)
		airpadsData[airpadID].emptySpot = {}
		for i=1, airpadDefs[airpadDefID].cap do
			local padName = padPieceName[i]
			local pieceNum = piecesList[padName]
			local x,y,z = spGetUnitPiecePosition(airpadID, pieceNum)
			local offX = front[1]*z + top[1]*y + right[1]*x
			local offY = front[2]*z + top[2]*y + right[2]*x
			local offZ = front[3]*z + top[3]*y + right[3]*x
			local uxx,uyy,uzz = ux+offX, uy+offY, uz+offZ
			local somethingOnThePad = spGetUnitsInBox(uxx-20,uyy-20,uzz-20, uxx+20,uyy+20,uzz+20)
			local unit1 = somethingOnThePad[1]
			local unit2 = somethingOnThePad[2]
			if (#somethingOnThePad == 1 and unit1== airpadID) or 
			(#somethingOnThePad == 0) then
				airpadsData[airpadID].emptySpot[#airpadsData[airpadID].emptySpot+1] = pieceNum; --Spring.MarkerAddPoint(uxx,uyy,uzz, "O")
			end
		end
	end
end

local function RefreshEmptyspot_minusBomberLanding()
	for allyTeam in pairs(airpadsPerAllyteam) do --all airpads
		for airpadID,airpadUnitDefID in pairs (airpadsPerAllyteam[allyTeam]) do
			if spGetUnitIsDead(airpadID) then --rare case. Can happen if airpad is built & die in same frame
				airpadsPerAllyteam[allyTeam][airpadID] = nil
			else
				RefreshEmptyPad(airpadID,airpadUnitDefID)
			end
		end
	end
	for bomberID,data in pairs(bomberLanding) do --airplane about to land
		local bomberAirpadID = data.padID
		for i=1, #airpadsData[bomberAirpadID].emptySpot do
			local padPiece = data.padPiece
			if airpadsData[bomberAirpadID].emptySpot[i]== padPiece then
				table.remove(airpadsData[bomberAirpadID].emptySpot,i)
				break
			end
		end
	end
end

local function FindBestAirpadAt(unitID, x, z, r) -- picks the least crowded pad in R radius around X/Z
	local allyTeam = spGetUnitAllyTeam(unitID)
	if not airpadsPerAllyteam[allyTeam] then
		return
	end

	local bestPadID
	local bestPadBookFactor = 9001
	for airpadID, airpadDefID in pairs(airpadsPerAllyteam[allyTeam]) do
		local bookFactor = airpadsData[airpadID].reservations.count / airpadsData[airpadID].cap
		if bookFactor < bestPadBookFactor then
			local ux, uy, uz = Spring.GetUnitPosition(airpadID)
			if (ux-x)^2 + (uz-z)^2 < r^2 then
				bestPadID = airpadID
				bestPadBookFactor = bookFactor
			end
		end
	end

	return bestPadID
end

local function FindNearestAirpad(unitID, team)
	--Spring.Echo(unitID.." checking for closest pad")
	local allyTeam = spGetUnitAllyTeam(unitID)
	local freePads = {}
	local freePadCount = 0
	if not airpadsPerAllyteam[allyTeam] then
		return
	end
	-- first go through all the pads to see which ones are unbooked
	for airpadID,airpadDefID in pairs(airpadsPerAllyteam[allyTeam]) do
		if spGetUnitIsDead(airpadID) or (not airpadsData[airpadID]) then --rare case. Can happen if airpad is built & die in same frame
			if (not airpadsData[airpadID]) then
				Spring.Echo("Warning: airpadsData for " .. airpadID .. " is NIL")
			end
			airpadsPerAllyteam[allyTeam][airpadID] = nil
		else
			if (airpadsData[airpadID].reservations.count < airpadsData[airpadID].cap) then
				freePads[airpadID] = true
				freePadCount = freePadCount + 1
			end
		end
	end
	-- if no free pads, just use all of them
	if freePadCount == 0 then
		--Spring.Echo("No free pads, directing to closest one")
		freePads = airpadsPerAllyteam[allyTeam]
	end
	
	local minDist = 999999
	local closestPad
	for airpadID in pairs(freePads) do
		local excessReservation = math.modf(airpadsData[airpadID].reservations.count/airpadsData[airpadID].cap) --output: return "0" if airpad NOT full, return "1" if airpad is full, return "2" if twice as full, return "3" if thrice as full.
		excessReservation = math.min(10,excessReservation) --clamp to avoid crazy value
		local dist = Spring.GetUnitSeparation(unitID, airpadID, true)
		dist = dist + (50*excessReservation)^2
		dist = math.min(999998, dist) --clamp to avoid crazy value
		if (dist < minDist) then
			minDist = dist
			closestPad = airpadID
		end
	end
	return closestPad
end

local function RequestRearm(unitID, team, forceNow, replaceExisting)
	if spGetUnitRulesParam(unitID, "airpadReservation") == 1 then
		return false --already reserved an airpad, do not reserve another one again
	end
	team = team or spGetUnitTeam(unitID)
	if spGetUnitRulesParam(unitID, "noammo") ~= 1 then
		local health, maxHealth = Spring.GetUnitHealth(unitID)
		if health and maxHealth and health > maxHealth - 1 then
			return false
		end
	end
	
	local unitDefID = Spring.GetUnitDefID(unitID)
	if unitDefID and bomberDefs[unitDefID] then
		-- Remove fight orders to implement a fight command version of CommandFire if Fight is the last command.
		local queueLength = spGetCommandQueue(unitID, 0)
		if queueLength <= 2 and (not Spring.Utilities.GetUnitRepeat(unitID)) then
			spGiveOrderToUnit(unitID, CMD.REMOVE, {CMD.FIGHT}, CMD.OPT_ALT)
		end
	end
	
	--Spring.Utilities.UnitEcho(unitID, "requesting rearm")
	local detectedRearm = false
	local queue = spGetCommandQueue(unitID, -1) or emptyTable
	local index = #queue + 1
	for i = 1, #queue do
		if combatCommands[queue[i].id] then
			index = i - 1
			break
		elseif queue[i].id == CMD_REARM then -- already have set rearm point, we have nothing left to do here
			detectedRearm = true
			if (not replaceExisting) then
				return bomberToPad[unitID], index	-- FIXME
			end
		elseif queue[i].id == CMD_FIND_PAD then	-- already have find airpad command, we might be doing same work twice, skip
			return
		end
	end
	if forceNow then
		index = 0
	end
	local targetPad = FindNearestAirpad(unitID, team) --UnitID find non-reserved airpad as target
	if targetPad then
		--Spring.Utilities.UnitEcho(targetPad, "targetPad")
		cmdIgnoreSelf = true
		ReserveAirpad(unitID, targetPad)
		--Spring.Echo(unitID.." directed to airpad "..targetPad)
		local replaceExistingRearm = (detectedRearm and replaceExisting) --replace existing Rearm (if available)
		-- InsertCommand(unitID, index, CMD_REARM, {targetPad}, nil, replaceExistingRearm) --UnitID get RE-ARM commandID. airpadID as its Params[1]
		if replaceExistingRearm then
			spGiveOrderToUnit(unitID, CMD.REMOVE, {index}, 0)
		end
		spGiveOrderToUnit(unitID, CMD.INSERT, {index, CMD_REARM, CMD.OPT_SHIFT + CMD.OPT_INTERNAL, targetPad}, CMD.OPT_ALT) --Internal to avoid repeat
		cmdIgnoreSelf = false
		return targetPad, index
	end
end

GG.RequestRearm = RequestRearm
GG.FindBestAirpadAt = FindBestAirpadAt

function gadget:UnitCreated(unitID, unitDefID, team)
	if airDefs[unitDefID] then
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
		local allyTeam = select(6, Spring.GetTeamInfo(team, false))
		airpadsData[unitID] = Spring.Utilities.CopyTable(airpadDefs[unitDefID], true)
		airpadsData[unitID].reservations = {count = 0, units = {}}
		airpadsData[unitID].emptySpot = {}
		airpadsPerAllyteam[allyTeam][unitID] = unitDefID
		spSetUnitRulesParam(unitID,"unreservedPad",airpadsData[unitID].cap) --hint widgets
	end
end

-- we don't need the airpad for now, free up a slot
local function CancelAirpadReservation(unitID)
	spSetUnitRulesParam(unitID, "airpadReservation",0)
	if GG.LandAborted then
		GG.LandAborted(unitID)
	end
	
	--value greater than 1 for icon state:
	if spGetUnitRulesParam(unitID, "noammo") == 3 then -- repairing
		local env = Spring.UnitScript.GetScriptEnv(unitID)
		if env and env.SetArmedAI then
			Spring.UnitScript.CallAsUnit(unitID, env.SetArmedAI)
		end
		spSetUnitRulesParam(unitID, "noammo", 0)
	elseif spGetUnitRulesParam(unitID, "noammo") == 2 then -- refueling
		spSetUnitRulesParam(unitID, "noammo", 1)
	end
	
	local targetPad
	if bomberToPad[unitID] then -- unit was going toward an airpad
		targetPad = bomberToPad[unitID].padID
		bomberToPad[unitID] = nil
	elseif bomberLanding[unitID] then -- unit was on the airpad
		targetPad = bomberLanding[unitID].padID
		bomberLanding[unitID] = nil
	end
	if not targetPad then
		return
	end

	--Spring.Echo("Clearing reservation by "..unitID.." at pad "..targetPad)
	if not airpadsData[targetPad] then 
		return 
	end
	local reservations = airpadsData[targetPad].reservations
	if reservations.units[unitID] then
		-- totalReservedPad = totalReservedPad -1
		reservations.units[unitID] = nil
		reservations.count = math.max(reservations.count - 1, 0)
		spSetUnitRulesParam(targetPad,"unreservedPad",math.max(0,airpadsData[targetPad].cap-reservations.count)) --hint widgets
	end
end

function ReserveAirpad(bomberID,airpadID)
	spSetUnitRulesParam(bomberID, "airpadReservation",1)
	local reservations = airpadsData[airpadID].reservations
	if not reservations.units[bomberID] then
		bomberToPad[bomberID] = {padID = airpadID, unitDefID = spGetUnitDefID(bomberID)}
		-- totalReservedPad = totalReservedPad + 1
		reservations.units[bomberID] = true --UnitID pre-reserve airpads so that next UnitID (if available) don't try to reserve the same spot
		reservations.count = reservations.count + 1
		spSetUnitRulesParam(airpadID,"unreservedPad",math.max(0,airpadsData[airpadID].cap-reservations.count)) --hint widgets
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, team)
	if airpadsData[unitID] then
		local allyTeam = select(6, Spring.GetTeamInfo(team, false))
		--Spring.Echo("Removing unit "..unitID.." from airpad list")
		airpadsPerAllyteam[allyTeam][unitID] = nil
		for bomberID in pairs(airpadsData[unitID].reservations.units) do
			CancelAirpadReservation(bomberID)	-- send anyone who was going here elsewhere
		end
		airpadsData[unitID] = nil
	elseif airDefs[unitDefID] then
		CancelAirpadReservation(unitID)
		bomberUnitIDs[unitID] = nil
	end
end

function GG.AircraftCrashingDown(unitID)
	CancelAirpadReservation(unitID)
	bomberUnitIDs[unitID] = nil
	--note: we don't worry about user re-doing REARM cmd or CommandFallback re-doing reservation because crashing airplane do not call CommandFallback
	--and unit_aircraft_crash.lua SetUnitNoSelect
end

function gadget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	if not spAreTeamsAllied(oldTeam, newTeam) then
		gadget:UnitDestroyed(unitID, unitDefID, oldTeam)
		gadget:UnitCreated(unitID, unitDefID, newTeam)
		gadget:UnitFinished(unitID, unitDefID, newTeam)
	end
end

function gadget:GameFrame(n)
	-- if n%30 == 0 then
		-- Spring.Echo(totalReservedPad)
	-- end
	for bomberID in pairs(rearmRequest) do
		RequestRearm(bomberID, nil, true)
		rearmRequest[bomberID] = nil
	end
	
	if n%120 == 0 then
		for airpadID, data in pairs(airpadsData) do
			local _,_,inbuild = spGetUnitIsStunned(airpadID)
			if inbuild then --if user reclaim airpad, send airplane elsewhere
				local allyTeam = spGetUnitAllyTeam(airpadID)
				airpadsPerAllyteam[allyTeam][airpadID] = nil
				for bomberID in pairs(airpadsData[airpadID].reservations.units) do
					CancelAirpadReservation(bomberID)	-- send anyone who was going here elsewhere
					RequestRearm(bomberID, nil, false, true) --argument: (bomberID, team, forceNow, replaceExisting)
				end
				airpadsData[airpadID] = nil
			end
		end
	end
	-- track bomber-airpad distance
	if n%10 == 0 then
		local airpadRefreshEmptyspot = nil;
		for bomberID, data in pairs(bomberToPad) do
			local padID = data.padID
			local unitDefID = data.unitDefID
			if (Spring.Utilities.GetUnitFirstCommand(bomberID) == CMD_REARM) and 
					((Spring.GetUnitSeparation(bomberID, padID, true) or 1000) < ((unitDefID and airDefs[unitDefID] and airDefs[unitDefID].padRadius) or DEFAULT_PAD_RADIUS)) then
				if not airpadRefreshEmptyspot then
					RefreshEmptyspot_minusBomberLanding() --initialize empty pad count once
					airpadRefreshEmptyspot = true
				end
				if airpadsData[padID] then
					local spotCount = #airpadsData[padID].emptySpot
					if spotCount>0 then
						local padPiece = airpadsData[padID].emptySpot[spotCount]
						table.remove(airpadsData[padID].emptySpot) --remove used spot
						if Spring.Utilities.GetUnitRepeat(bomberID) then 
							cmdIgnoreSelf = true
							-- InsertCommand(bomberID, 99999, CMD_REARM, {targetPad})
							spGiveOrderToUnit(bomberID, CMD.INSERT, {-1, CMD_REARM, CMD.OPT_SHIFT + CMD.OPT_INTERNAL, targetPad}, CMD.OPT_ALT) --Internal to avoid repeat
							cmdIgnoreSelf = false
						end
						if GG.SendBomberToPad then
							GG.SendBomberToPad(bomberID, padID, padPiece)
						end
						bomberToPad[bomberID] = nil
						bomberLanding[bomberID] = {padID=padID,padPiece=padPiece}
						
						--value greater than 1 is for icon state, and it block bomber from firing while on airpad:
						local noAmmo = spGetUnitRulesParam(bomberID, "noammo")
						if noAmmo == 1 then
							spSetUnitRulesParam(bomberID, "noammo", 2)	-- mark bomber as refuelling
						elseif not noAmmo or noAmmo==0 then
							spSetUnitRulesParam(bomberID, "noammo", 3)	-- mark bomber as repairing
						end
					end
				end
			end
		end
		
		for unitID in pairs(bomberUnitIDs) do -- CommandFallback doesn't seem to activate for inbuilt commands!!! <-- What this really mean?
			if spGetUnitRulesParam(unitID, "noammo") == 1 then
				local cmdID = Spring.Utilities.GetUnitFirstCommand(unitID)
				if (not cmdID) or combatCommands[cmdID] then --should never happen... (all should be catch by AllowCommand) 
					RequestRearm(unitID, nil, true)
				end
			end
		end
	end
end

function GG.RequireRefuel(bomberID)
	return (spGetUnitRulesParam(bomberID, "noammo") == 2) 
end

function GG.RefuelComplete(bomberID)
	spSetUnitRulesParam(bomberID, "noammo", 3)	-- mark bomber as repairing/ not refueling anymore
end

function GG.LandComplete(bomberID)
	local bomberData = bomberLanding[bomberID]
	local padID = bomberData and bomberData.padID

	CancelAirpadReservation(bomberID) -- cancel reservation and mark bomber as free to fire
	spGiveOrderToUnit(bomberID,CMD.WAIT, emptyTable, 0)
	spGiveOrderToUnit(bomberID,CMD.WAIT, emptyTable, 0)
	
	-- Check queue inheritence
	local queueLength = spGetCommandQueue(bomberID, 0)
	local cmdID = Spring.Utilities.GetUnitFirstCommand(bomberID)
	if (queueLength == 0 or (queueLength == 1 and (cmdID == CMD_REARM or cmdID == 0))) and 
			(padID and airpadsData[padID] and not airpadsData[padID].mobile) then
		local padQueueLength = spGetCommandQueue(padID, 0)
		if padQueueLength > 0 then
			local padQueue = spGetCommandQueue(padID, -1)
			for i = 1, #padQueue do
				padQueue[i][1] = padQueue[i].id
				padQueue[i][2] = padQueue[i].params
				padQueue[i][3] = padQueue[i].options.coded
			end
			spGiveOrderToUnit(bomberID,CMD.STOP, emptyTable, 0)
			Spring.GiveOrderArrayToUnitArray({bomberID}, padQueue)
			return
		end
	end
	
	-- Remove rearm if the queue was not inherited.
	if cmdID == CMD_REARM then
		rearmRemove[bomberID] = true --remove current RE-ARM command
	end
end

function gadget:UnitIdle(unitID, unitDefID, team)
	if airDefs[unitDefID] and spGetUnitRulesParam(unitID, "noammo") == 1 then
		rearmRequest[unitID] = true
	end
end

--[[
function gadget:UnitCmdDone(unitID, unitDefID, team, cmdID, cmdTag)
	if airDefs[unitDefID] then RequestRearm(unitID) end
end
]]--

function gadget:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions,cmdTag)
	if cmdID == CMD_REARM then	-- return to pad
		if not airDefs[unitDefID] then
			return true, true	-- trying to REARM using unauthorized unit
		end
		if rearmRemove[unitID] then
			rearmRemove[unitID] = nil
			return true, true
		end
		if bomberLanding[unitID] then
			return true, false --keep command while landing
		end
		--Spring.Echo("Returning to base")
		local targetAirpad = cmdParams[1]
		if not airpadsData[targetAirpad] then
			return true, true	-- trying to land on an unregistered (probably under construction) pad, abort
		end
		ReserveAirpad(unitID,targetAirpad) --Reserve the airpad specified in RE-ARM params (if not yet reserved)
		local x, y, z = Spring.GetUnitPosition(targetAirpad)
		Spring.SetUnitMoveGoal(unitID, x, y, z) -- try circle the airpad until free airpad allow bomberLanding.
		return true, false	-- command used, don't remove
	elseif cmdID == CMD_FIND_PAD then
		if airDefs[unitDefID] then
			rearmRequest[unitID] = true
		end
		return true,true
	end
	return false -- command not used
end

function gadget:AllowCommand_GetWantedCommand()
	return defaultCommands --command which is expected by gadget, other command is unhandled cases
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return boolAirDefs --gadget:AllowCommand only check bombers/gunships
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if cmdIgnoreSelf then  --don't re-read rewritten bomber's command
		return true
	end
	---------------------
	local noAmmo = spGetUnitRulesParam(unitID, "noammo")
	if not noAmmo or noAmmo == 0 then
		local health, maxHealth = Spring.GetUnitHealth(unitID)
		if ((cmdID == CMD_REARM or cmdID == CMD_FIND_PAD) and not cmdOptions.shift and health > maxHealth - 1) then
			return false  -- don't rearm unless damaged or need ammo
		end	
	elseif noAmmo == 2 or noAmmo==3 then
		if (cmdID == CMD_REARM or cmdID == CMD_FIND_PAD) and not cmdOptions.shift then
			return false --don't find new pad if already on the pad currently refueling or repairing.
		end
		if noAmmo == 2 then --don't leave in the middle of rearming, allow command and skip CancelAirpadReservation
			return true
		end
	elseif noAmmo == 1 then
		if combatCommands[cmdID] or cmdID == CMD.STOP then	-- don't fight without ammo, go get ammo first!
			rearmRequest[unitID] = true
		end
	end
	if bomberToPad[unitID] or bomberLanding[unitID] then
		if not cmdOptions.shift then
			CancelAirpadReservation(unitID) --don't leave airpad reservation hanging, empty them when bomber is given other task
		end
	end
	
	return true
end

-- not worth the system resources until bombers using reverse built pads is fixed for real
--[[
function gadget:AllowUnitBuildStep(builderID, teamID, unitID, unitDefID, step) 
	if step < 0 and airpadsData[unitID] and select(5,Spring.GetUnitHealth(unitID)) == 1 then
		gadget:UnitDestroyed(unitID, unitDefID, teamID)
	end
	return true
end
]]--

else
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
local spGetLocalTeamID = Spring.GetLocalTeamID
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetSpectatingState = Spring.GetSpectatingState
local spValidUnitID = Spring.ValidUnitID
local spGetSelectedUnits = Spring.GetSelectedUnits

function gadget:DefaultCommand(type, targetID)
	if (type == 'unit') and airpadDefs[spGetUnitDefID(targetID)] then
		local targetTeam = spGetUnitTeam(targetID)
		local selfTeam = spGetLocalTeamID()
		if not (spAreTeamsAllied(targetTeam, selfTeam)) then
			return
		end

		local selUnits = spGetSelectedUnits()
		if (not selUnits[1]) then
			return  -- no selected units
		end

		local unitID, unitDefID
		for i = 1, #selUnits do
			unitID    = selUnits[i]
			unitDefID = spGetUnitDefID(unitID)
			if airDefs[unitDefID] and not airDefs[unitDefID].builder then
				return CMD_REARM
			end
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
		if spValidUnitID(id) and airDefs[spGetUnitDefID(id)] and ((isSpec and fullView) or spGetUnitAllyTeam(id) == myAllyID) then
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
	Spring.SetCustomCommandDrawData(CMD_REARM, "Repair", {0, 1, 1, 0.7})
	Spring.SetCustomCommandDrawData(CMD_FIND_PAD, "Guard", {0, 1, 1, 0.7})
end

end
