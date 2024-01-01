function widget:GetInfo() return {
	name    = "decoy test",
	layer   = 0,
	enabled = true,
} end

function widget:GameFrame(n)
	if n == 31 then
		local units = Spring.GetTeamUnitsByDefs(1, {UnitDefNames.cloakraid.id})
		Spring.Echo("returned units:")
		for i = 1, #units do
			Spring.Echo(i, units[i])
		end
	end
end
