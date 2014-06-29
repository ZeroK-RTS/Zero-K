
local completeUnitListNames = {

	turretAA = {
		"corrazor",
		"missiletower",
		"armcir",
		"corflak",
		"screamer",
	},

	turret = {
		"corrl",
		"corllt",
		"corgrav",
		"armartic",
		"armdeva",
		"corhlt",
		"armpb",
		"armanni",
		"cordoom",
	},
	
	economy = {
		"cormex",
		"armwin",
		"armsolar",
		"armfus",
		"cafus",
		"geo",
		"amgeo",
		"armnanotc",
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
		"armrectr",
		"cornecro",
		"corned",
		"coracv",
		"arm_spider",
		"corfast",
		"corch",
		"amphcon",
		"armca",
		"shipcon",
	},
}

local ground = {

	raider = {
		"armpw",
		"spherepole",
		"corak",
		"corfav",
		"corgator",
		"panther",
		"panther",
		"logkoda",
		"armflea",
		"corpyro",
		"amphraider3",
		"corsh",
		"chicken",
		"chicken_leaper",
	},

	assault = {
		"armzeus",
		"corthud",
		"corraid",
		"spiderassault",
		"corcan",
		"corsumo",
		"correap",
		"corgol",
		"amphassault",
		"hoverassault",
		"armbanth",
		"armorco",
		"corkrog",
		"chickena",
		"chickenc",
		"chicken_tiamat",
	},

	skirm = {
		"armrock",
		"corstorm",
		"nsaclash",
		"amphfloater",
		"armsptk",
		"armsnipe",
		"slowmort",
		"chickens",
		"chicken_sporeshooter",
		"scorpion",
	},
	
	antiSkirm = {
		"armcrabe",
		"cormist",
		"firewalker",
	},

	riot = {
		"armwar",
		"cormak",
		"corlevlr",
		"spiderriot",
		"amphraider2",
		"amphriot",
		"shieldfelon",
		"spiderriot",
		"arm_venom",
		"tawf114",
		"hoverriot",
		"dante",
		"chickenwurm",
	},

	arty = {
		"armham",
		"corgarp",
		"armmerl",
		"armmanni",
		"cormart",
		"trem",
		"armraven",
		"chickenr",
		"chickenblobber",
	},
}

local antiAir = {	
	antiAir = {
		"armjeth",
		"corcrash",
		"vehaa",
		"corsent",
		"hoveraa",
		"spideraa",
		"armaak",
		"amphaa",
		"shipaa",
		"gunshipaa",
	},
}

local air = {
	bomber = {
		"corshad",
		"corhurc2",
		"armstiletto_laser",
		"armcybr",
	},
	
	gunship = {
		"bladew",
		"blastwing",
		"armkam",
		"gunshipsupport",
		"blackdawn",
		"armbrawl",
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
	["armwin"] = {mult = 1},
	["armsolar"] = {mult = 0.6},
	["armfus"] = {mult = 1},
	["cafus"] = {mult = 1},
	["geo"] = {mult = 1.5},
	["amgeo"] = {mult = 1.5},
	["armnanotc"] = {mult = 1},
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
