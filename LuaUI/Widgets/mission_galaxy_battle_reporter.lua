--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Galaxy Battle Reporter",
		desc      = "Reports outcome of galaxy battle.",
		author    = "GoogleFrog",
		date      = "7 February 2016",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
		api       = true,
		alwaysStart = true,
		hidden    = true,
	}
end

local campaignBattleID = Spring.GetModOptions().singleplayercampaignbattleid
if not campaignBattleID then
	return
end

-- Anyone could write a widget to send this message. However, they would only be
-- cheating themselves.
local WIN_MESSAGE = "Campaign_PlanetBattleWon"
local myAllyTeamID = Spring.GetMyAllyTeamID()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SendVictoryToLuaMenu(planetID)
	local luaMenu = Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()
	if luaMenu then
		Spring.SendLuaMenuMsg(WIN_MESSAGE .. planetID)
	end
end

function widget:GameOver(winners)
	for i = 1, #winners do
		if winners[i] == myAllyTeamID then
			SendVictoryToLuaMenu(campaignBattleID)
		end
	end
end
