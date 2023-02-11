--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Player Anonymiser API",
		desc      = "Checks modoptions and exposes functions for hinding identifiable player states.",
		author    = "GoogleFrog",
		date      = "11 Feb 2023",
		license   = "GNU GPL, v2 or later",
		layer     = -1,
		enabled   = true,
	}
end

-- TODO: Implement modoption and epicmenu opt-out toggle.

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local BLA_MODE = true
local spGetPlayerInfo = Spring.GetPlayerInfo
local myPlayerID = Spring.GetMyPlayerID()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local anonEnabled = false -- some modoption, modified by an epicmenu option

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function WG.IsPlayerAnon(playerID)
	if not anonEnabled then
		return false
	end
	return not Spring.Utilities.PlayerCanSeeOtherPlayerThroughAnon(myPlayerID, playerID)
end

function WG.GetPlayerName(playerID)
	if BLA_MODE then
		return "bla"
	end
	if WG.IsPlayerAnon(playerID) then
		return Spring.Utilities.GetAnonName(playerID)
	end
	local playerName = spGetPlayerInfo(playerID)
	return playerName
end

function WG.GetPlayerElo(playerID)
	if WG.IsPlayerAnon(playerID) then
		return 1500
	end
	return tonumber(select(10, Spring.GetPlayerInfo(playerID)).elo)
end

function WG.PlayerNameToAnonName(rawName)
	if BLA_MODE then
		return "bla"
	end
	if WG.IsPlayerAnon(playerID) then
		-- playerID = output of cached lookup table (take new specs into account too)
		-- return Spring.Utilities.GetAnonName(playerID), otherwise rawName
		return rawName
	end
	return rawName
end

function WG.PingToAnonPing(playerID, ping)
	-- Detect disconnect, but not geography.
	if WG.IsPlayerAnon(playerID) and ping < 1000 then
		return 200
	end
	return ping
end
