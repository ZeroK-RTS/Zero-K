
-- widgetHandler/gadgetHandler are nil at the point engine_compat.lua is loaded.


if true then -- No engine has this yet
	local origAddUnitDamage = Spring.AddUnitDamage
	function Spring.AddUnitDamageByTeam(unitID, damage, paralyze, attackerID, weaponID, teamID)
		gadgetHandler.GG._AddUnitDamage_teamID = teamID
		origAddUnitDamage(unitID, damage, paralyze, attackerID, weaponID)
		gadgetHandler.GG._AddUnitDamage_teamID = nil -- TODO: deal with recursion by saving old value. But this needs testing.
	end
end

-- Spring.RequestPath causes desync https://github.com/beyond-all-reason/RecoilEngine/issues/2434
if true or Script.IsEngineMinVersion(2025, 1, 0) and Spring.GetModOptions().luapathrequest ~= "1" then
	if widgetHandler then
		widgetHandler.WG.Disable_RequestPath = true
	end
	if gadgetHandler then
		gadgetHandler.GG.Disable_RequestPath = true
	end
	function Spring.RequestPath()
		return false
	end
end
