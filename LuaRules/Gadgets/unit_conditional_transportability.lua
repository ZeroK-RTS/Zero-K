function gadget:GetInfo() return {
	name    = "Conditional Transportability",
	desc    = "Allows units to only be transportable in some situations.",
	author  = "sprung",
	date    = "15-05-15",
	license = "PD",
	layer   = 0,
	enabled = false,
} end

if (gadgetHandler:IsSyncedCode()) then

	-- transports and potentially untransportable units
	local untransportable_defs = {
		[UnitDefNames.armtboat.id] = true, -- Surfboard
		[UnitDefNames.corbtrans.id] = true, -- Vindicator
		[UnitDefNames.corvalk.id] = true, -- Valkyrie
	}

	-- holds potentially untransportable units to notify transports to drop orders
	-- bidirectional, because load orders also come in two variants (load and get loaded)
	local potential_units = {}

	function gadget:AllowCommand (unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
		local numParams = #cmdParams

		if (cmdID == CMD.INSERT and cmdParams[2]) then
			cmdID = cmdParams[2]
			cmdParams[1] = cmdParams[4]
			numParams = numParams - 3
		end

		if (cmdID == CMD.LOAD_ONTO)
		and untransportable_defs[unitDefID] then
			if (Spring.GetUnitRulesParam(unitID, "untransportable") == 1) then
				return false
			else
				local transporter = cmdParams[1]
				potential_units[unitID][transporter] = true
				potential_units[transporter][unitID] = true
				return true
			end
		end

		local transportiee = cmdParams[1]

		if  (cmdID == CMD.LOAD_UNITS)
		and (numParams == 1) -- only block single-target load (not area load)
		and untransportable_defs[Spring.GetUnitDefID(transportiee)] then
			if (Spring.GetUnitRulesParam(transportiee, "untransportable") == 1) then
				return false
			else
				potential_units[transportiee][unitID] = true
				potential_units[unitID][transportiee] = true
				return true
			end
		end

		return true
	end

	function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
		Spring.SetUnitRulesParam(transportID, "untransportable", 1)

		-- purge any load orders regarding the newly untransportable unit
		for transporter in pairs(potential_units[transportID]) do
			local commandQ = Spring.GetCommandQueue(transporter)
			local purgeList = {}
			for j = 1, #commandQ do
				local command = commandQ[j]
				if (command.id == CMD.LOAD_UNITS) and (command.params[1] == transportID) and (not command.params[2]) then
					purgeList[#purgeList+1] = command.tag
				end
			end
			Spring.GiveOrderToUnit (transporter, CMD.REMOVE, purgeList, 0)
		end
		potential_units[transportID] = {}

		-- purge own queue of embark orders
		local commandQ = Spring.GetCommandQueue(transportID)
		local purgeList = {}
		for j = 1, #commandQ do
			local command = commandQ[j]
			if (command.id == CMD.LOAD_ONTO) then
				purgeList[#purgeList+1] = command.tag
			end
		end
		Spring.GiveOrderToUnit (transportID, CMD.REMOVE, purgeList, 0)
	end

	function gadget:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
		Spring.SetUnitRulesParam(transportID, "untransportable", 0)
	end

	function gadget:UnitCreated(unitID, unitDefID)
		if untransportable_defs[unitDefID] then
			potential_units[unitID] = {}
		end
	end

	function gadget:UnitDestroyed(unitID)
		if potential_units[unitID] then
			for id in pairs(potential_units[unitID]) do
				potential_units[id][unitID] = nil
			end
			potential_units[unitID] = nil
		end
	end

else -- unsynced

	function gadget:DefaultCommand (targetType, targetID)
		if (targetType == "unit") and Spring.IsUnitAllied(targetID) and (Spring.GetUnitRulesParam(targetID, "untransportable") == 1) then
			return CMD.GUARD
		end
	end

end

--[[ Version for the future engine

	function gadget:AllowTransport(unitID, transportID)
		return (Spring.GetUnitRulesParam(unitID, "untransportable") ~= 1)
	end

	function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID)
		Spring.SetUnitRulesParam(transportID, "untransportable", 1)
	end

	function gadget:UnitUnloaded(unitID, unitDefID, unitTeam, transportID)
		Spring.SetUnitRulesParam(transportID, "untransportable", 0)
	end
]]
