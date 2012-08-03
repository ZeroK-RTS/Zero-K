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
	"Repairing units is twice as fast as building them, but proceeds at 1/4th the normal speed if the unit has been recently damaged.",
	"Different AA types are effective against different targets. The Hacksaw missile turret is lethal against bombers, while the Cobra flak cannon cuts down gunships well.",
	"When fighting AoE weapons, spread out your units to minimize damage.",
	"You can draw on the map with tilde (~) and left mouse. ~ + double click adds a labelled point, while ~ + middle click adds a point without label. ~ + right click erases.",
	"Many commands can be issued over a whole area by keeping button the down and dragging a box or disc.",
	
	"Heavy striders are built by the Athena specops aircraft, buildable by any mobile constructor.",
	"Riot units double as improvised anti-air against most gunships.",
	"Nuclear missiles are devastating, but can be intercepted by antinuke systems which provide coverage over a wide area.",
	"Cloaked units can be revealed by close contact, or when damaged.",
	"Slow-rays and other weapons with slowing effects will reduce the target's movement and firing rate by up to 66%.",
	"Hovercraft are fast and can transverse water, but struggle on even gentle slopes.",
	"Most units have a smart Unit AI, which has them automatically kite or jink enemy units as needed on a fight order or when standing still.",
	"Spiders have excellent mobility including the ability to scale cliffs, although they tend to lack direct strength.",
	"Space-clicking on a unit or its build button in the menu brings up the \255\255\64\0Context Menu\008, where you can view unit data or access marketplace functions.",
}

unitTips = {
	corclog = {"The \255\255\64\0Dirtbag\008 leaves a mound of earth when it dies, obstructing units (especially vehicles) and weapons.", 3, 5},
	capturecar = {"The \255\255\64\0Dominatrix\008 capture vehicle can capture enemy units (with a 5 second cooldown between captures), but control is lost if the capturing Dominatrix dies.", 3, 5},
	armcrabe = {"The \255\255\64\0Crabe\008 outranges basic defenses. It curls up into armored form when stationary, becoming a formidable defense turret.", 3, 5},
	firewalker = {"The \255\255\64\0Firewalker\008 creates large clouds of fire which can seriously harm units - friend or foe - standing in them.", 3, 5},
	corsktl = {"The \255\255\64\0Skuttle\008 has a very powerful explosion with a very small blast radius. Use it to jump on enemy heavy targets and kill them in one or two blows.", 3, 5},
	
	tawf114 = {"The \255\255\64\0Banisher\008 packs a punch against groups of small units, but can be easily rushed - make sure to screen it.", 3, 4},
	armmanni = {"The \255\255\64\0Penetrator\008 can split many units apart in one shot, but has no AoE and a 20s reload time, and is itself very flimsy. Use it for pinpoint fire from a distance.", 3, 4},
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
	"striderhub",
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
	"zenith",
	"raveparty",
}

needPowerDefs = {
	"armanni",
	"corbhmth",
	"cordoom",
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
needPower = {}

for i=1,#UnitDefs do
	if UnitDefs[i].customParams.commtype then commander[i]=true
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
CreateArray(needPowerDefs, needPower)
