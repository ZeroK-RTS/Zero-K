local raider = {
	"armpw",
	"spherepole",
	"corak",
	"armflash",
	"corfav",
	"corgator",
	
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
	
	"armzeus",
	--"armcrabe",
	"spiderassault",
	"corcan",
	--"corsumo",
	"armbull",
	"correap",
	"corgol",
	
	"armanac",
	"hoverassault",
	
	--"armbanth",
	--"armorco",
	--"corkrog",
	
	--"chickena",
	--"chickenc",
	--"chicken_tiamat",
}

local skirm = {
	"armrock",
	"corstorm",
	"armjanus",
	"armstump",
	
	"armsptk",
	"armsnipe",
	"cormort",
	"slowmort",
	"cormortgold",
	"armmanni",
	
	"nsaclash",
	
	"chickens",
}

local jumper = { -- uses jump for offense. IE do not put commander or AA here.
	"corpyro",
	"corcan",
	"corsumo",
}

local riot = {
	"armwar",
	"cormak",
	"corlevlr",
	
	"arm_venom",
	"tawf003",
	"tawf114",

	"hoverriot",
	
	"armraz",
	"dante",
}

local arty = {
	"armham",
	"punisher",
	"firewalker",
	"tawf013",
	"corgarp",
	
	"armmerl",
	--"armmanni",
	"cormart",
	"trem",
	
	"armshock",
	"armraven",
	
	"hoverartillery",
	
	"chickenr",
	"chickenblobber",
}

local counteredByAssaults = {
	"puppy",
	"cormist",
}

local prioritySos = {
	"armfus",
	"cafus",
	"factoryshield",
    "factorycloak",
    "factoryveh",
    "factoryplane",
    "factorygunship",
    "factoryhover",
    "factoryspider",
    "factoryjump",
    "factorytank",
    "corsy",
	"armcom",
	"corcom",
	"commrecon",
	"commsupport",
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
