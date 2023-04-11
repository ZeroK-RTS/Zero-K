local funcs = {}

function funcs.RotateMirrorBoxes(layout)
	layout[1].boxes = {{}}
	layout[1].startpoints = {}
	
	for i = 1, #layout[0].boxes[1] do
		layout[1].boxes[1][i] = {
			Game.mapSizeX - layout[0].boxes[1][i][1],
			Game.mapSizeZ - layout[0].boxes[1][i][2]
		}
	end
	for i = 1, #layout[0].startpoints do
		layout[1].startpoints[i] = {
			Game.mapSizeX - layout[0].startpoints[i][1],
			Game.mapSizeZ - layout[0].startpoints[i][2]
		}
	end
	return layout
end

function funcs.NorthSouthBoxes(extent)
	local percent = extent / Game.mapSizeZ
	local layout = {
		[0] = {
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
		[1] = {
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
		[0] = {
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
		[1] = {
			boxes = {{}},
			startpoints = {},
			nameLong  = "East",
			nameShort = "E",
		}, -- mirrored automatically
	}

	return funcs.RotateMirrorBoxes(layout)
end

return funcs