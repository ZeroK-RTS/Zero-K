local teamCount
do
	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID()))
	local allyTeamList = Spring.GetAllyTeamList()
	local actualAllyTeamList = {}
	for i = 1, #allyTeamList do
		local teamList = Spring.GetTeamList(allyTeamList[i]) or {}
		if ((#teamList > 0) and (allyTeamList[i] ~= gaiaAllyTeamID)) then
			local isTeamValid = true
			for j = 1, #teamList do
				local luaAI = Spring.GetTeamLuaAI(teamList[j])
				if luaAI and luaAI:find("Chicken") then
					isTeamValid = false
				end
			end
			if isTeamValid then
				actualAllyTeamList[#actualAllyTeamList+1] = allyTeamList[i]
			end
		end
	end
	teamCount = #actualAllyTeamList
end

function Spring.Utilities.GetTeamCount()
	return teamCount
end
