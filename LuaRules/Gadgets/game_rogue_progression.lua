--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modOptions = Spring.GetModOptions() or {}

function gadget:GetInfo()
	return {
		name      = "Rogue-K Progression",
		desc      = "Progression handler for Rogue-K. Implements post-game unlocks and selecting next mission.",
		author    = "GoogleFrog",
		date      = "8 January 2026",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = tonumber(modOptions.rogue_enabled or 0) == 1,
	}
end

