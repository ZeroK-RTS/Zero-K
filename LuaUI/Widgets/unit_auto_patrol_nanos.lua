-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_immobile_buider.lua
--  brief:   sets immobile builders to ROAMING, and gives them a PATROL order
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Auto Patrol Nanos",
    desc      = "Sets nano towers to ROAM, with a PATROL command",
    author    = "trepan",
    date      = "Jan 8, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = -2,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Speeups

local CMD_MOVE_STATE    = CMD.MOVE_STATE
local CMD_PATROL        = CMD.PATROL
local CMD_STOP          = CMD.STOP
local spGetGameFrame    = Spring.GetGameFrame
local spGetMyTeamID     = Spring.GetMyTeamID
local spGetTeamUnits    = Spring.GetTeamUnits
local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
local spGetUnitDefID    = Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetGameRulesParam = Spring.GetGameRulesParam

local abs = math.abs

local mapCenterX = Game.mapSizeX / 2
local mapCenterZ = Game.mapSizeZ / 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

local stoppedUnit = {}
local enableIdleNanos = true
local stopHalts = true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Functions

VFS.Include("LuaRules/Utilities/ClampPosition.lua")
local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit

local function IsImmobileBuilder(ud)
	return(ud and ud.isBuilder and not ud.canMove and not ud.isFactory)
end

local function SetupUnit(unitID)
	-- set immobile builders (nanotowers?) to the ROAM movestate,
	-- and give them a PATROL order (does not matter where, afaict)
	local cmdID = spGetUnitCurrentCommand(unitID)
	if cmdID and cmdID ~= CMD_PATROL then
		return
	end
	
	local x, y, z = spGetUnitPosition(unitID)
	if (x) then
		-- point patrol towards map center
		vx = mapCenterX - x
		vz = mapCenterZ - z
		x = x + vx*25/abs(vx)
		z = z + vz*25/abs(vz)

		GiveClampedOrderToUnit(unitID, CMD_PATROL, { x, y, z }, {})
	end
end

local function SetupAll()
	for _,unitID in ipairs(spGetTeamUnits(spGetMyTeamID())) do
		local unitDefID = spGetUnitDefID(unitID)
		if (IsImmobileBuilder(UnitDefs[unitDefID])) then
			SetupUnit(unitID)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Settings

options_path = 'Settings/Unit Behaviour'
options = {
	patrol_idle_nanos = {
		name = "Caretaker automation",
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'Caretakers will automatically find tasks when idle. They may assist, repair or reclaim. Also applies to Strider Hub.',
		OnChange = function (self)
			enableIdleNanos = self.value
			if self.value then
				SetupAll()
			end
		end,
	},
	stop_disables = {
		name = "Disable caretakers with stop",
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'Caretakers automation is put on hold with the Stop command. Automation resumes after any other command. Also applies to Strider Hub.',
		OnChange = function (self)
			stopHalts = self.value
			if not self.value then
				stoppedUnit = {}
				SetupAll()
			end
		end,
	}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

function widget:Initialize()
	SetupAll()
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if not enableIdleNanos
	or unitTeam ~= spGetMyTeamID()
	or not IsImmobileBuilder(UnitDefs[unitDefID])
	or spGetGameRulesParam("loadPurge") == 1
	then
		return
	end

	SetupUnit(unitID)
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions) 
	if not IsImmobileBuilder(UnitDefs[unitDefID]) then
		return
	end
	if cmdID == CMD_PATROL and (not cmdOptions.shift) then
		local x, y, z = spGetUnitPosition(unitID)
		if math.abs(x - cmdParams[1]) > 30 or math.abs(z - cmdParams[3]) > 30 then
			SetupUnit(unitID)
		end
	end
	if stopHalts then
		if cmdID == CMD_STOP then
			stoppedUnit[unitID] = true
		elseif stoppedUnit[unitID] then
			stoppedUnit[unitID] = nil
		end
	end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
	widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitIdle(unitID, unitDefID, unitTeam)
	if not enableIdleNanos
	or stoppedUnit[unitID]
	or unitTeam ~= spGetMyTeamID()
	or not IsImmobileBuilder(UnitDefs[unitDefID])
	or spGetGameRulesParam("loadPurge") == 1
	then
		return
	end

	SetupUnit(unitID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
