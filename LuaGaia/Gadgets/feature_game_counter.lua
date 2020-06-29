--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Feature Creation Counter",
		desc      = "Counts the features that exist before LuaGaia creates them.",
		author    = "GoogleFrog",
		date      = "6 April 2020",
		license   = "GNU GPL, v2 or later",
		layer     = -10000000000,
		enabled   = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GamePreload()
	GG.game_count_features_preload = #(Spring.GetAllFeatures() or {})
	gadgetHandler:RemoveGadget()
end
