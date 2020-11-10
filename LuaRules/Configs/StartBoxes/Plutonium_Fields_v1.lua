local starts = {
		{2758, 1502, "North"     , "N" },
		{3378, 4656, "South"     , "S" },
		{1475, 3359, "West"      , "W" },
		{4695, 2808, "East"      , "E" },

		{ 630, 5303, "South-West", "SW"},
		{5429,  925, "North-East", "NE"},
		{5248, 5503, "South-East", "SE"},
		{ 911,  677, "North-West", "NW"},

		{5983, 4048, "East"      , "E" }, -- names disambiguated later
		{241,  2123, "West"      , "W" },
		{4105,  258, "North"     , "N" },
		{2011, 5915, "South"     , "S" },
}

local used_starts = {}

local tc = Spring.Utilities.GetTeamCount()
if tc <= 4 then
	local set = math.random(0, 2) * 4
	for i = 1, 4 do
		used_starts[i] = starts[set + i]
	end
elseif tc <= 8 then
	-- always use the outer ones
	for i = 1, 8 do
		used_starts[i] = starts[4 + i]
	end
else
	for i = 1, 4 do
		starts[i][3] = "Mid-" .. starts[i][3]
		starts[i][4] = "M" .. starts[i][4]
	end
	for i = 9, 12 do
		starts[i][3] = "Far-" .. starts[i][3]
		starts[i][4] = "F" .. starts[i][4]
	end
	used_starts = starts
end

-- convert the above to boxes (160 radius circles)
local ret = {}
for i = 1, #used_starts do
	ret[i-1] = {
		nameLong  = used_starts[i][3],
		nameShort = used_starts[i][4],
		startpoints = { { used_starts[i][1], used_starts[i][2] } },
		boxes = { { } },
	}
	for j = 1, 10 do
		ret[i-1].boxes[1][j] = {
			used_starts[i][1] + 160 * math.sin(j * math.pi / 5),
			used_starts[i][2] + 160 * math.cos(j * math.pi / 5),
		}
	end
end

return ret, {2, 4, 8, 12}
