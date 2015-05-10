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
local spGetUnitDefID = Spring.GetUnitDefID
local spGetMyTeamID = Spring.GetMyTeamID
local CMD_MOVE = CMD.MOVE

--------------------------------------------------------------------------------

-- rewritten by aeonios
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

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if unitTeam == myTeamID and builderID then -- commanders spawn with nil builderID
		local unitDef = UnitDefs[unitDefID]
		local builderDefID = spGetUnitDefID(builderID)
		local builderDef = UnitDefs[builderDefID]
		if (string.match(unitDef.humanName, "Athena")
		or string.match(builderDef.humanName, "Athena")
		or string.match(builderDef.humanName, "Strider"))
		and unitDef.canMove then
			Echo("Unit mover gave a move order!")
			local dx,_,dz = spGetUnitDirection(unitID)
			local x,y,z = spGetUnitPosition(unitID)
			-- convert dimensionless direction into a distance of 400 elmos, then add it to the location to get the destination
			dx = dx*400
			dz = dz*400
			spGiveOrderToUnit(unitID, CMD_MOVE, {x+dx, y, z+dz}, {""})
		end
	end
end
--------------------------------------------------------------------------------
