local raider = {
	"cloakraid",
	"spherepole",
	"corak",
	"armflash",
	"corfav",
	"corgator",
	"amphraid",
	
	"corpyro",
	"panther",
	"logkoda",
	
	"armsh",
	"corsh",
	
	"chicken",
	"chicken_leaper",
}

local assault = {
	"corthud",
	"corraid",
	
	"cloakassault",
	--"spidercrabe",
	"spiderassault",
	"corcan",
	--"corsumo",
	"armbull",
	"correap",
	"corgol",
	"amphassault",
	
	"armanac",
	"hoverassault",
	
	--"bantha",
	--"detriment",
	--"corkrog",
	
	--"chickena",
	--"chickenc",
	--"chicken_tiamat",
}

local skirm = {
	"cloakskirm",
	"corstorm",
	"armjanus",
	"armstump",
	"amphfloater",
	
	"spiderskirm",
	"cloaksnipe",
	"cormort",
	"slowmort",
	"cormortgold",
	"hoverarty",
	
	"nsaclash",
	
	"chickens",
	"chicken_sporeshooter",
	--"scorpion",
}

local jumper = { -- uses jump for offense. IE do not put commander or AA here.
	"corcan",
	"corsumo",
}

local riot = {
	"armwar",
	"cormak",
	"corlevlr",
	"spiderriot",
	"amphimpulse",
	"amphriot",
	
	"spideremp",
	"tawf003",
	"tawf114",

	"hoverriot",
	
	"armraz",
	"dante",
	
	"chickenwurm",
}

local arty = {
	"cloakarty",
	"punisher",
	"firewalker",
	"tawf013",
	"corgarp",
	
	"vehheavyarty",
	--"hoverarty",
	"cormart",
	"trem",
	
	"armshock",
	"striderarty",
	
	"hoverartillery",
	
	"chickenr",
	"chickenblobber",
}

local counteredByAssaults = {
	"puppy",
	"cormist",
}

local prioritySos = {
	"energyfusion",
	"energysingu",
	"factoryshield",
    "factorycloak",
    "factoryveh",
    "factoryplane",
    "factorygunship",
    "factoryhover",
    "factoryspider",
    "factoryjump",
    "factorytank",
    "factoryship",
	"dyntrainer_recon_base",
	"dyntrainer_support_base",
	"dyntrainer_assault_base",
	"dyntrainer_strike_base",
	"comm_trainer_strike_0",
	"armcom1",
	"corcom1",
	"commrecon1",
	"commsupport1",
	"benzcom1",
	"cremcom1",
}

--global versions
raiderArray = {}
assaultArray = {}
jumperArray = {}
skirmArray = {}
riotArray = {}
artyArray = {}
counteredByAssaultsArray = {}
prioritySosArray = {}

local function CreateArray(source, target)
	for i=1, #source do
		local def = UnitDefNames[source[i]]
		if def then target[def.id] = true end
	end
end

CreateArray(raider, raiderArray)
CreateArray(assault, assaultArray)
CreateArray(jumper, jumperArray)
CreateArray(skirm, skirmArray)
CreateArray(riot, riotArray)
CreateArray(arty, artyArray)
CreateArray(counteredByAssaults, counteredByAssaultsArray)
CreateArray(prioritySos, prioritySosArray)
