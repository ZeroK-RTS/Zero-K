local heatmapNames = {
	mobileAntiAir = {
		["cloakaa"] = {mult = 1},
		["corcrash"] = {mult = 1},
		["vehaa"] = {mult = 1},
		["corsent"] = {mult = 1},
		["hoveraa"] = {mult = 1},
		["spideraa"] = {mult = 1},
		["jumpaa"] = {mult = 1},
		["amphaa"] = {mult = 1},
		["shipaa"] = {mult = 1},
		["gunship11"] = {mult = 1},
		
		["tawf114"] = {mult = 0.4},
		["slowmort"] = {mult = 0.4},
		["cloaksnipe"] = {mult = 0.4},
		["shieldfelon"] = {mult = 0.4},
	},
	
	staticAntiAir = {
		["corrl"] = {mult = 1},
		["corrazor"] = {mult = 1},
		["missiletower"] = {mult = 2},
		["turretaafar"] = {mult = 1.5},
		["corflak"] = {mult = 2},
		["screamer"] = {mult = 1},
		
		["corgrav"] = {mult = 1},
		["turretemp"] = {mult = 1},
	},
	
	mobileLand = {
		["cloakraid"] = {mult = 1},
		["spherepole"] = {mult = 1},
		["corak"] = {mult = 1},
		["corfav"] = {mult = 1},
		["corgator"] = {mult = 1},
		["panther"] = {mult = 1},
		["logkoda"] = {mult = 1},
		["spiderscout"] = {mult = 1},
		["corpyro"] = {mult = 1},
		["amphraid"] = {mult = 1},
		["corsh"] = {mult = 1},
		["chicken"] = {mult = 1},
		["chicken_leaper"] = {mult = 1},
        
		["cloakassault"] = {mult = 1},
		["corthud"] = {mult = 1},
		["corraid"] = {mult = 1},
		["spiderassault"] = {mult = 1},
		["corcan"] = {mult = 1},
		["corsumo"] = {mult = 1},
		["correap"] = {mult = 1},
		["corgol"] = {mult = 1},
		["amphassault"] = {mult = 1},
		["hoverassault"] = {mult = 1},
		["bantha"] = {mult = 1},
		["detriment"] = {mult = 1},
		["corkrog"] = {mult = 1},
		["chickena"] = {mult = 1},
		["chickenc"] = {mult = 1},
		["chicken_tiamat"] = {mult = 1},
        
		["cloakskirm"] = {mult = 1},
		["corstorm"] = {mult = 1},
		["nsaclash"] = {mult = 1},
		["amphfloater"] = {mult = 1},
		["spiderskirm"] = {mult = 1},
		["cloaksnipe"] = {mult = 1},
		["slowmort"] = {mult = 1},
		["chickens"] = {mult = 1},
		["chicken_sporeshooter"] = {mult = 1},
		["scorpion"] = {mult = 1},
        
		["spidercrabe"] = {mult = 1},
		["cormist"] = {mult = 1},
		["firewalker"] = {mult = 1},
		
		["armwar"] = {mult = 1},
		["cormak"] = {mult = 1},
		["corlevlr"] = {mult = 1},
		["spiderriot"] = {mult = 1},
		["amphimpulse"] = {mult = 1},
		["amphriot"] = {mult = 1, range = 300},
		["shieldfelon"] = {mult = 1},
		["spiderriot"] = {mult = 1},
		["spideremp"] = {mult = 1},
		["tawf114"] = {mult = 1},
		["hoverriot"] = {mult = 1},
		["dante"] = {mult = 1},
		["chickenwurm"] = {mult = 1},
		
		["cloakarty"] = {mult = 1},
		["corgarp"] = {mult = 1},
		["vehheavyarty"] = {mult = 1},
		["hoverarty"] = {mult = 1},
		["cormart"] = {mult = 1},
		["trem"] = {mult = 1},
		["striderarty"] = {mult = 1},
		["chickenr"] = {mult = 1},
		["chickenblobber"] = {mult = 1},
	},
	
	staticLand = {
		["corrl"] = {mult = 2},
		["corllt"] = {mult = 2},
		["corgrav"] = {mult = 2},
		["turretemp"] = {mult = 2},
		["turretriot"] = {mult = 2},
		["corhlt"] = {mult = 2},
		["turretgauss"] = {mult = 2},
		["turretantiheavy"] = {mult = 2},
		["cordoom"] = {mult = 2},
		["staticarty"] = {mult = 2},
	},
}

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
		"energysingu",
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
		"tankcon",
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
		"bomberdive",
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
		"gunshipheavytrans",
	},
}

local fighter = {
	fighter = {
		"fighter",
		"corvamp",
	},
}

local economyTargetNames =  {
	["cormex"] = {mult = 1.5},
	["energywind"] = {mult = 1},
	["energysolar"] = {mult = 0.6},
	["energyfusion"] = {mult = 1},
	["energysingu"] = {mult = 1},
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

	["cloakcon"] = {mult = 1},
	["cornecro"] = {mult = 1},
	["corned"] = {mult = 1},
	["tankcon"] = {mult = 1},
	["spidercon"] = {mult = 1},
	["corfast"] = {mult = 1},
	["corch"] = {mult = 1},
	["amphcon"] = {mult = 1},
	["planecon"] = {mult = 1},
	["gunshipcon"] = {mult = 1},
	["shipcon"] = {mult = 1},
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

local function AddListNames(list, source, addMisc, addCommander)
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
	
	if addMisc then
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
	
	if addCommander then
		for defID = 1, #UnitDefs do
			local ud = UnitDefs[defID]
			if ud.customParams.dynamic_comm or ud.customParams.commtype then
				list[ud.id] = {
					name = "commander",
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

local heatmapUnitDefID = CreateHeatmapData(heatmapNames)

local completeListUnitDefID = {}
AddListNames(completeListUnitDefID, completeUnitListNames, true)

local combatListUnitDefID = {}
AddListNames(combatListUnitDefID, ground, false, true)
AddListNames(combatListUnitDefID, antiAir)
AddListNames(combatListUnitDefID, air)
AddListNames(combatListUnitDefID, fighter)

local economyTargetUnitDefID = CreateWeightedNameList(economyTargetNames)

return heatmapUnitDefID, completeListUnitDefID, combatListUnitDefID, economyTargetUnitDefID
