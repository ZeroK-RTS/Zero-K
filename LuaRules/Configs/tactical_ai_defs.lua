--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Union(t1, t2)
	local ret = {}
	for i, v in pairs(t1) do
		ret[i] = v
	end
	for i, v in pairs(t2) do
		ret[i] = v
	end
	return ret
end

local function NameToDefID(nameTable)
	local defTable = {}
	for _,unitName in pairs(nameTable) do
		local ud = UnitDefNames[unitName]
		if ud then
			defTable[ud.id] = true
		end
	end
	return defTable
end

local function SetMinus(set, exclusion)
	local copy = {}
	for i,v in pairs(set) do
		if not exclusion[i] then
			copy[i] = v
		end
	end
	
	return copy
end

-- general arrays
local allGround = {}
local armedLand = {}
local unarmedLand = {}

for name,data in pairs(UnitDefNames) do
	if not data.canfly then
		allGround[data.id] = true
		if data.canAttack and data.weapons[1] and data.weapons[1].onlyTargets.land then
			armedLand[data.id] = true
		else
			unarmedLand[data.id] = true
		end
	end
end


for name,data in pairs(UnitDefNames) do
	if data.canAttack and (not data.canfly) 
	and data.weapons[1] and data.weapons[1].onlyTargets.land then
		armedLand[data.id] = true 
	end
end

-- swarm arrays
-- these are not strictly required they just help with inputting the units

local longRangeSwarmieeArray = NameToDefID({ 
	"cormart",
	"firewalker",
	"armsptk",
	"corstorm",
	"shiparty",
	"armham",
	
	"a_shipcruiser",
})

local medRangeSwarmieeArray = NameToDefID({ 
	"armrock",
	"amphfloater",
	"chickens",
	
	"a_shipmissile",
})

local lowRangeSwarmieeArray = NameToDefID({
	"corthud",
	"spiderassault",
	"corraid",
	"armzeus",
	"logkoda",
	"hoverassault",
	
	"correap",
	"corgol",
	
	"armcrabe",
	"armmanni",
	
	"chickenr",
	"chickenblobber",
	"armsnipe", -- only worth swarming sniper at low range, too accurate otherwise.
})

medRangeSwarmieeArray = Union(medRangeSwarmieeArray,longRangeSwarmieeArray)
lowRangeSwarmieeArray = Union(lowRangeSwarmieeArray,medRangeSwarmieeArray)

-- skirm arrays
-- these are not strictly required they just help with inputting the units
local scorcherSkirmieeArray = NameToDefID({
	"armtick",
	"corroach",
	"puppy",
	"corsktl",
	"spherepole",
	"armpw",
	"corak",
	"corcan",
	"hoverdepthcharge",
	"armestor", -- scorchers tend to get blown up on pylons
	
	"chicken",
	"chickena",
	"chicken_tiamat",
	"chicken_dragon"
})

local veryShortRangeSkirmieeArray = NameToDefID({
	"corclog",
	"corcan",
	"spherepole",
	"armtick",
	"puppy",
	"corroach",
	"chicken",
	"chickena",
	"chicken_tiamat",
	"chicken_dragon",
	"hoverdepthcharge",
	
	"corgator",
	"armflea",
	"armpw",
	"corfav",
})

local shortRangeSkirmieeArray = NameToDefID({
	"corpyro",
	"logkoda",
	"amphraider3",
	"corsumo",
	
	"corsktl",
	"corak",
})

local riotRangeSkirmieeArray = NameToDefID({
	"panther",
	"armwar",
	"corsh",
	"hoverscout",
	"shipscout",
	"shipraider",
	"subraider",
	"amphriot",
	"armcomdgun",
	"dante",
	
	"armjeth",
	"corcrash",
	"armaak",
	"hoveraa",
	"spideraa",
	"amphaa",
	"shipaa",
	
	"armrectr",
	"cornecro",
	"corned",
	"corch",
	"coracv",
	"arm_spider",
	"corfast",
	"amphcon",
	"shipcon",
	
	"spherecloaker",
	"core_spectre",
	
	"a_shiptorpbt",
	"a_shipscout",
})

local lowMedRangeSkirmieeArray = NameToDefID({
	"armcom",
	"armadvcom",

	"armwar",
	"hoverassault",
	"arm_venom",
	
	"cormak",
	"corthud",
	"corraid",
	
	"a_shipcorvette",
})

