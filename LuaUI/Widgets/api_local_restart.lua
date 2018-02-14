--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Local Restart Handler",
		desc      = "Handles local singleplayer and coop game restarting",
		author    = "GoogleFrog",
		date      = "14 February 2018",
		license   = "GPL-v2",
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local RESTART_STRING = "restart_game"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local externalFunctions = {}

function externalFunctions.CheckAllowed()
	-- Only allow restarting for local games or by the host of steam coop.
	local myPing = select(6, Spring.GetPlayerInfo(Spring.GetMyPlayerID()))
	return (not myPing) or (myPing > 40)
end

function externalFunctions.DoRestart()
	if not externalFunctions.CheckAllowed() then
		return
	end
	Spring.SendLuaMenuMsg(RESTART_STRING)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize() 
	if Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName() then
		WG.LocalRestart = externalFunctions
	end
end
