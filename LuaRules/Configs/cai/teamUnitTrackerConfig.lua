
local completeUnitListNames = {

	turretAA = {
		"corrazor",
		"missiletower",
		"turretaafar",
		"corflak",
		"screamer",
	},

	turret = {
		"corrl",
		"corllt",
		"corgrav",
		"turretemp",
		"turretriot",
		"corhlt",
		"turretgauss",
		"turretantiheavy",
		"cordoom",
	},
	
	economy = {
		"cormex",
		"energywind",
		"energysolar",
		"energyfusion",
		"cafus",
		"geo",
		"energyheavygeo",
		"staticcon",
		"factoryshield",
		"factorycloak",
		"factoryveh",
		"factoryplane",
		"factorygunship",
		"factoryhover",
		"factoryamph",
		"factoryspider",
		"factoryjump",
		"factorytank",
		"striderhub",
		"factoryship",
	},
	
	constructor = {
		"cloakcon",
		"cornecro",
		"corned",
		"coracv",
		"spidercon",
		"corfast",
		"corch",
		"amphcon",
		"planecon",
		"gunshipcon",
		"shipcon",
	},
}

local ground = {

	raider = {
		"cloakraid",
		"spherepole",
		"corak",
		"corfav",
		"corgator",
		"panther",
		"panther",
		"logkoda",
		"spiderscout",
		"corpyro",
		"amphraid",
		"corsh",
		"chicken",
		"chicken_leaper",
	},

	assault = {
		"cloakassault",
		"corthud",
		"corraid",
		"spiderassault",
		"corcan",
		"corsumo",
		"correap",
		"corgol",
		"amphassault",
		"hoverassault",
		"bantha",
		"detriment",
		"corkrog",
		"chickena",
		"chickenc",
		"chicken_tiamat",
	},

	skirm = {
		"cloakskirm",
		"corstorm",
		"nsaclash",
		"amphfloater",
		"spiderskirm",
		"cloaksnipe",
		"slowmort",
		"chickens",
		"chicken_sporeshooter",
		"scorpion",
	},
	
	antiSkirm = {
		"spidercrabe",
		"cormist",
		"firewalker",
	},

	riot = {
		"armwar",
		"cormak",
		"corlevlr",
		"spiderriot",
		"amphimpulse",
		"amphriot",
		"shieldfelon",
		"spiderriot",
		"spideremp",
		"tawf114",
		"hoverriot",
		"dante",
		"chickenwurm",
	},

	arty = {
		"cloakarty",
		"corgarp",
		"vehheavyarty",
		"hoverarty",
		"cormart",
		"trem",
		"striderarty",
		"chickenr",
		"chickenblobber",
	},
}

local antiAir = {	
	antiAir = {
		"cloakaa",
		"corcrash",
		"vehaa",
		"corsent",
		"hoveraa",
		"spideraa",
		"jumpaa",
		"amphaa",
		"shipaa",
		"gunshipaa",
	},
}

local air = {
	bomber = {
		"corshad",
		"corhurc2",
		"bomberdisarm",
		"bomberheavy",
	},
	
	gunship = {
		"gunshipemp",
		"gunshipbomb",
		"gunshipraid",
		"gunshipsupport",
		"gunshipassault",
		"gunshipheavyskirm",
		"corcrw",
	},
	
	transport = {
		"corvalk",
		"corbtrans",
	},
}

local fighter = {
	fighter = {
		"fighter",
		"corvamp",
	},
}

local defenseRequirementNames =  {
	["cormex"] = {mult = 1.5},
	["energywind"] = {mult = 1},
	["energysolar"] = {mult = 0.6},
	["energyfusion"] = {mult = 1},
	["cafus"] = {mult = 1},
	["geo"] = {mult = 1.5},
	["energyheavygeo"] = {mult = 1.5},
	["staticcon"] = {mult = 1},
	["factoryshield"] = {mult = 0.2},
	["factorycloak"] = {mult = 0.2},
	["factoryveh"] = {mult = 0.2},
	["factoryplane"] = {mult = 0.2},
	["factorygunship"] = {mult = 0.2},
	["factoryhover"] = {mult = 0.2},
	["factoryamph"] = {mult = 0.2},
	["factoryspider"] = {mult = 0.2},
	["factoryjump"] = {mult = 0.2},
	["factorytank"] = {mult = 0.2},
	["striderhub"] = {mult = 0.2},
	["factoryship"] = {mult = 0.2},
}

local function FlattenTableInto(tableToFlatten, category, otherTable)
	for _, namesList in pairs(tableToFlatten) do
		otherTable[category] = {}
		for i = 1, #namesList do
			otherTable[category][i] = namesList[i]
		end
	end
end

FlattenTableInto(ground, "ground", completeUnitListNames)
FlattenTableInto(antiAir, "antiAir", completeUnitListNames)
FlattenTableInto(air, "air", completeUnitListNames)
FlattenTableInto(fighter, "fighter", completeUnitListNames)

local getMovetype = Spring.Utilities.getMovetype

local function AddListNames(list, source)
	for category, namesList in pairs(source) do
		for i = 1, #namesList do
			local defName = namesList[i]
			local ud = UnitDefNames[defName]
			if ud then
				list[ud.id] = {
					name = category,
					cost = ud.metalCost,
				}
			end
		end
	end
	
	for defID = 1, #UnitDefs do
		if not list[defID] then
			local ud = UnitDefs[defID]
			
			local moveType = getMovetype(ud) 
			if moveType then
				list[ud.id] = {
					name = "miscUnit",
					cost = ud.metalCost,
				}
			else
				list[ud.id] = {
					name = "miscStructure",
					cost = ud.metalCost,
				}
			end
		end
	end
end

local function CreateHeatmapData(source)
	local retList = {}
	for category, namesList in pairs(source) do
		for defName, data in pairs(namesList) do
			local ud = UnitDefNames[defName]
			if ud then
				local weaponRange = (data.range or ud.maxWeaponRange) + 50
				local finalData = {
					name = category,
					radius = weaponRange,
					amount = ud.metalCost*data.mult,
				}
				if retList[ud.id] then
					retList[ud.id][#retList[ud.id]] = finalData
				else
					retList[ud.id] = {
						[1] = finalData,
					}
				end
			end
		end
	end
	return retList
end

local function CreateWeightedNameList(source)
	local retList = {}
	for defName, data in pairs(source) do
		local ud = UnitDefNames[defName]
		if ud then
			local weaponRange = (data.range or ud.maxWeaponRange) + 50
			local finalData = {
				name = category,
				radius = weaponRange,
				amount = ud.metalCost*data.mult,
			}
			if retList[ud.id] then
				retList[ud.id][#retList[ud.id]] = finalData
			else
				retList[ud.id] = {
					[1] = finalData,
				}
			end
		end
	end
	return retList
end

local completeListUnitDefID = {}
AddListNames(completeListUnitDefID, completeUnitListNames)


local defenseRequirementUnitDefID = CreateWeightedNameList(defenseRequirementNames)

return defenseRequirementUnitDefID, completeListUnitDefID
