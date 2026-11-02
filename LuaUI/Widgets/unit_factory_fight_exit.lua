function widget:GetInfo()
	return {
		name      = "Constructor Factory Exit",
		desc      = "New constructors move away from their factory before they start a factory Fight or Patrol order.",
		author    = "moss-orbit",
		date      = "2 November 2026",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
-- Epic Menu Options
--------------------------------------------------------------------------------

options_path = 'Settings/Unit Behaviour'
options = {
	leaveFactory = {
		name = "Constructors leave factory on Fight and Patrol",
		type = "bool",
		value = false,
		desc = "When the first factory order is Fight or Patrol, new constructors first move halfway to the target. Otherwise they stay to assist the factory.",
		noHotkey = true,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local CMD_RAW_MOVE = Spring.Utilities.CMD.RAW_MOVE
local CMD_FIGHT = CMD.FIGHT
local CMD_PATROL = CMD.PATROL
local CMD_OPT_SHIFT = CMD.OPT_SHIFT

local buildDistance = {}
for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	if ud.isMobileBuilder and ud.canAssist then
		buildDistance[unitDefID] = ud.buildDistance
	end
end

function widget:UnitFromFactory(unitID, unitDefID, unitTeam, factID)
	if not (options.leaveFactory.value and buildDistance[unitDefID]) then
		return
	end
	if unitTeam ~= Spring.GetMyTeamID() or Spring.GetSpectatingState() then
		return
	end
	-- Constructors on hold position do not assist factories.
	local moveState = Spring.Utilities.GetUnitMoveState(unitID)
	if not moveState or moveState == 0 then
		return
	end
	local queue = Spring.GetUnitCommands(factID, -1)
	local first = queue and queue[1]
	if not (first and (first.id == CMD_FIGHT or first.id == CMD_PATROL) and first.params[3]) then
		return
	end

	local fx, _, fz = Spring.GetUnitPosition(factID)
	local dx, dz = first.params[1] - fx, first.params[3] - fz
	local distance = math.sqrt(dx*dx + dz*dz)
	-- Fight looks for units to assist within 300*moveState + buildDistance
	-- (CBuilderCAI::ExecuteFight). The factory radius covers the nanoframe.
	local clearance = 300*moveState + buildDistance[unitDefID] + Spring.GetUnitRadius(factID)
	if distance <= clearance then
		-- The target is close enough that fighting there includes the factory.
		return
	end

	local scale = math.max(0.5, clearance/distance)
	local mx, mz = fx + dx*scale, fz + dz*scale
	-- Replace the copied factory orders, as the engine copies them, behind the move.
	local orders = {{CMD_RAW_MOVE, {mx, Spring.GetGroundHeight(mx, mz), mz}, 0}}
	for i = 1, #queue do
		orders[i + 1] = {queue[i].id, queue[i].params, math.bit_or(queue[i].options.coded, CMD_OPT_SHIFT)}
	end
	Spring.GiveOrderArrayToUnitArray({unitID}, orders)
end
