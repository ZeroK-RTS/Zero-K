
local PRIVATE_VISIBLE = {private = true}
local gaiaTeam = Spring.GetGaiaTeamID()

local function GetTeamString(teamID)
	return "hidden_" .. teamID .. "_"
end

function Spring.Utilities.SetHiddenTeamRulesParam(teamID, rulesParam, value)
	Spring.SetTeamRulesParam(gaiaTeam, GetTeamString(teamID) .. rulesParam, value, PRIVATE_VISIBLE)
end

function Spring.Utilities.GetHiddenTeamRulesParam(teamID, rulesParam)
	return Spring.GetTeamRulesParam(gaiaTeam, GetTeamString(teamID) .. rulesParam)
end
