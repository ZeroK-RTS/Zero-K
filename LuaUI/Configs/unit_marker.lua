local unitlistNames = {
	energyheavygeo = {},
	staticantinuke = {},
	staticheavyarty = {},
	athena = { mark_each_appearance = true, show_owner = true, },
	cloaksnipe = { mark_each_appearance = true, },
	energysingu = {},
	chicken_dragon = {},
	chickenflyerqueen = {},
	chickenlandqueen = {},
	roost = {},
	chickenspire = {},
	staticnuke = {},
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
	staticmissilesilo = {},
	pw_hq_attacker = {},
	pw_hq_defender = {},
	raveparty = {},
	cloakheavyraid = { mark_each_appearance = true, },
	cloakjammer = { mark_each_appearance = true, },
	striderhub = {},
	zenith = {},
	turretaaheavy = {},
}

local unitList = {}
for name, data in pairs(unitlistNames) do
	unitList[UnitDefNames[name].id] = data
end
return unitList
