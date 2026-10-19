-- This file is part of Zero-K (GPL v2 or later), see LICENSE.
function widget:GetInfo()
	return { name = "Portal save regression", layer = 10000, enabled = true }
end
if Spring.GetModOptions().zk_duels_save ~= "1" then
	return false
end
local options = Spring.GetModOptions()
local baseline = not options.zk_duels or options.zk_duels == "baseline"
local loaded = Spring.GetConfigInt("PortalFixtureReloaded", 0) == 1
local requested, quitAt
function widget:Update()
	if loaded then
		if not requested and Spring.GetGameFrame() > 0 then
			requested = true
			Spring.SendCommands("pause 0")
		end
		if Spring.GetGameRulesParam("portal_save_loaded_done") ~= nil then
			Spring.SendCommands("quitforce")
		end
	elseif
		not requested
		and (
			Spring.GetGameRulesParam("portal_save_ready") == 1 or (baseline and Spring.GetGameFrame() >= 240)
		)
	then
		requested = true
		Spring.SendCommands("pause 1", "save portal-mechanics")
		quitAt = Spring.GetDrawSeconds() + 2
	elseif
		quitAt
		and Spring.GetDrawSeconds() > quitAt
		and VFS.FileExists("Saves/portal-mechanics.ssf", VFS.RAW_ONLY)
	then
		Spring.SendCommands("quitforce")
	end
end
