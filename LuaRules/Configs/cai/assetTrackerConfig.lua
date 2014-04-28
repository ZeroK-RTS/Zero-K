local listNames = {

	antiAirTurret = {
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
		
	largeStructure = {
		"corbhmth",
		"missilesilo",
		"armbrtha",
		"armamd",
		"corsilo",
		"mahlazer",
		"zenith",
		"raveparty",
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
	
	fighter = {
		"fighter",
		"corvamp",
	},
	
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
		"corape",
		"blackdawn",
		"armbrawl",
		"corcrw",
	},
	
	transport = {
		"corvalk",
		"corbtrans",
	},
}

local HeatmapNames = {
	mobileAntiAir = {
		["armjeth"] = {mult = 1},
		["corcrash"] = {mult = 1},
		["vehaa"] = {mult = 1},
		["corsent"] = {mult = 1},
		["hoveraa"] = {mult = 1},
		["spideraa"] = {mult = 1},
		["armaak"] = {mult = 1},
		["amphaa"] = {mult = 1},
		["shipaa"] = {mult = 1},
		["gunship11"] = {mult = 1},
		
		["tawf114"] = {mult = 0.4},
		["slowmort"] = {mult = 0.4},
		["armsnipe"] = {mult = 0.4},
		["shieldfelon"] = {mult = 0.4},
	},
	
	staticAntiAir = {
		["corrl"] = {mult = 1},
		["corrazor"] = {mult = 1},
		["missiletower"] = {mult = 2},
		["armcir"] = {mult = 1.5},
		["corflak"] = {mult = 2},
		["screamer"] = {mult = 1},
		
		["corgrav"] = {mult = 1},
		["armartic"] = {mult = 1},
	},
	
	mobileLand = {
		["armpw"] = {mult = 1},
		["spherepole"] = {mult = 1},
		["corak"] = {mult = 1},
		["corfav"] = {mult = 1},
		["corgator"] = {mult = 1},
		["panther"] = {mult = 1},
		["logkoda"] = {mult = 1},
		["armflea"] = {mult = 1},
		["corpyro"] = {mult = 1},
		["amphraider3"] = {mult = 1},
		["corsh"] = {mult = 1},
		["chicken"] = {mult = 1},
		["chicken_leaper"] = {mult = 1},
        
		["armzeus"] = {mult = 1},
		["corthud"] = {mult = 1},
		["corraid"] = {mult = 1},
		["spiderassault"] = {mult = 1},
		["corcan"] = {mult = 1},
		["corsumo"] = {mult = 1},
		["correap"] = {mult = 1},
		["corgol"] = {mult = 1},
		["amphassault"] = {mult = 1},
		["hoverassault"] = {mult = 1},
		["armbanth"] = {mult = 1},
		["armorco"] = {mult = 1},
		["corkrog"] = {mult = 1},
		["chickena"] = {mult = 1},
		["chickenc"] = {mult = 1},
		["chicken_tiamat"] = {mult = 1},
        
		["armrock"] = {mult = 1},
		["corstorm"] = {mult = 1},
		["nsaclash"] = {mult = 1},
		["amphfloater"] = {mult = 1},
		["armsptk"] = {mult = 1},
		["armsnipe"] = {mult = 1},
		["slowmort"] = {mult = 1},
		["chickens"] = {mult = 1},
		["chicken_sporeshooter"] = {mult = 1},
		["scorpion"] = {mult = 1},
        
		["armcrabe"] = {mult = 1},
		["cormist"] = {mult = 1},
		["firewalker"] = {mult = 1},
		
		["armwar"] = {mult = 1},
		["cormak"] = {mult = 1},
		["corlevlr"] = {mult = 1},
		["spiderriot"] = {mult = 1},
		["amphraider2"] = {mult = 1},
		["amphriot"] = {mult = 1, range = 300},
		["shieldfelon"] = {mult = 1},
		["spiderriot"] = {mult = 1},
		["arm_venom"] = {mult = 1},
		["tawf114"] = {mult = 1},
		["hoverriot"] = {mult = 1},
		["dante"] = {mult = 1},
		["chickenwurm"] = {mult = 1},
		
		["armham"] = {mult = 1},
		["corgarp"] = {mult = 1},
		["armmerl"] = {mult = 1},
		["armmanni"] = {mult = 1},
		["cormart"] = {mult = 1},
		["trem"] = {mult = 1},
		["armraven"] = {mult = 1},
		["chickenr"] = {mult = 1},
		["chickenblobber"] = {mult = 1},
	},
	
	staticLand = {
		["corrl"] = {mult = 2},
		["corllt"] = {mult = 2},
		["corgrav"] = {mult = 2},
		["armartic"] = {mult = 2},
		["armdeva"] = {mult = 2},
		["corhlt"] = {mult = 2},
		["armpb"] = {mult = 2},
		["armanni"] = {mult = 2},
		["cordoom"] = {mult = 2},
		["corbhmth"] = {mult = 2},
	},
}

local getMovetype = Spring.Utilities.getMovetype

local function CreateListData(source)
	local retList = {}
	for category, namesList in pairs(source) do
		for i = 1, #namesList do
			local defName = namesList[i]
			local ud = UnitDefNames[defName]
			if ud then
				retList[ud.id] = {
					name = category,
					cost = ud.metalCost,
				}
			end
		end
	end
	
	for defID = 1, #UnitDefs do
		if not retList[defID] then
			local ud = UnitDefs[defID]
			
			local moveType = getMovetype(ud) 
			if moveType then
				retList[ud.id] = {
					name = "miscUnit",
					cost = ud.metalCost,
				}
			else
				retList[ud.id] = {
					name = "miscStructure",
					cost = ud.metalCost,
				}
			end
		end
	end
	return retList
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

local HeatmapUnitDefID = CreateHeatmapData(HeatmapNames)
local ListUnitDefID = CreateListData(listNames)

return HeatmapUnitDefID, ListUnitDefID