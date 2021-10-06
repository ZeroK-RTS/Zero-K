local airpadDefs = {
	[UnitDefNames["factoryplane"].id] = {
		mobile = false,
		cap = 1,
		padPieceName = {"land"}
	},
	[UnitDefNames["staticrearm"].id] = {
		mobile = false,
		cap = 4,
		padPieceName = {"land1","land2","land3","land4"}
	},
	[UnitDefNames["shipcarrier"].id] = {
		mobile = true,
		cap = 2,
		padPieceName = {"LandingFore","LandingAft"}
	},
}

return airpadDefs
