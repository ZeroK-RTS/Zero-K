-- scripts common to bombers
local CMD_REARM = 32768
local spGiveOrderToUnit = Spring.GiveOrderToUnit

local function ReloadQueue(queue, cmdTag, id)
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
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {})
	Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, {})
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
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, {})
	
	return re
end

local function ReinsertAttackOrder(cmd, param)
	local queue = Spring.GetUnitCommands(unitID) or {}
	local index = #queue + 1
	for i=1, #queue do
		if queue[i].id == CMD_REARM then
			index = i
			break
		end
	end
	--spGiveOrderToUnit(unitID, CMD.INSERT, {index, cmd, 0, unpack(param)}, {"alt"})
	GG.InsertCommand(unitID, index, cmd, param)
end

function Reload()
	local queue = Spring.GetUnitCommands(unitID) or {}
	local id, target
	local re = false
	if queue then
		local tag = queue[1].tag
		id = queue[1].id
		if id == CMD.AREA_ATTACK then
			target = queue[1].params
		elseif id == CMD.ATTACK and #(queue[1].params) == 1 then
			target = {queue[1].params[1]}
		end
		re = ReloadQueue(queue, tag, id)
	end
	Spring.SetUnitRulesParam(unitID, "noammo", 1)
	GG.RequestRearm(unitID)
	if target and not re then
		ReinsertAttackOrder(id, target)
	end
end