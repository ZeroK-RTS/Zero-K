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

for name,data in pairs(UnitDefNames) do
	if not data.canfly then
		allGround[data.id] = true
		if data.canAttack and data.weapons[1] and data.weapons[1].onlyTargets.land then
			armedLand[data.id] = true
		end
	end
end

---------------------------------------------------------------------------
-- swarm arrays
---------------------------------------------------------------------------
-- these are not strictly required they just help with inputting the units

local longRangeSwarmieeArray = NameToDefID({ 
	"cormart",
	"firewalker",
	"armsptk",
	"corstorm",
	"shiparty",
	"armham",
	"shiparty",
})

local medRangeSwarmieeArray = NameToDefID({ 
	"armrock",
	"amphfloater",
	"chickens",
	"shipskirm",
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

---------------------------------------------------------------------------
-- skirm arrays
---------------------------------------------------------------------------
-- these are not strictly required they just help with inputting the units

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
	
	"shiptorpraider",
	"subraider",
})

local lowMedRangeSkirmieeArray = NameToDefID({
	"armwar",
	"hoverassault",
	"arm_venom",
	
	"cormak",
	"corthud",
	"corraid",
	
	"shipriot",
})

local medRangeSkirmieeArray = NameToDefID({
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
	
	
	"shipscout",
	"shipassault",
})

for name, data in pairs(UnitDefNames) do -- add all comms to mid ranged skirm because they might be short ranged (and also explode)
	if data.customParams.commtype then
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
	"corllt",
	"armdeva",
	"armartic",
	
	
})

