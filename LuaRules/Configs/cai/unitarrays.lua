local raider = {
	"cloakraid",
	"cloakheavyraid",
	"shieldraid",
	"armflash",
	"vehscout",
	"vehraid",
	"amphraid",
	
	"jumpraid",
	"tankheavyraid",
	"tankraid",
	
	"armsh",
	"hoverraid",
	
	"chicken",
	"chicken_leaper",
}

local assault = {
	"shieldassault",
	"vehassault",
	
	"cloakassault",
	--"spidercrabe",
	"spiderassault",
	"jumpassault",
	--"jumpsumo",
	"armbull",
	"tankassault",
	"tankheavyassault",
	"amphassault",
	
	"armanac",
	"hoverassault",
	
	--"striderbantha",
	--"striderdetriment",
	--"corkrog",
	
	--"chickena",
	--"chickenc",
	--"chicken_tiamat",
}

local skirm = {
	"cloakskirm",
	"shieldskirm",
	"armjanus",
	"armstump",
	"amphfloater",
	
	"spiderskirm",
	"cloaksnipe",
	"cormort",
	"jumpskirm",
	"cormortgold",
	"hoverarty",
	
	"hoverskirm",
	
	"chickens",
	"chicken_sporeshooter",
	--"striderscorpion",
}

local jumper = { -- uses jump for offense. IE do not put commander or AA here.
	"jumpassault",
	"jumpsumo",
}

local riot = {
	"cloakriot",
	"shieldriot",
	"vehriot",
	"spiderriot",
	"amphimpulse",
	"amphriot",
	
	"spideremp",
	"tawf003",
	"tankriot",

	"hoverriot",
	
	"armraz",
	"striderdante",
	
	"chickenwurm",
}

local arty = {
	"cloakarty",
	"punisher",
	"jumparty",
	"tawf013",
	"veharty",
	
	"vehheavyarty",
	--"hoverarty",
	"tankarty",
	"tankheavyarty",
	
	"armshock",
	"striderarty",
	
	"hoverartillery",
	
	"chickenr",
	"chickenblobber",
}

local counteredByAssaults = {
	"jumpscout",
	"vehsupport",
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
