-- scripts common to bombers

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
		Spring.GiveOrderToUnit(unitID, CMD.ATTACK, {storeParams[1],Spring.GetGroundHeight(storeParams[1],storeParams[3]),storeParams[3]}, {"shift"} )
	end	
end

function Reload()
	local queue = Spring.GetUnitCommands(unitID)
	if queue then
		local tag = queue[1].tag
		ReloadQueue(queue, tag)
	end	
	Spring.SetUnitRulesParam(unitID, "noammo", 1)
	GG.RequestRearm(unitID)
end