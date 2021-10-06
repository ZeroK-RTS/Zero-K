local airpadDefs = {
	[UnitDefNames["factoryplane"].id] = {
		padPieceName = {"land"}
	},
	[UnitDefNames["staticrearm"].id] = {
		padPieceName = {"land1","land2","land3","land4"}
	},
	[UnitDefNames["shipcarrier"].id] = {
		padPieceName = {"LandingFore","LandingAft"}
	},
}

for unitDefID, config in pairs(airpadDefs) do
    local ud = UnitDefs[unitDefID]

    config.mobile = (not ud.isImmobile)
    config.cap = config.cap or ud.customParams.pad_count
end

return airpadDefs
