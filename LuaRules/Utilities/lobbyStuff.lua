local xpTable = {5, 10, 20, 35, 50, 75, 100}
function Spring.Utilities.TranslateLobbyRank(elo, xp)
	if not elo or type(elo) ~= "number" then
		elo = 0
	end
	if not xp or type(xp) ~= "number" then
		xp = 0
	end

	elo = math.max(0, math.min(7, math.floor(
		(elo / 200) - 5
	)))
	local retXP = 0
	for i = 1, #xpTable do
		if xp >= xpTable[i] then
			retXP = i
		end
	end
	return elo, retXP
end
