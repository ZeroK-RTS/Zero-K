local menu = {
	items = {
		{
			angle = 0,
			unit = "striderantiheavy",
			label = "Stealth",
		},
		{
			angle = -45,
			unit = "striderscorpion",
			label = "Spider",
			items = {
				{
					angle = 45,
					unit = "striderfunnelweb"
				}
			},
		},
		{
			angle = -90,
			unit = "striderdante",
			label = "Light",
		},
		{
			angle = -135,
			unit = "striderarty",
			label = "Artillery",
		},
		{
			angle = 45,
			unit = "striderbantha",
			label = "Heavy",
		},
		{
			angle = 90,
			unit = "subtacmissile",
			label = "Sub",
		},
		{
			angle = 135,
			unit = "shipheavyarty",
			label = "Ship",
			items = {
				{
					angle = -135,
					unit = "shipcarrier"
				},
			},
		},
		{
			angle = 180,
			unit = "striderdetriment",
			label = "Massive",
		},
	}
}

return menu

