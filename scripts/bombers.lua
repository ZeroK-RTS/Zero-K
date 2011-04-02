-- scripts common to bombers
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

	-- workaround for STOP not clearing attack order
	local firestate = Spring.GetUnitStates(unitID).firestate
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {})
	Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, {})
	for i=start,#queue do
		local cmd = queue[i]
		local cmdOpt = cmd.options
		local opts = {}	--{"shift"} -- appending
		if i > start then opts = {"shift"} end
		if (cmdOpt.alt)   then opts[#opts+1] = "alt"   end
		if (cmdOpt.ctrl)  then opts[#opts+1] = "ctrl"  end
		if (cmdOpt.right) then opts[#opts+1] = "right" end
		Spring.GiveOrderToUnit(unitID, cmd.id, cmd.params, opts)
	end
	
	if re and start == 2 then
		spGiveOrderToUnit(unitID, id, params, {"shift"} )
	end
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, {})
end

local function ReinsertAttackOrder(cmd, param)
	local queue = Spring.GetUnitCommands(unitID) or {}
	local index = #queue + 1
	for i=1, #queue do
		if queue[i].id == CMD_REARM then	-- already have manually set rearm point, we have nothing left to do here
			index = i
		end
	end
	spGiveOrderToUnit(unitID, CMD.INSERT, {index, cmd, 0, unpack(param)}, {"alt"})
end

function Reload()
	local queue = Spring.GetUnitCommands(unitID)
	local id, target
	if queue then
		local tag = queue[1].tag
		id = queue[1].id
		if id == CMD.AREA_ATTACK then
			target = queue[1].params
		elseif id == CMD.ATTACK and #(queue[1].params) == 1 then
			target = {queue[1].params[1]}
		end
		ReloadQueue(queue, tag, id)
	end
	Spring.SetUnitRulesParam(unitID, "noammo", 1)
	GG.RequestRearm(unitID)
	if target then
		ReinsertAttackOrder(id, target)
	end
end