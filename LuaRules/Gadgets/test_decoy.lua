if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name    = "decoy test",
	layer   = 0,
	enabled = true,
} end

function gadget:GameFrame(n)
	if n == 2 then
		Spring.CreateUnit("staticradar", 500, 999, 500, 0, 0) -- make sure the spawned stuff is visible
		for i = 1, 5 do
			local id1 = Spring.CreateUnit("cloakraid", 1, 0, 1, 0, 1)
			local id2 = Spring.CreateUnit("shieldraid", 1, 0, 1, 0, 1)
			Spring.Echo(id1, "is REAL")
			Spring.Echo(id2, "is DECOY")
		end
	end
end
