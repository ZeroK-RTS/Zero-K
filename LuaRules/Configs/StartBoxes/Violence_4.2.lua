local layout = {
	[0] = {{
		{4599.8403320313, 3195.0278320313},
		{4669.3291015625, 3121.9633789063},
		{4742.1538085938, 3089.4133300781},
		{4841.6083984375, 3061.3872070313},
		{4929.0893554688, 3033.1252441406},
		{4994.1552734375, 3045.7421875},
		{5061.5859375, 3041.9548339844},
		{5253.642578125, 3572.7189941406},
		{5124.296875, 3561.4067382813},
		{5078.3134765625, 3561.6203613281},
		{4998.9458007813, 3590.4201660156},
		{4905.673828125, 3620.4255371094},
		{4841.2314453125, 3639.5561523438},
		{4719.2509765625, 3751.419921875},
	}},
	[1] = {{}},
	[2] = {{}},
	[3] = {{}},
	[4] = {{}},
}

local startpos = {
	[0] = {{4907, 3359}},
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
}

local center = {Game.mapSizeX / 2, Game.mapSizeZ / 2}

for tri = 1, #layout[0][1] do
	local dx = (layout[0][1][tri][1] - center[1])
	local dy = (layout[0][1][tri][2] - center[2])
	for area = 1, 4 do
		local phi = math.pi * area * 0.4
		layout[area][1][tri] = {
			center[1] + dx*math.cos(phi) + dy*math.sin(-phi),
			center[2] + dx*math.sin(phi) + dy*math.cos(phi)
		}
	end
end

for area = 0, 4 do
	local dx = (startpos[0][1][1] - center[1])
	local dy = (startpos[0][1][2] - center[2])
	local phi = math.pi * area * 0.4
	startpos[area][1] = {
		center[1] + dx*math.cos(phi) + dy*math.sin(-phi),
		center[2] + dx*math.sin(phi) + dy*math.cos(phi)
	}
end

return layout, startpos, {2, 5}