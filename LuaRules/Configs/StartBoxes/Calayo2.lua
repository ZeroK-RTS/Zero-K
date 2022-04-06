return {
	[0] = {
		nameLong = "Northwest",
		nameShort = "NW",
		startpoints = {
			{205,205},
		},
		boxes = {
			{
				{0,0},
				{410,0},
				{410,410},
				{0,410},
			},
		},
	},
	[1] = {
		nameLong = "Southeast",
		nameShort = "SE",
		startpoints = {
			{3891,3891},
		},
		boxes = {
			{
				{3686,3686},
				{4096,3686},
				{4096,4096},
				{3686,4096},
			},
		},
	},
--[[ The map is not actually 4-way symmetrical.
     The other corners could probably be reused
     at some point but for now they're excluded.

	[2] = {
		nameLong = "Northeast",
		nameShort = "NE",
		startpoints = {
			{3891,205},
		},
		boxes = {
			{
				{3686,0},
				{4096,0},
				{4096,410},
				{3686,410},
			},
		},
	},
	[3] = {
		nameLong = "Southwest",
		nameShort = "SW",
		startpoints = {
			{205,3891},
		},
		boxes = {
			{
				{0,3686},
				{410,3686},
				{410,4096},
				{0,4096},
			},
		},
	},
]]
}
