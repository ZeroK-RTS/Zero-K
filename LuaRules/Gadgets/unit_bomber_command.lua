------------------------------------------------------------------------------
-- HOW IT WORKS:
-- 	After firing, set ammo to 0 and look for a pad
--	Find first non-combat order and queue rearm order before it
--	If bomber idle and out of ammo (UnitIdle), give it rearm order
-- 	When bomber is in range of airpad (GameFrame), set fuel to zero	
--------------------------------------------------------------------------------
-- TODO
-- 	Redirect bombers if closest pad is already full (and clear the waiting line as needed)
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Bomber Command",
    desc      = "Handles bomber refuelling",
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


include "LuaRules/Configs/customcmds.h.lua"

local bomberNames = {
	"armstiletto_laser",
	"corshad",
	"corhurc2",
	--"armcybr",
}

local airpadNames = {
	armasp = {mobile = false, cap = 4},
	armcarry = {mobile = true, cap = 9},
}

local bomberDefs = {}
local airpadDefs = {}

for _,name in pairs(bomberNames) do
	if UnitDefNames[name] then bomberDefs[UnitDefNames[name].id] = true end
end
for name,data in pairs(airpadNames) do
	if UnitDefNames[name] then airpadDefs[UnitDefNames[name].id] = data end
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
	[CMD.DGUN] = true,
}

local padRadius = 500 -- land if pad is within this range

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--local CMD_REARM = CMD.MOVE

local rearmCMD = {
    id      = CMD_REARM,
    name    = "Rearm",
    action  = "rearm",
	cursor  = 'Repair',
    type    = CMDTYPE.ICON_UNIT,
	tooltip = "Select an airpad to return to for rearm",
}

local bomberToPad = {}	-- [bomberID] = detination pad ID
local airpads = {}	-- stores data
local airpadsPerAllyTeam = {}	-- [allyTeam] = {[pad1ID] = true, [pad2ID] = true, ..}
local allyteams = Spring.GetAllyTeamList()
for i=1,#allyteams do
	airpadsPerAllyTeam[allyteams[i]] = {}
end
local scheduleRearmRequest = {} -- [bomberID] = true	(used to avoid recursion in UnitIdle)

function gadget:Initialize()
	Spring.SetCustomCommandDrawData(CMD_REARM, "Guard", {0, 1, 1, 1})
	gadgetHandler:RegisterCMDID(CMD_REARM)
	local unitList = Spring.GetAllUnits()
	for i=1,#(unitList) do
		local ud = spGetUnitDefID(unitList[i])
		local team = spGetUnitTeam(unitList[i])
		gadget:UnitCreated(unitList[i], ud, team)
		gadget:UnitFinished(unitList[i], ud, team)
	end
end

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
	
	local mindist = 999999
	local closestPad
	for airpadID in pairs(freePads) do
		local dist = Spring.GetUnitSeparation(unitID, airpadID, true)
		if (dist < mindist) then
			mindist = dist
			closestPad = airpadID
		end
	end
	return closestPad
end

local function RequestRearm(unitID, team)
	team = team or spGetUnitTeam(unitID)
	if Spring.GetUnitRulesParam(unitID, "noammo") ~= 1 then return end
	--Spring.Echo(unitID.." requesting rearm")
	local queue = Spring.GetUnitCommands(unitID) or {}
	local index = #queue + 1
	for i=1, #queue do
		if combatCommands[queue[i].id] then
			index = i-1
			break
		elseif queue[i].id == CMD_REARM then	-- already have manually set rearm point, we have nothing left to do here
			return
		end
	end
	local targetPad = FindNearestAirpad(unitID, team)
	if targetPad then
		--Spring.Echo(unitID.." directed to airpad "..targetPad)
		spGiveOrderToUnit(unitID, CMD.INSERT, {index, CMD_REARM, 0, targetPad}, {"alt"})
		return targetPad
	end
end
GG.RequestRearm = RequestRearm

