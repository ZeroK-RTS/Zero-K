--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Disable /take",
    desc      = "Disable /take of AI's unit or inactive team's unit unless /cheat is enabled", 
    author    = "xponen",
    date      = "21 January 2015",
    license   = "ZK's default license",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

local spIsCheatingEnabled = Spring.IsCheatingEnabled
local spGetPlayerInfo     = Spring.GetPlayerInfo
local spGetTeamInfo       = Spring.GetTeamInfo

GG.allowTransfer = false
function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
	--NOTE: this gadget don't block unit transfer to enemy (which is an Engine setting).
	if capture or GG.allowTransfer or spIsCheatingEnabled() then --ALLOW transfer when capturing unit, or when superuser asked it, or when gadget requested it
		return true 
	end
	local _,leaderID,isDead,isAI = spGetTeamInfo(oldTeam)
	if isAI or isDead then --DISALLOW /take of AI or dead player
		return false
	end
	local _, active, spectator = spGetPlayerInfo(leaderID)
	if (spectator or not active) then --DISALLOW /take of resigned or afk player
		return false
	end
	return true --ALLOW transfer for all other case (eg: player to player)
end
