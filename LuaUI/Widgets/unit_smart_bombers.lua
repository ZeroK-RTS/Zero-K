-- $Id: cmd_unit_mover.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    cmd_unit_mover.lua
--  brief:   Allows combat engineers to use repeat when building mobile units (use 2 or more build spots)
--  author:  Owen Martindell
--
--  Copyright (C) 2007.
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

local spGetCommandQueue = Spring.GetCommandQueue
local GetPlayerInfo = Spring.GetPlayerInfo
local GetUnitPosition = Spring.GetUnitPosition
local GiveOrderToUnit = Spring.GiveOrderToUnit
local myTeamID = Spring.GetMyTeamID()
local Echo = Spring.Echo

--------------------------------------------------------------------------------

local fightingBombers = {}
local reservedBombers = {}
local myID

local function checkSpec()
  local _, _, spec = GetPlayerInfo(myID)
  if spec then
	Echo("Spectating: Widget Removed")
    widgetHandler:RemoveWidget()
  end
end

--	Borrowed this from CarRepairer's Retreat.  Returns only first command in queue.
function GetFirstCommand(unitID)
	local queue = spGetCommandQueue(unitID, 1)
	return queue[1]
end

function widget:Initialize()
	myID = Spring.GetMyPlayerID()
	checkSpec()
end

function widget:GameFrame(frame)
	if frame % 15 == 0 then
		checkSpec()
		checkBombers()
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

function CheckUnit(unitID, unitDefID)
	local ud = UnitDefs[unitDefID]
	if (ud and (ud.name == "corshad" or ud.name == "corhurc2" or ud.name == "armstiletto_laser" or ud.name == "armcybr")) then
		local cmd = GetFirstCommand(unitID)
		if cmd and (cmd.id == 16 or cmd.id == 15) then
			GiveOrderToUnit(unitID, 45, {2}, {""})
			fightingBombers[unitID] = true
		else
			GiveOrderToUnit(unitID, 45, {0}, {""})
			reservedBombers[unitID] = true
		end
	end
end

function checkBombers()
	for unitID, _ in pairs(fightingBombers) do
	-- clean dead or captured bombers
		if (not Spring.ValidUnitID(unitID) or Spring.GetUnitTeam(unitID) ~= myTeamID) then
			fightingBombers[unitID] = nil
		else
		-- swap bombers whose commands have changed and update their firestate
			local cmd = GetFirstCommand(unitID)
			if cmd and (cmd.id == 16 or cmd.id == 15) then
				-- do nothing
			else
				GiveOrderToUnit(unitID, 45, {0}, {""})
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
			if cmd and (cmd.id == 16 or cmd.id == 15) then
				GiveOrderToUnit(unitID, 45, {2}, {""})
				fightingBombers[unitID] = true
				reservedBombers[unitID] = nil
			else
				-- do nothing
			end
		end
	end
end

--------------------------------------------------------------------------------