function gadget:UnitCreated(unitID, unitDefID, team)
	if bomberDefs[unitDefID] then
		Spring.InsertUnitCmdDesc(unitID, 400, rearmCMD)
	end
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
		reservations.count = math.max(reservations.count, 0)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, team)
	if airpadDefs[unitDefID] then
		local allyTeam = spGetUnitAllyTeam(unitID)
		--Spring.Echo("Removing unit "..unitID.." from airpad list")
		airpadsPerAllyTeam[allyTeam][unitID] = nil
		for bomberID in pairs(airpads[unitID].reservations.units) do
			CancelAirpadReservation(bomberID)	-- send anyone who was going here elsewhere
		end
		airpads[unitID] = nil
	elseif bomberDefs[unitDefID] then
		CancelAirpadReservation(unitID)
	end
end

function gadget:AllowUnitTransfer(unitID, unitDefID, oldteam, newteam)
	gadget:UnitDestroyed(unitID, unitDefID, oldteam)
	gadget:UnitFinished(unitID, unitDefID, newteam)
	return true
end

function gadget:GameFrame(n)
	-- track proximity to bombers
	if n%10 == 0 then
		for bomberID in pairs(scheduleRearmRequest) do
			RequestRearm(bomberID)
		end
		scheduleRearmRequest = {}
		for bomberID, padID in pairs(bomberToPad) do
			local queue = Spring.GetUnitCommands(bomberID)
			if (queue and queue[1] and queue[1].id == CMD_REARM) and Spring.GetUnitSeparation(bomberID, padID, true) < padRadius then
				local tag = queue[1].tag
				--Spring.Echo("Bomber "..bomberID.." cleared for landing")
				CancelAirpadReservation(bomberID)
				spGiveOrderToUnit(bomberID, CMD.REMOVE, {tag}, {})	-- clear rearm order
				Spring.SetUnitFuel(bomberID, 0)	-- set fuel to zero
				bomberToPad[bomberID] = nil
				Spring.SetUnitRulesParam(bomberID, "noammo", 0)	-- plane can fire again once it's refuelled
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
--[[	-- this part dinnae work
	if Spring.GetUnitRulesParam(unitID, "noammo") == 1 and combatCommands[cmdID]  then
		return true, true	-- command used, clear it so we can get on with the rearming
	end
]]
	if cmdID == CMD_REARM then	-- return to pad
		if Spring.GetUnitRulesParam(unitID, "noammo") ~= 1 then
			return true, true -- attempting to rearm while already armed, abort
		end
		--Spring.Echo("Returning to base")
		local targetPad = cmdParams[1]
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
	end
	return false -- command not used
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if Spring.GetUnitRulesParam(unitID, "noammo") == 1 then
		if (combatCommands[cmdID] and not cmdOptions.shift) then
			return false
		elseif (cmdID == CMD.INSERT and combatCommands[cmdParams[2]]) then
			-- FIXME: allow insertion of attack commands after refuel command, block otherwise
		end
	else
		if (cmdID == CMD_REARM and not cmdOptions.shift) then return false end	-- don't allow rearming when already armed
	end
	if bomberToPad[unitID] then
		if cmdID ~= CMD_REARM and not cmdOptions.shift then
			CancelAirpadReservation(unitID)
		end
	end
	return true
end


else
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------

function gadget:DefaultCommand(type, targetID)
	if (type == 'unit') then
		if not (Spring.IsUnitAllied(targetID)) then
			return  -- capture allied units? na
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

		local targetDefID = spGetUnitDefID(targetID)
		if airpadDefs[targetDefID] then
			return CMD_REARM
		end
		return
	end
end

local noAmmoTexture = 'LuaUI/Images/noammo.png'

local function DrawUnitFunc(yshift)
	gl.Translate(0,yshift,0)
	gl.Billboard()
	gl.TexRect(-10, -10, 10, 10)
end

function gadget:DrawWorld()
	if Spring.IsGUIHidden() then return end
	local myAllyID = Spring.GetMyAllyTeamID()

	gl.Texture(noAmmoTexture)	
	gl.Color(1,1,1,1)
	local units = Spring.GetVisibleUnits()
	for i=1,#units do
		local id = units[i]
		if Spring.ValidUnitID(id) and spGetUnitDefID(id) and Spring.GetUnitRulesParam(id, "noammo") == 1 then
			gl.DrawFuncAtUnit(id, false, DrawUnitFunc, UnitDefs[spGetUnitDefID(id)].height + 30)
		end
	end
	gl.Texture("")
end

end