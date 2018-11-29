--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "GC Control",
		desc      = "Control lua GC rate.",
		author    = "GoogleFrog",
		date      = "8 November 2018",
		license   = "GNU GPL, v2 or later",
		layer     = math.huge,
		alwaysStart = true,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	-- See:
	-- https://springrts.com/mantis/view.php?id=5951
	-- https://github.com/spring/spring/commit/a8b5ffc86351680c6e0e8d7e8db161e63dbb912e
	-- https://github.com/spring/spring/commit/20c5c96c9ec4a7810346e0f20abdf1c3ae0f9513
	Spring.SendCommands({"luagccontrol 1"})
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
