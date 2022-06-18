local SHOW_OWNER = { show_owner = true }
local MARK_EACH = { mark_each_appearance = true }
local DEFAULT = { }

local unitlistNames = {
	athena = { mark_each_appearance = true, show_owner = true, },
	cloaksnipe = MARK_EACH,
	cloakheavyraid = MARK_EACH,
	cloakjammer = MARK_EACH,
	spiderantiheavy = MARK_EACH,

	energyheavygeo = DEFAULT,
	energyfusion = DEFAULT,
	energysingu = DEFAULT,

	chicken_dragon = DEFAULT,
	chickenflyerqueen = DEFAULT,
	chickenlandqueen = DEFAULT,
	roost = DEFAULT,
	chickenspire = DEFAULT,

	staticantinuke = DEFAULT,
	staticnuke = DEFAULT,

	factoryamph = SHOW_OWNER,
	factorycloak = SHOW_OWNER,
	factorygunship = SHOW_OWNER,
	factoryhover = SHOW_OWNER,
	factoryjump = SHOW_OWNER,
	factoryplane = SHOW_OWNER,
	factoryshield = SHOW_OWNER,
	factoryship = SHOW_OWNER,
	factoryspider = SHOW_OWNER,
	factorytank = SHOW_OWNER,
	factoryveh = SHOW_OWNER,
	staticmissilesilo = DEFAULT,
	pw_hq_attacker = DEFAULT,
	pw_hq_defender = DEFAULT,
	striderhub = DEFAULT,

	staticarty = DEFAULT,
	staticheavyarty = DEFAULT,

	turretantiheavy = DEFAULT,
	turretheavy = DEFAULT,
	turretaaheavy = DEFAULT,

	jumpsumo = DEFAULT,
	spidercrabe = DEFAULT,
	tankheavyarty = DEFAULT,
	hoverarty = DEFAULT,
	amphassault = DEFAULT,
	tankheavyassault = DEFAULT,

	striderfunnelweb = DEFAULT,
	striderantiheavy = DEFAULT,
	striderdante = DEFAULT,
	striderbantha = DEFAULT,
	shipcarrier = DEFAULT,
	gunshipkrow = DEFAULT,
	striderarty = DEFAULT,
	shipheavyarty = DEFAULT,
	subtacmissile = DEFAULT,
	striderscorpion = DEFAULT,
	striderdetriment = DEFAULT,

	-- these announce their presence globally, but
	-- are still worth marking in case they get scouted
	-- as a nanoframe or when toggled off
	mahlazer = DEFAULT,
	zenith = DEFAULT,
	raveparty = DEFAULT,
}

local unitList = {}
local UnitDefNames = UnitDefNames
for name, data in pairs(unitlistNames) do
	unitList[UnitDefNames[name].id] = data
end
return unitList
