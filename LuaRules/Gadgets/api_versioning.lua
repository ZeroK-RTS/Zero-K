if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name     = "API versioning stuff for maps and user widgets",
		layer    = -math.huge, -- before map gadgetry does Initialize
		enabled  = true,
	}
end

function gadget:Initialize()
	-- see commit 60454838f895c2a7f9c52b52db52df03ec922257
	Spring.SetGameRulesParam("GetTeamInfoCustomKeysIndex", 7)
	Spring.SetGameRulesParam("GetPlayerInfoCustomKeysIndex", 10)

	Spring.SetGameRulesParam("GetGroundInfoNameIndex", 1)
	Spring.SetGameRulesParam("GetTerrainTypeDataNameIndex", 1)
end
