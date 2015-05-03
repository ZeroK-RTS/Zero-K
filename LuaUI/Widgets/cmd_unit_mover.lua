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
local spGetMyTeamID = Spring.GetMyTeamID
local CMD_MOVE = CMD.MOVE

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

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if unitTeam == myTeamID then
		local unitDef = UnitDefs[unitDefID]
		if unitDef.canMove then
			local dx,_,dz = spGetUnitDirection(unitID)
			local x,y,z = spGetUnitPosition(unitID)
			-- convert dimensionless direction into a distance of 200 elmos, then add it to the location to get the destination
			dx = dx*200
			dz = dz*200
			spGiveOrderToUnit(unitID, CMD_MOVE, {x+dx, y, z+dz}, {""})
		end
	end
end

--------------------------------------------------------------------------------
