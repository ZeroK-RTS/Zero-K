--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Hacky version fix",
		desc      = "Fixes missing Game.version for missions, sigh.",
		author    = "GoogleFrog",
		date      = "12 April, 2017",
		license   = "GNU GPL, v2 or later",
		layer     = -math.huge,
		enabled   = true, --  loaded by default?
		api       = true,
		alwaysStart = true,
	}
	end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Game.version = Engine and Engine.version or Game.version -- See mission_night.lua

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
