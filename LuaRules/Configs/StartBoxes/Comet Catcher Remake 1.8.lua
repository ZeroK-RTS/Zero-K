local boxFuncs = VFS.Include("LuaRules/Configs/StartBoxes/helpers.lua")

local layout = Spring.Utilities.Gametype.is1v1() and {
	[0] = {
		nameLong = "North-West",
		nameShort = "NW",
		startpoints = {
			{570, 650},
		},
		boxes = {
			{
				{0, 0},
				{1279, 0},
				{1279, 324},
				{686, 1019},
				{0, 1019},
			}
		},
	},
	[1] = {
		nameLong = "South-East",
		nameShort = "SE",
		startpoints = {
			{7620, 5510},
		},
		boxes = {
			{
				{6900, 6144},
				{6900, 5857},
				{7542, 5137},
				{8192, 5137},
				{8192, 6144},
			},
		},
	},
} or boxFuncs.RotateMirrorBoxes({
	[0] = {
		nameLong = "West",
		nameShort = "W",
		startpoints = {
			{820, 3072},
		},
		boxes = {
			{
				{1638, 0},
				{1638, 6144},
				{0, 6144},
				{0, 0},
			},
		},
	},
	[1] = {
		nameLong = "East",
		nameShort = "SE",
	},
})

return layout
