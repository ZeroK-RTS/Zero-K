function widget:GetInfo() return {
	name      = "Spawn order test",
	layer     = 0,
	enabled   = true,
} end

function widget:GameFrame (n)
	if n % 300 ~= 0 then
		return
	end
	Spring.Echo("frame", n)

	Spring.Echo("units0")
	local units0 = Spring.GetTeamUnitsByDefs(0, {UnitDefNames.energysolar.id, UnitDefNames.energywind.id, UnitDefNames.staticmex.id})
	for i = 1, #units0 do
		local unitID = units0[i]
		Spring.Echo(i, unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitRulesParam(unitID, "spawn_order"))
	end

	Spring.Echo("units1")
	local units1 = Spring.GetTeamUnitsByDefs(1, {UnitDefNames.energysolar.id, UnitDefNames.energywind.id, UnitDefNames.staticmex.id})
	for i = 1, #units1 do
		local unitID = units1[i]
		Spring.Echo(i, unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitRulesParam(unitID, "spawn_order"))
	end
end
