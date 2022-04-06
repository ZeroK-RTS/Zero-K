local tiny = {
	[0] = {
		startpoints = {
			{250,2200},
		},
		boxes = {
			{
				{20,1975},
				{550,1975},
				{550,2375},
				{20,2375},
			},
		},
		nameLong = "West",
		nameShort = "W",
	},
	[1] = {
		startpoints = {
			{6144-250,5120-2200},
		},
		boxes = {
			{
				{6144-20,5120-1975},
				{6144-550,5120-1975},
				{6144-550,5120-2375},
				{6144-20,5120-2375},
			},
		},
		nameLong = "East",
		nameShort = "E",
	},
}

local small = {
	[0] = {
		startpoints = {
			{250,2200},
		},
		boxes = {
			{
				{20,1975},
				{550,1975},
				{550,3200},
				{20,3200},
			},
		},
		nameLong = "West",
		nameShort = "W",
	},
	[1] = {
		startpoints = {
			{6144-250,5120-2200},
		},
		boxes = {
			{
				{6144-20,5120-1975},
				{6144-550,5120-1975},
				{6144-550,5120-3200},
				{6144-20,5120-3200},
			},
		},
		nameLong = "East",
		nameShort = "E",
	},
}

local large = {
	[0] = {
		startpoints = {
			{1500,3150},
		},
		boxes = {
			{
				{20,700},
				{850,700},
				{850,4100},
				{20,4100},
			},
		},
		nameLong = "West",
		nameShort = "W",
	},
	[1] = {
		startpoints = {
			{6144-3150,5120-1500},
		},
		boxes = {
			{
				{6144-20,5120-700},
				{6144-850,5120-700},
				{6144-850,5120-4100},
				{6144-20,5120-4100},
			},
		},
		nameLong = "East",
		nameShort = "E",
	},
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

if pcount > 4 then
	if pcount > 10 then
		return large
	else
		return small
	end
end
return tiny