local medRangeSkirmieeArray = NameToDefID({
	"corcom",
	"coradvcom",
	"commsupport",
	"commadvsupport",
	
	"spiderriot",
	"armzeus",
	"amphraider2",
	
	"spiderassault",
	"corlevlr",
	
	"hoverriot",
    "shieldfelon",

	"correap",
	"corgol",
	"tawf114", -- banisher
	"scorpion",
	
	"armfus", -- don't suicide vs fusions if possible.
	"cafus", -- same with singu, at least to make an effort for survival.
	"armbanth", -- banthas also have a fairly heavy but dodgeable explosion.
	
	"a_shipdestroyer",
})

for name, data in pairs(UnitDefNames) do -- add all comms and facs to mid range skirm, so units avoid their death explosions.
	if data.customParams.commtype or string.match(name, "factory") or string.match(name, "hub") then
		medRangeSkirmieeArray[data.id] = true
	end
end

local longRangeSkirmieeArray = NameToDefID({
	"armrock",
	"slowmort",
	"amphfloater",
	"nsclash", -- hover janus
	"capturecar",
	"chickenc",
	"armbanth",
	"gorg",
	"corllt",
	"armdeva",
	"armartic",
	
	
})

local artyRangeSkirmieeArray = NameToDefID({
	"shipskirm",
	"armsptk",
	"corstorm",
	"cormist",
	"amphassault",
	"chicken_sporeshooter",
	"corrl",
	"corhlt",
	"armpb",
	"cordoom",
	"armorco",
	"amphartillery",
	
	"a_shipmissile",
})

local slasherSkirmieeArray = NameToDefID({
	"corsumo",
	"dante",
	"armwar",
	"hoverassault",
	"cormak",
	"corthud",
	"spiderriot",
	"armzeus",
	"spiderassault",
	"corraid",
	"corlevlr",
	"hoverriot",
    "shieldfelon",
	"correap",
	"armrock",
})

local fleaSkirmieeArray = Union(veryShortRangeSkirmieeArray, unarmedLand)
shortRangeSkirmieeArray = Union(shortRangeSkirmieeArray,veryShortRangeSkirmieeArray)
riotRangeSkirmieeArray = Union(riotRangeSkirmieeArray,shortRangeSkirmieeArray)
lowMedRangeSkirmieeArray = Union(lowMedRangeSkirmieeArray, riotRangeSkirmieeArray)
medRangeSkirmieeArray = Union(medRangeSkirmieeArray, lowMedRangeSkirmieeArray)
longRangeSkirmieeArray = Union(longRangeSkirmieeArray,medRangeSkirmieeArray)
artyRangeSkirmieeArray = Union(artyRangeSkirmieeArray,longRangeSkirmieeArray)

-- Stuff that mobile AA skirms

local skirmableAir = NameToDefID({
	"blastwing",
	"bladew",
	"armkam",
	"gunshipsupport",
	"armbrawl",
	"blackdawn",
	"corbtrans",
	"corcrw",
})

-- Brawler, for AA to swarm.
local brawler = NameToDefID({
	"armbrawl",
})

-- Things that are fled by some things
local fleeables = NameToDefID({
	"corllt",
	"armdeva",
	"armartic",
	"corgrav",
	
	"armcom",
	"armadvcom",
	"corcom",
	"coradvcom",
	
	"armwar",
	"armzeus",
	
	"arm_venom",
	"spiderriot",
	
	"cormak",
	
	"corlevlr",
	"capturecar",

	"hoverriot", -- mumbo
    "shieldfelon",
	"corsumo",
})

-- scorcher dive list
local scorcherSwarmieeArray = SetMinus(allGround, scorcherSkirmieeArray)

-- waterline(defaults to 0): Water level at which the unit switches between land and sea behaviour
-- sea: table of behaviour for sea. Note that these tables are optional.
-- land: table of behaviour for land 

-- weaponNum(defaults to 1): Weapon to use when skirming
-- searchRange(defaults to 800): max range of GetNearestEnemy for the unit.
-- defaultAIState (defaults in config): (1 or 0) state of AI when unit is initialised

