local heatmapNames = {
	mobileAntiAir = {
		["cloakaa"] = {mult = 1},
		["shieldaa"] = {mult = 1},
		["vehaa"] = {mult = 1},
		["tankaa"] = {mult = 1},
		["hoveraa"] = {mult = 1},
		["spideraa"] = {mult = 1},
		["jumpaa"] = {mult = 1},
		["amphaa"] = {mult = 1},
		["shipaa"] = {mult = 1},
		["gunship11"] = {mult = 1},
		
		["tankriot"] = {mult = 0.4},
		["jumpskirm"] = {mult = 0.4},
		["cloaksnipe"] = {mult = 0.4},
		["shieldfelon"] = {mult = 0.4},
	},
	
	staticAntiAir = {
		["turretmissile"] = {mult = 1},
		["turretaalaser"] = {mult = 1},
		["turretaaclose"] = {mult = 2},
		["turretaafar"] = {mult = 1.5},
		["turretaaflak"] = {mult = 2},
		["turretaaheavy"] = {mult = 1},
		
		["turretimpulse"] = {mult = 1},
		["turretemp"] = {mult = 1},
	},
	
	mobileLand = {
		["cloakraid"] = {mult = 1},
		["cloakheavyraid"] = {mult = 1},
		["shieldraid"] = {mult = 1},
		["vehscout"] = {mult = 1},
		["vehraid"] = {mult = 1},
		["tankheavyraid"] = {mult = 1},
		["tankraid"] = {mult = 1},
		["spiderscout"] = {mult = 1},
		["jumpraid"] = {mult = 1},
		["amphraid"] = {mult = 1},
		["hoverraid"] = {mult = 1},
		["chicken"] = {mult = 1},
		["chicken_leaper"] = {mult = 1},
        
		["cloakassault"] = {mult = 1},
		["shieldassault"] = {mult = 1},
		["vehassault"] = {mult = 1},
		["spiderassault"] = {mult = 1},
		["jumpassault"] = {mult = 1},
		["jumpsumo"] = {mult = 1},
		["tankassault"] = {mult = 1},
		["tankheavyassault"] = {mult = 1},
		["amphassault"] = {mult = 1},
		["hoverassault"] = {mult = 1},
		["striderbantha"] = {mult = 1},
		["striderdetriment"] = {mult = 1},
		["corkrog"] = {mult = 1},
		["chickena"] = {mult = 1},
		["chickenc"] = {mult = 1},
		["chicken_tiamat"] = {mult = 1},
        
		["cloakskirm"] = {mult = 1},
		["shieldskirm"] = {mult = 1},
		["hoverskirm"] = {mult = 1},
		["amphfloater"] = {mult = 1},
		["spiderskirm"] = {mult = 1},
		["cloaksnipe"] = {mult = 1},
		["jumpskirm"] = {mult = 1},
		["chickens"] = {mult = 1},
		["chicken_sporeshooter"] = {mult = 1},
		["striderscorpion"] = {mult = 1},
        
		["spidercrabe"] = {mult = 1},
		["vehsupport"] = {mult = 1},
		["jumparty"] = {mult = 1},
		
		["cloakriot"] = {mult = 1},
		["shieldriot"] = {mult = 1},
		["vehriot"] = {mult = 1},
		["amphimpulse"] = {mult = 1},
		["amphriot"] = {mult = 1, range = 300},
		["shieldfelon"] = {mult = 1},
		["spiderriot"] = {mult = 1},
		["spideremp"] = {mult = 1},
		["tankriot"] = {mult = 1},
		["hoverriot"] = {mult = 1},
		["striderdante"] = {mult = 1},
		["chickenwurm"] = {mult = 1},
		
		["cloakarty"] = {mult = 1},
		["veharty"] = {mult = 1},
		["vehheavyarty"] = {mult = 1},
		["hoverarty"] = {mult = 1},
		["tankarty"] = {mult = 1},
		["tankheavyarty"] = {mult = 1},
		["striderarty"] = {mult = 1},
		["chickenr"] = {mult = 1},
		["chickenblobber"] = {mult = 1},
	},
	
	staticLand = {
		["turretmissile"] = {mult = 2},
		["turretlaser"] = {mult = 2},
		["turretimpulse"] = {mult = 2},
		["turretemp"] = {mult = 2},
		["turretriot"] = {mult = 2},
		["turretheavylaser"] = {mult = 2},
		["turretgauss"] = {mult = 2},
		["turretantiheavy"] = {mult = 2},
		["turretheavy"] = {mult = 2},
		["staticarty"] = {mult = 2},
	},
}

