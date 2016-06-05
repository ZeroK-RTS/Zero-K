--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Mission Results Handler",
		desc      = "What it says on the tin",
		author    = "KingRaptor (L.J. Lim)",
		date      = "2013.10.29",
		license   = "Public domain/CC0",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not VFS.FileExists("mission.lua") then
	return
end

local missionVars = {}
local varsWritten = false

function widget:GameOver(winners)
	local result = "defeat"
	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID()))
	if #winners > 1 then
		if Spring.GetSpectatingState() then
			result = "draw"
		else
			for i = 1, #winners do
				if (winners[i] == Spring.GetMyAllyTeamID()) then
					result = "victory"
					break
				end
			end
		end
	elseif #winners == 1 then
		if (winners[1] == Spring.GetMyAllyTeamID()) then
			result = "victory"
		end
	elseif #winners == 0 then
		result = "draw"
	end
	missionVars.result = result
	WG.SavePythonDict("cache/", "mission_results.json", missionVars, "", {json = true, endOfFile = true})
	varsWritten = true
end

function widget:Initialize()
	WG.missionVars = missionVars
end

function widget:Shutdown()
	if not varsWritten then
		widget:GameOver({})
	end
	WG.missionVars = nil
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------