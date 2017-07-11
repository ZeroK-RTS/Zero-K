--  Copyright (C) 2016.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Smart Bombers",
    desc      = "Automatically sets bombers to fire at will when following fight or patrol orders, and hold fire otherwise.",
    author    = "aeonios",
    date      = "Nov, 2016",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetCommandQueue = Spring.GetCommandQueue
local spGetSpectatingState = Spring.GetSpectatingState
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetMyTeamID = Spring.GetMyTeamID

local myTeamID

local fightingBombers = {}
local reservedBombers = {}

local bombderDefIDs = {
	[UnitDefNames["bomberprec"].id] = true,
	[UnitDefNames["bomberriot"].id] = true,
	[UnitDefNames["bomberdisarm"].id] = true,
	[UnitDefNames["bomberheavy"].id] = true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CheckSpec()
	myTeamID = spGetMyTeamID()
	if spGetSpectatingState() then
		Spring.Echo("Spectating: Widget Removed")
		widgetHandler:RemoveWidget()
	end
end

--	Borrowed this from CarRepairer's Retreat.  Returns only first command in queue.
function GetFirstCommand(unitID)
	local queue = spGetCommandQueue(unitID, 1)
	return queue and queue[1]
end

local function CheckUnit(unitID, unitDefID)
	if not bombderDefIDs[unitDefID] then
		return
	end
	local cmd = GetFirstCommand(unitID)
	if cmd and (cmd.id == CMD.FIGHT or cmd.id == CMD.PATROL) then
		local oldFirestate = Spring.GetUnitStates(unitID).firestate or 0
		spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {2}, {""}) -- fire at will
		fightingBombers[unitID] = oldFirestate
	else
		local oldFirestate = fightingBombers[unitID]
		if oldFirestate then
			spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {oldFirestate}, {""}) -- restore old firestate
		end
		reservedBombers[unitID] = true
	end
end

local function CheckBombers()
	for unitID, _ in pairs(fightingBombers) do
		-- clean dead or captured bombers
		if (not Spring.ValidUnitID(unitID) or Spring.GetUnitTeam(unitID) ~= myTeamID) then
			fightingBombers[unitID] = nil
		else
			-- swap bombers whose commands have changed and update their firestate
			local cmd = GetFirstCommand(unitID)
			if cmd and (cmd.id == CMD.FIGHT or cmd.id == CMD.PATROL) then
				-- do nothing
			else
				local oldFirestate = fightingBombers[unitID]
				if oldFirestate then
					spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {oldFirestate}, {""}) -- restore old firestate
				end
				fightingBombers[unitID] = nil
				reservedBombers[unitID] = true
			end
		end
	end

	for unitID, _ in pairs(reservedBombers) do
		-- clean dead or captured bombers
		if (not Spring.ValidUnitID(unitID) or Spring.GetUnitTeam(unitID) ~= myTeamID) then
			reservedBombers[unitID] = nil
		else
			-- swap bombers whose commands have changed and update their firestate
			local cmd = GetFirstCommand(unitID)
			if cmd and (cmd.id == CMD.FIGHT or cmd.id == CMD.PATROL) then
				local oldFirestate = Spring.GetUnitStates(unitID).firestate or 0
				spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {2}, {""}) -- fire at will
				fightingBombers[unitID] = oldFirestate
				reservedBombers[unitID] = nil
			else
				-- do nothing
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget interface

function widget:Initialize()
	CheckSpec()
	local myTeamID = Spring.GetMyTeamID()
	for _, unitID in pairs(Spring.GetTeamUnits(myTeamID)) do
		widget:UnitFinished(unitID, Spring.GetUnitDefID(unitID), myTeamID)
	end
end

function widget:PlayerChanged()
	CheckSpec()
end

function widget:GameFrame(frame)
	if frame % 15 == 0 then
		CheckBombers()
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if (unitTeam ~= myTeamID) then
		return
	end
	CheckUnit(unitID, unitDefID)
end

function widget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	if newTeam == myTeamID then
		CheckUnit(unitID, unitDefID)
	end
end