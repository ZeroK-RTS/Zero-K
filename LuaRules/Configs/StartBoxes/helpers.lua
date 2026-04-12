local funcs = {}

function funcs.RotateMirrorBoxes(layout)
	layout[2].boxes = {{}}
	layout[2].startpoints = {}
	
	for i = 1, #layout[1].boxes[1] do
		layout[2].boxes[1][i] = {
			Game.mapSizeX - layout[1].boxes[1][i][1],
			Game.mapSizeZ - layout[1].boxes[1][i][2]
		}
	end
	for i = 1, #layout[1].startpoints do
		layout[2].startpoints[i] = {
			Game.mapSizeX - layout[1].startpoints[i][1],
			Game.mapSizeZ - layout[1].startpoints[i][2]
		}
	end
	return layout
end

function funcs.NorthSouthBoxes(extent)
	local percent = extent / Game.mapSizeZ
	local layout = {
		{
			nameLong = "North",
			nameShort = "N",
			startpoints = {
				{Game.mapSizeX*0.5, Game.mapSizeZ*percent*0.5},
			},
			boxes = {
				{
					{0, Game.mapSizeZ*percent},
					{Game.mapSizeX, Game.mapSizeZ*percent},
					{Game.mapSizeX, 0},
					{0, 0},
				},
			},
		},
		{
			boxes = {{}},
			startpoints = {},
			nameLong  = "South",
			nameShort = "S",
		}, -- mirrored automatically
	}

	return funcs.RotateMirrorBoxes(layout)
end

function funcs.EastWestBoxes(extent)
	local percent = extent / Game.mapSizeX
	local layout = {
		{
			nameLong = "West",
			nameShort = "W",
			startpoints = {
				{Game.mapSizeX*percent*0.5, Game.mapSizeZ*0.5},
			},
			boxes = {
				{
					{0, Game.mapSizeZ},
					{Game.mapSizeX*percent, Game.mapSizeZ},
					{Game.mapSizeX*percent, 0},
					{0, 0},
				},
			},
		},
		{
			boxes = {{}},
			startpoints = {},
			nameLong  = "East",
			nameShort = "E",
		}, -- mirrored automatically
	}

	return funcs.RotateMirrorBoxes(layout)
end

return funcs