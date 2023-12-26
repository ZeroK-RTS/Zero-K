local layout = Spring.Utilities.Gametype.is1v1() and {
	[0] = {
		nameLong = "North-East",
		nameShort = "NE",
		startpoints = {
			{5500, 580},
		},
		boxes = {
			{
				{6144, 1279},
				{5834, 1279},
				{5102, 668},
				{5102, 0},
				{6144, 0},
			},
		},
	},
	[1] = {
		nameLong = "South-West",
		nameShort = "SW",
		startpoints = {
			{640, 7620},
		},
		boxes = {
			{
				{0, 6928},
				{323, 6928},
				{1044, 7536},
				{1044, 8192},
				{0, 8192},
			},
		},
	},
} or  {
	[0] = {
		nameLong = "North",
		nameShort = "N",
		startpoints = {
			{3072,614},
			{5120,614},
			{1024,614},
		},
		boxes = {
			{
				{0,0},
				{6144,0},
				{6144,1229},
				{0,1229},
			},
		},
	},
	[1] = {
		nameLong = "South",
		nameShort = "S",
		startpoints = {
			{3072,7578},
			{1024,7578},
			{5120,7578},
		},
		boxes = {
			{
				{0,6963},
				{6144,6963},
				{6144,8192},
				{0,8192},
			},
		},
	},
}

return layout
