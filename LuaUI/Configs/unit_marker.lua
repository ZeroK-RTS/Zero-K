local unitlistNames = {
	amgeo = {},
	armamd = {},
	armbrtha = {},
	armcsa = { mark_each_appearance = true, show_owner = true, },
	armsnipe = { mark_each_appearance = true, },
	cafus = {},
	chicken_dragon = {},
	chickenflyerqueen = {},
	chickenlandqueen = {},
	chickenqueenlite = {},
	corsilo = {},
	factoryamph = { show_owner = true, },
	factorycloak = { show_owner = true, },
	factorygunship = { show_owner = true, },
	factoryhover = { show_owner = true, },
	factoryjump = { show_owner = true, },
	factoryplane = { show_owner = true, },
	factoryshield = { show_owner = true, },
	factoryship = { show_owner = true, },
	factoryspider = { show_owner = true, },
	factorytank = { show_owner = true, },
	factoryveh = { show_owner = true, },
	missilesilo = {},
	pw_hq = {},
	raveparty = {},
	spherepole = { mark_each_appearance = true, },
	spherecloaker = { mark_each_appearance = true, },
	striderhub = {},
	zenith = {},
}

local unitList = {}
for name, data in pairs(unitlistNames) do
	unitList[UnitDefNames[name].id] = data
end
return unitList
