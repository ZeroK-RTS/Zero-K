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
    name      = "Unit Mover",
    desc      = "Allows combat engineers to use repeat when building mobile units (use 2 or more build spots)",
    author    = "TheFatController",
    date      = "Mar 20, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 11,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------

local Echo = Spring.Echo
local spGetSpectatingState = Spring.GetSpectatingState
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDirection = Spring.GetUnitDirection
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetCommandQueue = Spring.GetCommandQueue
local spGetMyTeamID = Spring.GetMyTeamID
local CMD_MOVE = CMD.MOVE
local currentFrame = 15
local myUnits = {}

--------------------------------------------------------------------------------


local myTeamID = spGetMyTeamID()

function widget:PlayerChanged(playerID)
	if spGetSpectatingState() then -- remove widget if the player switches to spec
		widgetHandler:RemoveWidget()
	end
end

function widget:Initialize()
	if spGetSpectatingState() then
		widgetHandler:RemoveWidget()
	end
end

function widget:GameFrame(thisFrame)
	for unitID, frame in pairs(myUnits) do
		if thisFrame >= frame then
			local cmd = GetFirstCommand(unitID)
			if not cmd then -- if the unit already has a command, we should leave it alone
				local dx,_,dz = spGetUnitDirection(unitID)
				local x,y,z = spGetUnitPosition(unitID)
				-- convert dimensionless direction into a distance of 400 elmos, then add it to the location to get the destination
				dx = dx*400
				dz = dz*400
				spGiveOrderToUnit(unitID, CMD_MOVE, {x+dx, y, z+dz}, {""})
			end
			myUnits[unitID] = nil
		end
	end
	currentFrame = thisFrame
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if unitTeam == myTeamID then
		local unitDef = UnitDefs[unitDefID]
		if unitDef.canMove and unitDef.cost < 600 then -- only target mobile units that aren't commanders
			myUnits[unitID] = currentFrame + 5 -- wait 5 frames before checking the unit to see if it has a command
		end
	end
end

--	Borrowed this from CarRepairer's Retreat.  Returns only first command in queue.
function GetFirstCommand(unitID)
	local queue = spGetCommandQueue(unitID, 1)
	return queue[1]
end

--------------------------------------------------------------------------------
