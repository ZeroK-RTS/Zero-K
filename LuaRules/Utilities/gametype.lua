local teamCount
local is1v1, isTeams, isBigTeams, isSmallTeams, isChickens, isCoop, isFFA, isTeamFFA, isSandbox, isPlanetWars, isSoloTeams = false, false, false, false, false, false, false, false, false, false, false
do
	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID(), false))
	local allyTeamList = Spring.GetAllyTeamList()
	local actualAllyTeamList = {}
	local allyTeamsWithHumans = {}
	
	isSoloTeams = true
	for i = 1, #allyTeamList do
		local teamList = Spring.GetTeamList(allyTeamList[i]) or {}
		if ((#teamList > 0) and (allyTeamList[i] ~= gaiaAllyTeamID)) then
			local isTeamValid = true
			local humanExists = false
			for j = 1, #teamList do
				if not select (4, Spring.GetTeamInfo(teamList[j], false)) then
					humanExists = true
				end
				local luaAI = Spring.GetTeamLuaAI(teamList[j])
				if luaAI and luaAI:find("Chicken") then
					isChickens = true
					isTeamValid = false
				end
			end
			if isTeamValid then
				actualAllyTeamList[#actualAllyTeamList+1] = allyTeamList[i]
			end
			if humanExists then
				allyTeamsWithHumans[#allyTeamsWithHumans + 1] = allyTeamList[i]
			end
			if #teamList > 1 then
				isSoloTeams = false
			end
		end
	end
	teamCount = #actualAllyTeamList

	if teamCount > 2 then
		isFFA = true
		for i = 1, teamCount do
			if #Spring.GetTeamList(actualAllyTeamList[i]) > 1 then
				isTeamFFA = true
				break
			end
		end
		isChickens = false
	elseif teamCount < 2 then
		isSandbox = not isChickens
	else
		isChickens = false
		local cnt1 = #Spring.GetTeamList(actualAllyTeamList[1])
		local cnt2 = #Spring.GetTeamList(actualAllyTeamList[2])
		if cnt1 == 1 and cnt2 == 1 then
			is1v1 = true
		else
			isTeams = true
			if cnt1 <= 4 and cnt2 <= 4 then
				isSmallTeams = true
			else
				isBigTeams = true
			end
		end
	end

	if #allyTeamsWithHumans == 1 then
		isCoop = true
	end

	if Spring.GetModOptions().planet then
		isPlanetWars = true
	end
end

function Spring.Utilities.GetTeamCount()
	return teamCount
end

Spring.Utilities.Gametype = {
	is1v1        = function () return is1v1        end,
	isTeams      = function () return isTeams      end,
	isBigTeams   = function () return isBigTeams   end,
	isSmallTeams = function () return isSmallTeams end,
	isChickens   = function () return isChickens   end,
	isCoop       = function () return isCoop       end,
	isTeamFFA    = function () return isTeamFFA    end,
	isFFA        = function () return isFFA        end,
	isSandbox    = function () return isSandbox    end,
	isPlanetWars = function () return isPlanetWars end,
	isSoloTeams  = function () return isSoloTeams  end,
	IsSinglePlayer = function () return isSoloTeams or isSandbox end,
}
