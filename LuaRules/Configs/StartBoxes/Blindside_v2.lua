local suported_playercounts = {5, 11, 16}
--[[ The 16 startpoints form a planar graph where each vertex is a 3-mex startpoint and has 3 edges, which
     are veh-pathable passages to other vertices with 2 mexes in between. The lack of connection means there
     are mountains in between (there are some mexes and geospots in the mountains but they are standalone).

     5 of the vertices are landlocked but also have a geospot. The remanining 11 vertices are all on the coast
     so have water access but no geo. Each of the 11 has exactly one connection to one of the 5, but not vice
     versa (there's two connections between geo pairs and one standalone spot with 3 connections to the shore).

     The "3 connections each" rule could probably be used to construct a lot of mostly-fair distributions
     for other player counts but I don't have the mana to do that so only did the obvious geo-related ones. ]]

local potential_starts = { -- x, z, hasGeoButIsLandlocked, connectedVertices (geo)
	[ 1] = { 1628, 3881, false, {  2 , ( 3),   4  }},
	[ 2] = { 3300, 1179, false, {  1 , ( 3),   5  }},
	[ 3] = { 3853, 3498,  true, {  1 ,   2 , ( 6) }},
	[ 4] = { 3420, 6195, false, {  1 , ( 6),   7  }},
	[ 5] = { 5861, 1299, false, {  2 , ( 6),   8  }},
	[ 6] = { 5983, 4260,  true, {( 3),   4 ,   5  }},
	[ 7] = { 6448, 6681, false, {  4 , ( 9),  10  }},
	[ 8] = { 9085, 1259, false, {  5 , (11),  13  }},
	[ 9] = { 8387, 4180,  true, {  7 ,  10 , (11) }},
	[10] = { 9000, 6533, false, {  7 , ( 9),  12  }},
	[11] = {10710, 3457,  true, {  8 , ( 9),  12  }},
	[12] = {10926, 6131, false, { 10 , (11),  15  }},
	[13] = {12784, 1325, false, {  8 , (14),  16  }},
	[14] = {12742, 4092,  true, { 13 ,  15 ,  16  }}, -- not connected to any geo, though has one itself
	[15] = {13729, 6509, false, { 12 , (14),  16  }},
	[16] = {14914, 2751, false, { 13 , (14),  15  }},
}


local starts
local N = Spring.Utilities.GetTeamCount()
if N <= 5 then
	-- just the geospot starts
	starts = {}
	for i = 1, #potential_starts do
		local p = potential_starts[i]
		if p[3] then
			starts[#starts + 1] = p
		end
	end
elseif N <= 11 then
	-- just the non-geospot starts
	starts = {}
	for i = 1, #potential_starts do
		local p = potential_starts[i]
		if not p[3] then
			starts[#starts + 1] = p
		end
	end
else
	starts = potential_starts
end


-- convert the above to boxes (256 radius circles)
local ret = {}
for i = 1, #starts do
	ret[i-1] = {
		startpoints = { { starts[i][1], starts[i][2] } },
		boxes = { { } },
	}
	for j = 1, 16 do
		ret[i-1].boxes[1][j] = {
			starts[i][1] + 256 * math.sin(j * math.pi / 8),
			starts[i][2] + 256 * math.cos(j * math.pi / 8),
		}
	end
end

return ret, suported_playercounts
