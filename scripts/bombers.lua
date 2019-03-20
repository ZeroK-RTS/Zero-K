-- TODO: CACHE INCLUDE FILE
-- scripts common to bombers
VFS.Include("LuaRules/Configs/customcmds.h.lua")
-- local CMD_REARM = 33410 --get from customcmds.h.lua
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetUnitMoveTypeData = Spring.GetUnitMoveTypeData

-- old crappy way
--[[
local function ReloadQueue(queue, cmdTag)
	if (not queue) then
		return
	end
	local re = Spring.GetUnitStates(unitID)["repeat"]
	local storeParams
 --// remove finished command
	local start = 1
	if (queue[1])and(cmdTag == queue[1].tag) then
		start = 2 
		 if re then
			storeParams = queue[1].params
		end
	end

	-- workaround for STOP not clearing attack order due to auto-attack
	-- we set it to hold fire temporarily, revert once commands have been reset
	local firestate = Spring.GetUnitStates(unitID).firestate
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, 0)
	Spring.GiveOrderToUnit(unitID, CMD.STOP, emptyTable, 0)
	for i=start,#queue do
		local cmd = queue[i]
		local cmdOpt = cmd.options
		Spring.GiveOrderToUnit(unitID, cmd.id, cmd.params, cmdOpt.coded + (cmdOpt.shift and 0 or CMD.OPT_SHIFT))
	end
	
	if re and start == 2 then
		local cmd = queue[1]
		spGiveOrderToUnit(unitID, cmd.id, cmd.params, CMD.OPT_SHIFT)
	end
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, 0)
	
	return re
end
]]

-- much better!
local function ReloadQueue(queue, cmd)
	if (not queue) then
		return
	end
	local re = Spring.GetUnitStates(unitID)["repeat"]

	-- workaround for RemoveCommand not clearing attack order due to auto-attack
	-- we set it to hold fire temporarily, revert once commands have been reset
	local firestate = Spring.GetUnitStates(unitID).firestate
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, 0)
	Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {cmd.tag}, 0)
	
	if re then
		spGiveOrderToUnit(unitID, cmd.id, cmd.params, CMD.OPT_SHIFT)
	end
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, 0)
	
	return re
end

function Reload()
	local queue = Spring.GetCommandQueue(unitID, 1)
	local cmdID, areaAttack
	local re = false
	if queue and queue[1] then
		local cmd = queue[1]
		cmdID = cmd.id
		if cmdID == CMD.AREA_ATTACK then
			areaAttack = cmd.params
		end
		if cmdID == CMD.AREA_ATTACK or cmdID == CMD.ATTACK then
			re = ReloadQueue(queue, cmd)
		end
	end
	Spring.SetUnitRulesParam(unitID, "noammo", 1)
	local targetPad, index = GG.RequestRearm(unitID)
	if areaAttack and index and not re then
		GG.InsertCommand(unitID, index, cmdID, areaAttack)
	end
end

function RearmBlockShot()
	local ammoState = Spring.GetUnitRulesParam(unitID, "noammo")
	return (ammoState == 1) or (ammoState == 2) or (ammoState == 3)
end

function SetInitialBomberSettings()
	local aircraftState = (spGetUnitMoveTypeData(unitID) or {}).aircraftState
	if aircraftState then
		Spring.MoveCtrl.SetAirMoveTypeData(unitID, {maneuverBlockTime = 0})
	end
end

function SetUnarmedAI()
	-- Make bombers think they have much smaller turn radius to make them more responsive.
	-- This is not applied to armed AI because it can cause infinite circling while trying
	-- to line up a bombing run.
	local aircraftState = (spGetUnitMoveTypeData(unitID) or {}).aircraftState
	if aircraftState then
		Spring.MoveCtrl.SetAirMoveTypeData(unitID, {turnRadius = 10})
	end
end

local defaultTurnRadius = UnitDefs[unitDefID].turnRadius 
function SetArmedAI()
	local aircraftState = (spGetUnitMoveTypeData(unitID) or {}).aircraftState
	if aircraftState then
		Spring.MoveCtrl.SetAirMoveTypeData(unitID, {turnRadius = defaultTurnRadius})
	end
end
