local raider = {
	"armpw",
	"spherepole",
	"corak",
	"armflash",
	"corfav",
	"corgator",
	
	"armfast",
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
	"armstump",
	"corraid",
	
	"armzeus",
	--"armcrabe",
	"corcan",
	--"corsumo",
	"armbull",
	"correap",
	--"corgol",
	
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
	
	"armsptk",
	"armsnipe",
	"cormort",
	"armmanni",
	
	"nsaclash",
	
	"chickens",
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
	"corkarg",
}

local arty = {
	"armham",
	"punisher",
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

--global versions
raiderArray = {}
assaultArray = {}
skirmArray = {}
riotArray = {}
artyArray = {}

for i=1, #raider do
	local id = UnitDefNames[raider[i]].id
	raiderArray[id] = true
end

for i=1, #assault do
	local id = UnitDefNames[assault[i]].id
	assaultArray[id] = true
end

for i=1, #skirm do
	local id = UnitDefNames[skirm[i]].id
	skirmArray[id] = true
end

for i=1, #riot do
	local id = UnitDefNames[riot[i]].id
	riotArray[id] = true
end

for i=1, #arty do
	local id = UnitDefNames[arty[i]].id
	artyArray[id] = true
end

