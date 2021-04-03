local allspots = {
	-- river supermex
    {x = 360, z = 2075, metal = 3.5},
    {x = 155, z = 2315, metal = 3.5},
    
    -- northwest hills
    {x = 1260, z = 1410, metal = 2.0},
    {x = 1010, z = 940, metal = 2.0},
    {x = 1210, z = 620, metal = 2.0},
    {x = 1310, z = 1000, metal = 2.0},
    --{x = 500, z = 160, metal = 2.0},
    --{x = 300, z = 280, metal = 2.0},
    
    -- southwest hills
    {x = 1025, z = 3560, metal = 2.0},
    {x = 1060, z = 3815, metal = 2.0},
    {x = 1240, z = 3480, metal = 2.0},
    {x = 1800, z = 5000, metal = 2.0},
    --{x = 240, z = 4400, metal = 2.0},
    {x = 170, z = 3100, metal = 2.0},
    
    -- north/south hills
    {x = 2435, z = 230, metal = 2.0},
    {x = 2585, z = 4330, metal = 2.0},
    {x = 3005, z = 4425, metal = 2.0},
    
    -- in the river
    {x = 1810, z = 3120, metal = 2.0},
    {x = 3520, z = 3605, metal = 2.0},
}

local duelspots = {

}

local twospots = {

}

local threespots = {

}

local teamspots = {

}

-- there's probably a better way to get player count... borrowed from the old and bad player list
local pcount = 0
local playerlist = Spring.GetPlayerList()
local teamsSorted = Spring.GetTeamList()
-- count AIs
for i = 1, #teamsSorted do
	local teamID = teamsSorted[i]
	if teamID ~= Spring.GetGaiaTeamID() then
		local _,leader,isDead,isAI,_,allyTeamID = Spring.GetTeamInfo(teamID)
		if isAI then
			pcount = pcount + 1
		end
	end 
end
-- count humans
for i = 1, #playerlist do
	local playerID = playerlist[i]
	local name, active, spectator, teamID, allyTeamID, pingTime, cpuUsage, country = Spring.GetPlayerInfo(playerID)
	local isSpec = (teamID == 0 and spectator and (not Spring.GetGameRulesParam("initiallyPlayingPlayer_" .. playerID))) 
	if not isSpec then
		pcount = pcount + 1
	end
end

local ret = {}
local v2

local count = 1

for k,v in pairs(allspots) do
	ret[count] = v 
	ret[count+1] = {x = 6144-v.x, z = 5120-v.z, metal = v.metal}
	count = count + 2
end

if pcount > 2 then
	if pcount > 4 then
		if pcount > 6 then
			for k,v in pairs(teamspots) do
				ret[count] = v 
				ret[count+1] = {x = 6144-v.x, z = 5120-v.z, metal = v.metal}
				count = count + 2
			end
		else
			for k,v in pairs(threespots) do
				ret[count] = v 
				ret[count+1] = {x = 6144-v.x, z = 5120-v.z, metal = v.metal}
				count = count + 2
			end
		end
	else
		for k,v in pairs(twospots) do
			ret[count] = v 
			ret[count+1] = {x = 6144-v.x, z = 5120-v.z, metal = v.metal}
			count = count + 2
		end
	end
else
	for k,v in pairs(duelspots) do
		ret[count] = v 
		ret[count+1] = {x = 6144-v.x, z = 5120-v.z, metal = v.metal}
		count = count + 2
	end
end

return { spots = ret }
