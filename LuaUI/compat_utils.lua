local oldIsPosInLos = Spring.IsPosInLos
local oldIsPosInRadar = Spring.IsPosInRadar
local oldIsPosInAirLos = Spring.IsPosInAirLos
local oldGetPositionLosState = Spring.GetPositionLosState


Spring.IsPosInLos = function (x, y, z, allyTeamID)
	return oldIsPosInLos(x, y, z, allyTeamID or Spring.GetMyAllyTeamID())
end

Spring.IsPosInRadar = function (x, y, z, allyTeamID)
	return oldIsPosInRadar(x, y, z, allyTeamID or Spring.GetMyAllyTeamID())
end

Spring.IsPosInAirLos = function (x, y, z, allyTeamID)
	return oldIsPosInAirLos(x, y, z, allyTeamID or Spring.GetMyAllyTeamID())
end

Spring.GetPositionLosState = function (x, y, z, allyTeamID)
	return oldGetPositionLosState(x, y, z, allyTeamID or Spring.GetMyAllyTeamID())
end