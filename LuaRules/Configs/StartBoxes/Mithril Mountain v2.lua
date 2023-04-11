local boxFuncs = VFS.Include("LuaRules/Configs/StartBoxes/helpers.lua")

local layout = {
	[0] = {
		nameLong = "North-West",
		nameShort = "NW",
		startpoints = {
			{1610, 800},
		},
		boxes = {
			{
				{0, 1822},
				{542, 1822},
				{2046, 960},
				{2393, 248},
				{2393, 0},
				{0, 0},
				{12, 9},
			},
		},
	},
	[1] = {
		nameLong = "South-East",
		nameShort = "SE",
	},
}

return boxFuncs.RotateMirrorBoxes(layout)