local completeUnitListNames = {

	turretAA = {
		"turretaalaser",
		"turretaaclose",
		"turretaafar",
		"turretaaflak",
		"turretaaheavy",
	},

	turret = {
		"turretmissile",
		"turretlaser",
		"turretimpulse",
		"turretemp",
		"turretriot",
		"turretheavylaser",
		"turretgauss",
		"turretantiheavy",
		"turretheavy",
	},
	
	economy = {
		"staticmex",
		"energywind",
		"energysolar",
		"energyfusion",
		"energysingu",
		"energygeo",
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
		"shieldcon",
		"vehcon",
		"tankcon",
		"spidercon",
		"jumpcon",
		"hovercon",
		"amphcon",
		"planecon",
		"gunshipcon",
		"shipcon",
	},
}

local ground = {

	raider = {
		"cloakraid",
		"cloakheavyraid",
		"shieldraid",
		"vehscout",
		"vehraid",
		"tankheavyraid",
		"tankraid",
		"spiderscout",
		"jumpraid",
		"amphraid",
		"hoverraid",
		"chicken",
		"chicken_leaper",
	},

	assault = {
		"cloakassault",
		"shieldassault",
		"vehassault",
		"spiderassault",
		"jumpassault",
		"jumpsumo",
		"tankassault",
		"tankheavyassault",
		"amphassault",
		"hoverassault",
		"striderbantha",
		"striderdetriment",
		"corkrog",
		"chickena",
		"chickenc",
		"chicken_tiamat",
	},

	skirm = {
		"cloakskirm",
		"shieldskirm",
		"hoverskirm",
		"amphfloater",
		"spiderskirm",
		"cloaksnipe",
		"jumpskirm",
		"chickens",
		"chicken_sporeshooter",
		"striderscorpion",
	},
	
	antiSkirm = {
		"spidercrabe",
		"vehsupport",
		"jumparty",
	},

	riot = {
		"cloakriot",
		"shieldriot",
		"vehriot",
		"spiderriot",
		"amphimpulse",
		"amphriot",
		"shieldfelon",
		"spiderriot",
		"spideremp",
		"tankriot",
		"hoverriot",
		"striderdante",
		"chickenwurm",
	},

	arty = {
		"cloakarty",
		"veharty",
		"vehheavyarty",
		"hoverarty",
		"tankarty",
		"tankheavyarty",
		"striderarty",
		"chickenr",
		"chickenblobber",
	},
}

local antiAir = {
	antiAir = {
		"cloakaa",
		"shieldaa",
		"vehaa",
		"tankaa",
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
		"bomberprec",
		"bomberriot",
		"bomberdisarm",
		"bomberheavy",
	},
	
	gunship = {
		"gunshipemp",
		"gunshipbomb",
		"gunshipraid",
		"gunshipskirm",
		"gunshipassault",
		"gunshipheavyskirm",
		"gunshipkrow",
	},
	
	transport = {
		"gunshiptrans",
		"gunshipheavytrans",
	},
}

local fighter = {
	fighter = {
		"planefighter",
		"planeheavyfighter",
	},
}

local economyTargetNames =  {
	["staticmex"] = {mult = 1.5},
	["energywind"] = {mult = 1},
	["energysolar"] = {mult = 0.6},
	["energyfusion"] = {mult = 1},
	["energysingu"] = {mult = 1},
	["energygeo"] = {mult = 1.5},
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
	["shieldcon"] = {mult = 1},
	["vehcon"] = {mult = 1},
	["tankcon"] = {mult = 1},
	["spidercon"] = {mult = 1},
	["jumpcon"] = {mult = 1},
	["hovercon"] = {mult = 1},
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