--*** skirms(defaults to empty): the table of units that this unit will attempt to keep at max range
-- skirmEverything (defaults to false): Skirms everything (does not skirm radar with this enabled only)
-- skirmLeeway (defaults to 0): (Weapon range - skirmLeeway) = distance that the unit will try to keep from units while skirming
-- stoppingDistance (defaults to 0): (skirmLeeway - stoppingDistance) = max distance from target unit that move commands can be given while skirming
-- skirmRadar (defaults to false): Skirms radar dots
-- skirmOnlyNearEnemyRange (defaults to false): If true, skirms only when the enemy unit is withing enemyRange + skirmOnlyNearEnemyRange
-- skirmOrderDis (defaults in config): max distance the move order is from the unit when skirming
-- skirmKeepOrder (defaults to false): If true the unit does not clear its move order when too far away from the unit it is skirming.
-- velocityPrediction (defaults in config): number of frames of enemy velocity prediction for skirming and fleeing

--*** swarms(defaults to empty): the table of units that this unit will jink towards and strafe
-- maxSwarmLeeway (defaults to Weapon range): (Weapon range - maxSwarmLeeway) = Max range that the unit will begin strafing targets while swarming
-- minSwarmLeeway (defaults to Weapon range): (Weapon range - minSwarmLeeway) = Range that the unit will attempt to move further away from the target while swarming
-- jinkTangentLength (default in config): component of jink vector tangent to direction to enemy
-- jinkParallelLength (default in config): component of jink vector parallel to direction to enemy
-- circleStrafe (defaults to false): when set to true the unit will run all around the target unit, false will cause the unit to jink back and forth
-- minCircleStrafeDistance (default in config): (weapon range - minCircleStrafeDistance) = distance at which the circle strafer will attempt to move away from target
-- strafeOrderLength (default in config): length of move order while strafing
-- swarmLeeway (defaults to 50): adds to enemy range when swarming
-- swarmEnemyDefaultRange (defaults to 800): range of the enemy used if it cannot be seen.
-- alwaysJinkFight (defaults to false): If enabled the unit with jink whenever it has a fight command
-- localJinkOrder (defaults in config): Causes move commands to be given near the unit, otherwise given next to opponent

--*** flees(defaults to empty): the table of units that this unit will flee like the coward it is!!!
-- fleeCombat (defaults to false): if true will flee everything without catergory UNARMED
-- fleeLeeway (defaults to 100): adds to enemy range when fleeing
-- fleeDistance (defaults to 100): unit will flee to enemy range + fleeDistance away from enemy
-- fleeRadar (defaults to false): does the unit flee radar dots?
-- minFleeRange (defaults to 0): minumun range at which the unit will flee, will flee at higher range if the attacking unit outranges it
-- fleeOrderDis (defaults to 120): max distance the move order is from the unit when fleeing


--- Array loaded into gadget 
local behaviourDefaults = {
	defaultState = 1,
	defaultJinkTangentLength = 80,
	defaultJinkParallelLength = 200,
	defaultStrafeOrderLength = 100,
	defaultMinCircleStrafeDistance = 40,
    defaultLocalJinkOrder = true,
	defaultSkirmOrderDis = 120,
	defaultVelocityPrediction = 30,
}

