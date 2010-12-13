local THRESHOLD_EXPENSIVE = 800

--seconds
TIMER_EXPENSIVE_UNITS = 60 * 10
TIMER_ADV_FACTORY = 60 * 15
TIMER_SUPERWEAPON = 60 * 30

stringExpensiveUnits = "That <name> is particularly expensive; at this point, cheaper units offer far more flexibility. You should probably save that for later."
stringAdvFactory = "That <name> is difficult to use and inflexible early game; you should start with a more basic factory."
stringSuperweapon = "Superweapons such as that <name> are meant for resolving late-game stalemates when no other options remain. This is NOT the time to be building one!"

stringAirSpotted = "\255\255\0\0Enemy aircraft spotted.\008 Now might be a good time to invest in some anti-air."
stringNukeSpotted = "\255\255\0\0Enemy nuclear silo located.\008 Build an anti-nuke launcher while you still can."

generalTips = {
	"Use the priority buttons to maximize your efficiency during stalls (expenditure outstripping income). Resources will be allocated to high priority units before low priority ones.",
	"Repairing units is 3x faster than building them, but proceeds at 1/6th the normal speed if the unit has been recently damaged.",
	"Different AA types are effective against different targets. The Hacksaw missile turret is lethal against bombers, while the Cobra flak cannon cuts down gunships well.",
	"When fighting AoE weapons, spread out your units to minimize damage.",
	"You can draw on the map with tilde (~) and left mouse. ~ + double click adds a labelled point, while ~ + middle click adds a point without label. ~ + right click erases.",
	"Many commands can be issued over a whole area by keeping button the down and dragging a box or disc.",
	"The Dreamweaver capture vehicle can capture a single enemy unit, but control is lost if the capturing Dreamweaver dies.",
	"Heavy striders are built by the Athena specops aircraft, buildable by any mobile constructor.",
	"Riot units double as improvised anti-air against most gunships.",
	"Nuclear missiles are devastating, but can be intercepted by antinuke systems which provide coverage over a wide area.",
	"Cloaked units can be revealed by close contact, or when damaged.",
	"Slow-rays and other weapons with slowing effects will reduce the target's movement and firing rate by up to 66%.",
	"Hovercraft are fast and can transverse water, but struggle on even gentle slopes.",
	"Spiders have excellent mobility including the ability to scale cliffs, although they tend to lack direct strength.",
}

raiderDefs = {
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

assaultDefs = {
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

skirmDefs = {
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

riotDefs = {
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

artyDefs = {
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

bomberDefs = {
	"corshad",
	"corhurc2",
	"armstiletto_laser",
	"armcybr",
}

conDefs = {
	"armrectr",
	"cornecro",
	"arm_weaver",
	"corfast",
	"corned",
	"coracv",
	"corch",
	"armca",
	"corcs",
}

mexDefs = {"cormex"}

energyDefs = {
	"armsolar",
	"armwin",
	"armfus",
	"geo",
	"cafus",
}

factoryDefs = {
	"corsy",
}

advFactoryDefs = {
	"factoryspider",
	"factoryjump",
	"factorytank",
}

airFactoryDefs = {
	"factoryplane",
	"factorygunship",
}

superweaponDefs = {
	"armbrtha",
	"corsilo",
	"mahlazer",
}

for name in pairs(UnitDefNames) do
	if string.find(name, "factory") then factoryDefs[#factoryDefs+1] = name end
end

--unitDefID-indexed versions
raider = {}
assault = {}
skirm = {}
riot = {}
arty = {}
bomber = {}
con = {}
mex = {}
energy = {}
factory = {}
commander = {}
expensive_unit = {}
adv_factory = {}
air_factory = {}
superweapon = {}

for i=1,#UnitDefs do
	if UnitDefs[i].isCommander then commander[i]=true
	elseif UnitDefs[i].metalCost > THRESHOLD_EXPENSIVE then expensive_unit[i] = true end
end

local function CreateArray(source, target)
	for i=1, #source do
		local def = UnitDefNames[source[i]]
		if def then target[def.id] = true end
	end
end

CreateArray(raiderDefs, raider)
CreateArray(assaultDefs, assault)
CreateArray(skirmDefs, skirm)
CreateArray(riotDefs, riot)
CreateArray(artyDefs, arty)
CreateArray(bomberDefs, bomber)
CreateArray(conDefs, con)

CreateArray(mexDefs, mex)
CreateArray(energyDefs, energy)
CreateArray(factoryDefs, factory)
CreateArray(advFactoryDefs, adv_factory)
CreateArray(airFactoryDefs, air_factory)
CreateArray(superweaponDefs, superweapon)
