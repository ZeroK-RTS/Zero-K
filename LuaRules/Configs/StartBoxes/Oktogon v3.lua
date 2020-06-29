local rings = { -- could also get them from map VFS but this way various infrastructure can also in theory access it
	{ -- grass (middle)
		{ 3389,  9071},
		{ 3355,  3466},
		{ 8765,  3235},
		{ 8910,  8835},
	}, { -- outer 1
		{  955,  7866},
		{ 4324,   992},
		{11148,  4376},
		{ 7317, 11477},
	}, { -- outer 2
		{ 1030,  3951},
		{ 8326,   995},
		{11035,  8169},
		{ 3967, 11202},
	}, { -- center
		{ 5126,  6158},
		{ 6096,  5051},
		{ 7120,  6071},
		{ 6194,  7151},
	}
}

local rings_to_use
local N = Spring.Utilities.GetTeamCount()
if N == 2 then
	rings_to_use = {1} -- center would be jackfest or some other crappy rush, and the outer rings are comparatively lame
elseif N <= 4 then
	if math.random() < 0.7 then
		rings_to_use = {1} -- skew random because green is the best (see 1v1)
	else
		rings_to_use = {math.random(2,4)} -- except it's ffa so spice shit up from time to time
	end
elseif N <= 8 then
	if math.random() < 0.7 then
		rings_to_use = {2,3} -- outer ring is the most symmetric for 8-way
	else
		rings_to_use = {1,4}
	end
elseif N <= 12 then
	local r = math.random()
	if r < 0.25 then
		rings_to_use = {1,2,3}
	elseif r < 0.50 then
		rings_to_use = {2,3,4}
	elseif r < 0.75 then
		rings_to_use = {1,2,4}
	else
		rings_to_use = {1,3,4}
	end
else
	rings_to_use = {1,2,3,4}
end

local starts = {}
for i = 1, #rings_to_use do
	local ring = rings_to_use[i]
	for j = 1, 4 do
		starts[#starts + 1] = rings[ring][j]
	end
end

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
return ret, {2, 4, 8, 12, 16}
