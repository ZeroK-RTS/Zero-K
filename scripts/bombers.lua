-- scripts common to bombers
VFS.Include("LuaRules/Configs/customcmds.h.lua")
-- local CMD_REARM = 33410 --get from customcmds.h.lua
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local emptyTable = {}

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
		local opts = {"shift"} -- appending
		if (cmdOpt.alt)   then opts[#opts+1] = "alt"   end
		if (cmdOpt.ctrl)  then opts[#opts+1] = "ctrl"  end
		if (cmdOpt.right) then opts[#opts+1] = "right" end
		Spring.GiveOrderToUnit(unitID, cmd.id, cmd.params, opts)
	end
	
	if re and start == 2 then
		local cmd = queue[1]
		spGiveOrderToUnit(unitID, cmd.id, cmd.params, {"shift"} )
	end
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, 0)
	
	return re
end

function Reload()
	local queue = Spring.GetUnitCommands(unitID)
	local cmdID, target
	local re = false
	if queue and queue[1] then
		local tag = queue[1].tag
		cmdID = queue[1].id
		if cmdID == CMD.AREA_ATTACK then
			target = queue[1].params
		elseif cmdID == CMD.ATTACK and #(queue[1].params) == 1 then
			--target = {queue[1].params[1]}
		end
		re = ReloadQueue(queue, tag)
	end
	Spring.SetUnitRulesParam(unitID, "noammo", 1)
	local targetPad, index = GG.RequestRearm(unitID)
	if target and index and not re then
		GG.InsertCommand(unitID, index, cmdID, target)
	end
end