local artyRangeSkirmieeArray = NameToDefID({
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
	
	"shipskirm",
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

-- Nested union so long ranged things also skirm the things skirmed by short ranged things
shortRangeSkirmieeArray  = Union(shortRangeSkirmieeArray,veryShortRangeSkirmieeArray)
riotRangeSkirmieeArray   = Union(riotRangeSkirmieeArray,shortRangeSkirmieeArray)
lowMedRangeSkirmieeArray = Union(lowMedRangeSkirmieeArray, riotRangeSkirmieeArray)
medRangeSkirmieeArray    = Union(medRangeSkirmieeArray, lowMedRangeSkirmieeArray)
longRangeSkirmieeArray   = Union(longRangeSkirmieeArray,medRangeSkirmieeArray)
artyRangeSkirmieeArray   = Union(artyRangeSkirmieeArray,longRangeSkirmieeArray)

---------------------------------------------------------------------------
-- Explosion avoidance
---------------------------------------------------------------------------

local veryShortRangeExplodables = NameToDefID({
	"armwin",
	"cormex",
})

local shortRangeExplodables = NameToDefID({
	"armwin",
	"cormex",
	"armdeva",
	"armestor",
})

local diverExplodables = NameToDefID({
	"armestor",
})

local medRangeExplodables = NameToDefID({
	"armfus", -- don't suicide vs fusions if possible.
	"geo",
	"cafus", -- same with singu, at least to make an effort for survival.
	"amgeo",
	"armbanth", -- banthas also have a fairly heavy but dodgeable explosion.
})

for name, data in pairs(UnitDefNames) do -- avoid factory death explosions.
	if string.match(name, "factory") or string.match(name, "hub") then
		shortRangeExplodables[data.id] = true
		medRangeExplodables[data.id] = true
	end
end

-- Notably, this occurs after the skirm nested union
veryShortRangeSkirmieeArray = Union(veryShortRangeSkirmieeArray, veryShortRangeExplodables)

local diverSkirmieeArray = Union(shortRangeSkirmieeArray, diverExplodables)
shortRangeSkirmieeArray     = Union(shortRangeSkirmieeArray, shortRangeExplodables)
riotRangeSkirmieeArray      = Union(riotRangeSkirmieeArray, shortRangeExplodables)

lowMedRangeSkirmieeArray = Union(lowMedRangeSkirmieeArray, medRangeExplodables)
medRangeSkirmieeArray    = Union(medRangeSkirmieeArray, medRangeExplodables)
longRangeSkirmieeArray   = Union(longRangeSkirmieeArray, medRangeExplodables)
artyRangeSkirmieeArray   = Union(artyRangeSkirmieeArray, medRangeExplodables)

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

-- Submarines to be fled by some things
local subfleeables = NameToDefID({
	"subraider",
})

-- Some short ranged units dive everything that they don't skirm or swarm.
local shortRangeDiveArray = SetMinus(SetMinus(allGround, diverSkirmieeArray), lowRangeSwarmieeArray)

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
-- selfVelocityPrediction (defaults to false): Whether the unit predicts its own velocity when calculating range.

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

--*** hugs(defaults to empty): the table of units to close range with.
-- hugRange (default in config): Range to close to

--*** fightOnlyUnits(defaults to empty): the table of units that the unit will only interact with when it has a fight command. No AI invoked with manual attack or leashing.

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
	defaultHugRange = 30,
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
		fightOnlyUnits = veryShortRangeExplodables,
		circleStrafe = true, 
		maxSwarmLeeway = 35, 
		swarmLeeway = 50, 
		skirmLeeway = 10,
		jinkTangentLength = 140, 
		stoppingDistance = 10,
	},
	
	["armflea"] = {
		skirms = veryShortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = fleeables,
		fightOnlyUnits = veryShortRangeExplodables,
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
	["corfav"] = {
		skirms = veryShortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = fleeables,
		fightOnlyUnits = veryShortRangeExplodables,
		circleStrafe = true,
		skirmLeeway = 15,
		strafeOrderLength = 180,
		maxSwarmLeeway = 40, 
		swarmLeeway = 40, 
		stoppingDistance = 25,
		minCircleStrafeDistance = 50,
		fleeLeeway = 100,
		fleeDistance = 150,
	},
  
	-- longer ranged swarmers
	["corak"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = shortRangeExplodables,
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
			fightOnlyUnits = shortRangeExplodables,
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
			fightOnlyUnits = shortRangeExplodables,
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
		skirms = diverSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		hugs = shortRangeDiveArray,
		fightOnlyUnits = shortRangeExplodables, 
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
		fightOnlyUnits = shortRangeExplodables,
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
		fightOnlyUnits = shortRangeExplodables,
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
		fightOnlyUnits = shortRangeExplodables,
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
		fightOnlyUnits = shortRangeExplodables,
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
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = true, 
		strafeOrderLength = 180,
		maxSwarmLeeway = 40, 
		swarmLeeway = 50, 
		stoppingDistance = 15,
		skirmOrderDis = 150,
	},
	
	["amphraider2"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = true,
		maxSwarmLeeway = 40,
		skirmLeeway = 30, 
		minCircleStrafeDistance = 10,
		velocityPrediction = 20
	},
	
	["shiptorpraider"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		swarmLeeway = 30, 
		stoppingDistance = 8,
		skirmOrderDis = 200,
		velocityPrediction = 90,
	},
	
	-- could flee subs but isn't fast enough for it to be useful
	["shipriot"] = {
		skirms = diverSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		hugs = shortRangeDiveArray,
		fightOnlyUnits = shortRangeExplodables, 
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
	
	-- riots
	["armwar"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 0, 
		skirmLeeway = 20, 
		velocityPrediction = 20
	},
	["spiderriot"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0, 
		skirmLeeway = 0, 
		velocityPrediction = 20
	},
	["arm_venom"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = shortRangeExplodables,
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
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 0, 
		skirmLeeway = 50, 
		velocityPrediction = 20
	},
	["corlevlr"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0, 
		skirmLeeway = -30, 
		stoppingDistance = 5
	},
	
    ["shieldfelon"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0, 
		skirmLeeway = 50, 
		stoppingDistance = 5
	},
	
	["hoverriot"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0, 
		skirmLeeway = -30,
		stoppingDistance = 5
	},
	["tawf114"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0, 
		skirmOrderDis = 220,
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
			fightOnlyUnits = shortRangeExplodables,
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
			fightOnlyUnits = shortRangeExplodables,
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
			fightOnlyUnits = medRangeExplodables,
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
			fightOnlyUnits = medRangeExplodables,
			skirmRadar = true,
			maxSwarmLeeway = 10, 
			minSwarmLeeway = 130, 
			skirmLeeway = 40, 
		},
	},
	["shipscout"] = { -- scout boat
		skirms = medRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = subfleeables,
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		swarmLeeway = 30, 
		stoppingDistance = 8,
		skirmLeeway = 100,
		skirmOrderDis = 200,
		velocityPrediction = 90,
		fleeLeeway = 250,
		fleeDistance = 300,
	},
	["shipassault"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0, 
		skirmLeeway = -30, 
		stoppingDistance = 5
	},
		
	--assaults
	["armzeus"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 90, 
		skirmLeeway = 20, 
	},
	["corthud"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 50, 
		minSwarmLeeway = 120, 
		skirmLeeway = 40, 
	},
	["spiderassault"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 50, 
		minSwarmLeeway = 120, 
		skirmLeeway = 40, 
	},
	
	["shipraider"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 90, 
		skirmLeeway = 60, 
	},

	["corraid"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 50, 
		minSwarmLeeway = 120, 
		skirmLeeway = 40, 
	},	
	["correap"] = {
		skirms = lowMedRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		fightOnlyUnits = shortRangeExplodables,
		skirmOrderDis = 220,
		skirmLeeway = 50, 
	},		
	
	-- med range skirms
	["armrock"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["slowmort"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 20, 
	},
	["dante"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
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
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 30,
		skirmOrderDis = 200,
		velocityPrediction = 90,
	},
	["gunshipsupport"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		skirmOrderDis = 120,
		selfVelocityPrediction = true,
		velocityPrediction = 30,
	},
	["corcrw"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		skirmLeeway = 30, 
	},
	
	-- long range skirms
	["jumpblackhole"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 20, 
	},
	["corstorm"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["armsptk"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["amphassault"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 20, 
	},
	["corcrw"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 20, 
	},
	["capturecar"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 30,
		skirmOrderDis = 200,
		velocityPrediction = 60,
	},
	["shipskirm"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
		skirmOrderDis = 200,
		velocityPrediction = 90,
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
		skirmLeeway = 40,
	},
	
	["corgarp"] = {
		skirms = allGround,
		skirmRadar = true,
		swarms = {}, 
		flees = {},
		skirmLeeway = 20, 
		skirmOrderDis = 200,
		skirmOrderDisMin = 100, -- Make it turn around.
	},
	
	["armmerl"] = {
		skirms = allGround,
		skirmRadar = true, 
		swarms = {}, 
		flees = {},
		skirmLeeway = 100,
		stoppingDistance = -80,
		velocityPrediction = 0,
	},
	
	["cormart"] = {
		skirms = allGround,
		skirmRadar = true,
		swarms = {}, 
		flees = {},
		skirmLeeway = 200,
		skirmKeepOrder = true,
		stoppingDistance = -180,
		velocityPrediction = 0,
		skirmOrderDis = 250,
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
		fightOnlyUnits = medRangeExplodables,
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
		skirmKeepOrder = true,
		skirmLeeway = 150,
		skirmOrderDis = 200,
		stoppingDistance = -100,
		velocityPrediction = 0,
	},	
	["armbanth"] = {
		skirms = allGround, 
		swarms = {}, 
		flees = {},
		skirmRadar = true,
		skirmLeeway = 120, 
	},	
	["shiparty"] = {
		skirms = allGround, 
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
	["shipaa"] = {
		skirms = skirmableAir, 
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