local behaviourConfig = { 
	-- swarmers
	["armtick"] = {
		skirms = {}, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		jinkTangentLength = 100, 
		minCircleStrafeDistance = 0,
		minSwarmLeeway = 100,
		swarmLeeway = 30,
		alwaysJinkFight = true,		
	},
	
	["corroach"] = {
		skirms = {}, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		jinkTangentLength = 100, 
		minCircleStrafeDistance = 0,
		minSwarmLeeway = 100,
		swarmLeeway = 30, 
		alwaysJinkFight = true,	
	},
	
	["puppy"] = {
		skirms = {}, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		localJinkOrder = false,
		circleStrafe = true,
		minCircleStrafeDistance = 170,
		maxSwarmLeeway = 170, 
		jinkTangentLength = 100,
		minSwarmLeeway = 100,
		swarmLeeway = 200, 
	},
  
	["armpw"] = {
		skirms = veryShortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 35, 
		swarmLeeway = 50, 
		skirmLeeway = 10,
		jinkTangentLength = 140, 
		stoppingDistance = 10,
	},
	
	["armflea"] = {
		skirms = fleaSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = fleeables,
		circleStrafe = true,
		skirmLeeway = 5,
		maxSwarmLeeway = 5, 
		swarmLeeway = 30,
		stoppingDistance = 0,
		strafeOrderLength = 100,
		minCircleStrafeDistance = 20,
		fleeLeeway = 150,
		fleeDistance = 150,
	},
	["corfav"] = { -- weasel
		skirms = veryShortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = fleeables,
		circleStrafe = true, 
		strafeOrderLength = 180,
		maxSwarmLeeway = 40, 
		swarmLeeway = 40, 
		stoppingDistance = 15,
		minCircleStrafeDistance = 50,
		fleeLeeway = 100,
		fleeDistance = 150,
	},
  
	-- longer ranged swarmers
	["corak"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 35, 
		swarmLeeway = 30, 
		jinkTangentLength = 140, 
		stoppingDistance = 10,
		minCircleStrafeDistance = 10,
		velocityPrediction = 30,
	},
	
	["amphraider3"] = {
		waterline = -5,
		land = {
			weaponNum = 1,
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 35, 
		swarmLeeway = 30, 
		jinkTangentLength = 140, 
		stoppingDistance = 25,
		minCircleStrafeDistance = 10,
		velocityPrediction = 30,
		},
		sea = {
			weaponNum = 2,
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 35, 
		swarmLeeway = 30, 
		jinkTangentLength = 140, 
		stoppingDistance = 25,
		minCircleStrafeDistance = 10,
		velocityPrediction = 30,
		},
	},
	
	["corgator"] = {
		skirms = scorcherSkirmieeArray,
		swarms = scorcherSwarmieeArray, 
		flees = {},
		localJinkOrder = false,
		jinkTangentLength = 50,
		circleStrafe = true,
		strafeOrderLength = 100,
		minCircleStrafeDistance = 260,
		maxSwarmLeeway = 0,
		minSwarmLeeway = 100,
		swarmLeeway = 300,
		skirmLeeway = 10,
		stoppingDistance = 8,
	},
	
	["hoverscout"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		strafeOrderLength = 180,
		maxSwarmLeeway = 40, 
		swarmLeeway = 40, 
		stoppingDistance = 8,
		skirmOrderDis = 150,
	},
	
	["corsh"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		strafeOrderLength = 180,
		maxSwarmLeeway = 40, 
		swarmLeeway = 40, 
		stoppingDistance = 8,
		skirmOrderDis = 150,
	},
  
	["corpyro"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 100, 
		minSwarmLeeway = 200, 
		swarmLeeway = 30, 
		stoppingDistance = 8,
		velocityPrediction = 20
	},
	
	["logkoda"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		swarmLeeway = 30, 
		stoppingDistance = 8,
		skirmOrderDis = 150,
	},
  
	["panther"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		strafeOrderLength = 180,
		maxSwarmLeeway = 40, 
		swarmLeeway = 50, 
		stoppingDistance = 15,
		skirmOrderDis = 150,
	},

	["shipscout"] = { -- scout boat
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		swarmLeeway = 30, 
		stoppingDistance = 8
	},
	["amphraider2"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true,
		maxSwarmLeeway = 40,
		skirmLeeway = 30, 
		minCircleStrafeDistance = 10,
		velocityPrediction = 20
	},
	
	["a_shipscout"] = { -- scout boat
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		swarmLeeway = 30, 
		stoppingDistance = 8
	},
	
	["a_shiptorpbt"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		swarmLeeway = 30, 
		stoppingDistance = 8
	},
	
	["a_shipcorvette"] = {
		skirms = {}, 
		swarms = allGround, 
		flees = {},
		
		localJinkOrder = false,
		jinkTangentLength = 25,
		circleStrafe = true,
		strafeOrderLength = 100,
		minCircleStrafeDistance = 250,
		maxSwarmLeeway = 0,
		minSwarmLeeway = 100,
		swarmLeeway = 300,
		skirmLeeway = 10,
		stoppingDistance = 8,
		
		--maxSwarmLeeway = 30, 
		--minSwarmLeeway = 90, 
		--skirmLeeway = 60, 
	},
	
	-- riots
	["armwar"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = 20, 
		velocityPrediction = 20
	},
	["spiderriot"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = 0, 
		velocityPrediction = 20
	},
	["arm_venom"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true,
		maxSwarmLeeway = 40,
		skirmLeeway = 30, 
		minCircleStrafeDistance = 10,
		velocityPrediction = 20
	},
	["cormak"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = 50, 
		velocityPrediction = 20
	},
	["corlevlr"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = -30, 
		stoppingDistance = 5
	},
	
    ["shieldfelon"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = 50, 
		stoppingDistance = 5
	},
	
	["hoverriot"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = -30,
		stoppingDistance = 5
	},
	["tawf114"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = -30, 
		stoppingDistance = 10
	},
	["amphriot"] = {
		waterline = -5,
		land = {
			weaponNum = 1,
			skirms = riotRangeSkirmieeArray, 
			swarms = {}, 
			flees = {},
			circleStrafe = true,
			maxSwarmLeeway = 40,
			skirmLeeway = 30, 
			minCircleStrafeDistance = 10,
		},
		sea = {
			weaponNum = 2,
			skirms = riotRangeSkirmieeArray, 
			swarms = {}, 
			flees = {},
			circleStrafe = true,
			maxSwarmLeeway = 40,
			skirmLeeway = 30, 
			minCircleStrafeDistance = 10,
		},
	},
	
	["amphartillery"] = {
		waterline = -5,
		land = {
			weaponNum = 1,
			skirms = artyRangeSkirmieeArray, 
			swarms = {}, 
			flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 40, 
		},
		sea = {
			weaponNum = 2,
			skirms = medRangeSkirmieeArray, 
			swarms = {}, 
			flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 40, 
		},
	},
	["a_shipdestroyer"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = -30, 
		stoppingDistance = 5
	},
		
	--assaults
	["armzeus"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 90, 
		skirmLeeway = 20, 
	},
	["corthud"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 50, 
		minSwarmLeeway = 120, 
		skirmLeeway = 40, 
	},
	["spiderassault"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 50, 
		minSwarmLeeway = 120, 
		skirmLeeway = 40, 
	},
	
	["shipraider"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 90, 
		skirmLeeway = 60, 
	},

	["corraid"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 50, 
		minSwarmLeeway = 120, 
		skirmLeeway = 40, 
	},		
	
	["a_shipdestroyer"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = -30, 
		stoppingDistance = 5
	},
	
	-- med range skirms
	["armrock"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["slowmort"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 20, 
	},
	["dante"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		skirmLeeway = 40, 
	},
	["amphfloater"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["nsaclash"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 30,
		skirmOrderDis = 200,
		velocityPrediction = 90,
	},
	["shiptorp"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 0,
		stoppingDistance = -40,
		skirmOrderDis = 250,
		velocityPrediction = 40,
	},
	["gunshipsupport"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
	},
	["corcrw"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		skirmLeeway = 30, 
	},
	
	-- long range skirms
	["jumpblackhole"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 20, 
	},
	["corstorm"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["armsptk"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["amphassault"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 20, 
	},
	["corcrw"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 20, 
	},
	["capturecar"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 30,
		skirmOrderDis = 200,
		velocityPrediction = 60,
	},
	["a_shipmissile"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	
	
	-- weird stuff
	["cormist"] = {
		defaultAIState = 0,
		skirms = slasherSkirmieeArray, 
		swarms = {}, 
		flees = {},
		skirmLeeway = -400, 
		skirmOrderDis = 700,
		skirmKeepOrder = true,
		velocityPrediction = 10,
		skirmOnlyNearEnemyRange = 80
	},
	
	-- arty range skirms
	["armsnipe"] = {
		skirms = allGround,
		skirmRadar = true,
		swarms = {}, 
		flees = {},
		skirmLeeway = 50,
	},
	
	["corgarp"] = {
		skirms = allGround,
		skirmRadar = true,
		swarms = {}, 
		flees = {},
		skirmLeeway = 50, 
	},
	
	["armmerl"] = {
		skirms = allGround,
		skirmRadar = true, 
		swarms = {}, 
		flees = {},
		skirmLeeway = 400, 
	},
	
	["cormart"] = {
		skirms = allGround,
		skirmRadar = true,
		swarms = {}, 
		flees = {},
		skirmLeeway = 50, 
	},
	
	["armraven"] = {
		skirms = allGround,
		skirmRadar = true,
		swarms = {}, 
		flees = {},
		skirmLeeway = 100, 
	},
	
	["armham"] = {
		skirms = allGround, 
		swarms = {}, 
		flees = {},
		skirmRadar = true,
		skirmLeeway = 40, 
	},
	--["subarty"] = {
	--	skirms = artyRangeSkirmieeArray, 
	--	swarms = {}, 
	--	flees = {},
	--	skirmRadar = true,
	--	maxSwarmLeeway = 10, 
	--	minSwarmLeeway = 130, 
	--	skirmLeeway = 80, 
	--	skirmOrderDis = 250,
	--	velocityPrediction = 40,
	--},
	["shiparty"] = {
		skirms = artyRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 40, 
	},
	["firewalker"] = {
		skirms = allGround, 
		swarms = {}, 
		flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 20, 
	},	
	["shieldarty"] = {
		skirms = Union(artyRangeSkirmieeArray, skirmableAir),
		swarms = {},
		flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 150, 
	},	
	["armmanni"] = {
		skirms = allGround, 
		swarms = {}, 
		flees = {},
		skirmRadar = true,
		skirmLeeway = 200, 
	},	
	["armbanth"] = {
		skirms = allGround, 
		swarms = {}, 
		flees = {},
		skirmRadar = true,
		skirmLeeway = 120, 
	},	
	["a_shipcruiser"] = {
		skirms = artyRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 40, 
	},
	
	-- cowardly support units
	--[[
	["example"] = {
		skirms = {}, 
		swarms = {}, 
		flees = {},
		fleeCombat = true,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
	},
	--]]

	-- support
	["spherecloaker"] = {
		skirms = {}, 
		swarms = {}, 
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 400,
	},
	
	["core_spectre"] = {
		skirms = {}, 
		swarms = {}, 
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 450,
	},
	
	-- mobile AA
	["armjeth"] = {
		skirms = skirmableAir, 
		swarms = brawler, 
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
        skirmLeeway = 150,
		swarmLeeway = 250,
		minSwarmLeeway = 300,
		maxSwarmLeeway = 200,
	},
	["corcrash"] = {
		skirms = skirmableAir, 
		swarms = brawler, 
		flees = armedLand,
		minSwarmLeeway = 500,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
        skirmLeeway = 50, 
	},
	["vehaa"] = {
		skirms = skirmableAir, 
		swarms = brawler, 
		flees = armedLand,
		minSwarmLeeway = 100,
		strafeOrderLength = 180,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
        skirmLeeway = 50, 
	},
	["armaak"] = {
		skirms = skirmableAir, 
		swarms = brawler, 
		flees = armedLand,
		minSwarmLeeway = 300,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
        skirmLeeway = 50, 
	},
	["hoveraa"] = {
		skirms = skirmableAir, 
		swarms = brawler, 
		flees = armedLand,
		minSwarmLeeway = 100,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
        skirmLeeway = 50,
		skirmOrderDis = 200,
	},
	["spideraa"] = {
		skirms = skirmableAir, 
		swarms = brawler, 
		flees = armedLand,
		minSwarmLeeway = 300,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
        skirmLeeway = 50, 
	},
	["corsent"] = {
		skirms = skirmableAir, 
		swarms = brawler, 
		flees = armedLand,
		minSwarmLeeway = 100,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
        skirmLeeway = 50,
		skirmOrderDis = 200, 
	},
	["amphaa"] = {
		skirms = skirmableAir,
		swarms = brawler, 
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
        skirmLeeway = 50,
		skirmOrderDis = 200, 
	},
	["shipaa"] = {
		skirms = skirmableAir, 
		swarms = brawler, 
		flees = armedLand,
		minSwarmLeeway = 100,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
        skirmLeeway = 50,
		skirmOrderDis = 200, 
	},
	["gunshipaa"] = {
		skirms = skirmableAir, 
		swarms = brawler, 
		flees = armedLand,
		minSwarmLeeway = 100,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
        skirmLeeway = 50,
		skirmOrderDis = 200, 
	},
	["a_shipaa"] = {
		skirms = artyRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 40, 
	},
}

return behaviourConfig, behaviourDefaults

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
