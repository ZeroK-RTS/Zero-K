if (not gadgetHandler:IsSyncedCode()) then return end

function gadget:GetInfo() return {
	name      = "ShareControl",
	desc      = "Controls sharing of units and resources",
	author    = "trepan (Dave Rodgers)",
	date      = "Apr 22, 2007",
	license   = "GNU GPL, v2 or later",
	layer     = -5,
	enabled   = true,
} end

local spAreTeamsAllied = Spring.AreTeamsAllied
local spIsCheatingEnabled = Spring.IsCheatingEnabled
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local gaiaTeamID = Spring.GetGaiaTeamID()
function gadget:AllowResourceTransfer(oldTeam, newTeam, resource_type, amount)
	if ((amount < 0) or (not spAreTeamsAllied(oldTeam, newTeam))) then
		return false
	end
	return true
end

function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
	if (capture
	or spAreTeamsAllied(oldTeam, newTeam)
	or spIsCheatingEnabled()
	or ((newTeam == gaiaTeamID) and (spGetUnitRulesParam(unitID, "can_share_to_gaia") == 1)) -- for Planet Wars
	) then
		return true
	end

	return false
end
