local menu = {
	items = {
		{
			angle = 0,
			unit = "armcomdgun",
			label = "Stealth",
		},
		{
			angle = -45,
			unit = "scorpion",
			label = "Spider",
			items = {
				{
					angle = 45,
					unit = "funnelweb"
				}
			},  
		},
		{
			angle = -90,
			unit = "dante",
			label = "Light",
		},
		{
			angle = -135,
			unit = "armraven",
			label = "Artillery",
		},
		{
			angle = 45,
			unit = "armbanth",
			label = "Heavy",
		},
		{
			angle = 90,
			unit = "cornukesub",
			label = "Sub",
		},
		{
			angle = 135,
			unit = "corbats",
			label = "Ship",
			items = {
				{
					angle = -135,
					unit = "armcarry"
				},
				{
					angle = -135,
					unit = "reef"
				},
			}
		},
		{
			angle = 180,
			unit = "armorco",
			label = "Massive",
		},
	}
}

return menu

