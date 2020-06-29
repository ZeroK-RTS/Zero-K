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
local allMobileGround = {}
local armedLand = {}

for name,data in pairs(UnitDefNames) do
	if not data.canfly then
		allGround[data.id] = true
		if data.canAttack and data.weapons[1] and data.weapons[1].onlyTargets.land then
			armedLand[data.id] = true
		end
		if not data.isImmobile then
			allMobileGround[data.id] = true
		end
	end
end

---------------------------------------------------------------------------
-- swarm arrays
---------------------------------------------------------------------------
-- these are not strictly required they just help with inputting the units

local longRangeSwarmieeArray = NameToDefID({
	"tankarty",
	"jumparty",
	"spiderskirm",
	"shieldskirm",
	"shiparty",
	"cloakarty",
	"shiparty",
})

local medRangeSwarmieeArray = NameToDefID({
	"cloakskirm",
	"amphfloater",
	"chickens",
	"shipskirm",
})

local lowRangeSwarmieeArray = NameToDefID({
	"shieldassault",
	"spiderassault",
	"vehassault",
	"hoverassault",
	
	"tankassault",
	"tankheavyassault",
	
	"spidercrabe",
	--"hoverarty", -- Always hits small units. Swarm may make it hit more.
	
	"chickenr",
	"chickenblobber",
	"cloaksnipe", -- only worth swarming sniper at low range, too accurate otherwise.
})

medRangeSwarmieeArray = Union(medRangeSwarmieeArray,longRangeSwarmieeArray)
lowRangeSwarmieeArray = Union(lowRangeSwarmieeArray,medRangeSwarmieeArray)

---------------------------------------------------------------------------
-- skirm arrays
---------------------------------------------------------------------------
-- these are not strictly required they just help with inputting the units

local veryShortRangeSkirmieeArray = NameToDefID({
	"shieldscout",
	"tankraid",
	"jumpassault",
	"cloakheavyraid",
	"cloakbomb",
	"jumpscout",
	"shieldbomb",
	"chicken",
	"chickena",
	"chicken_leaper",
	"chicken_tiamat",
	"chicken_dragon",
	"hoverdepthcharge",
	"vehraid",
	"spiderscout",
	"cloakraid",
	"vehscout",
})

local shortRangeSkirmieeArray = NameToDefID({
	"jumpraid",
	"amphraid",
	"jumpsumo",
	"amphbomb",
	"jumpbomb",
	"shieldraid",
})

local shortToRiotRangeSkirmieeArray = NameToDefID({
	"hoverraid",
	"amphriot",
})

local riotRangeSkirmieeArray = NameToDefID({
	"cloakriot",
	"tankheavyraid",
	"hoverheavyraid",
	"striderantiheavy",
	"striderdante",
	
	"cloakaa",
	"shieldaa",
	"jumpaa",
	"hoveraa",
	"spideraa",
	"amphaa",
	"shipaa",
	
	"cloakcon",
	"shieldcon",
	"vehcon",
	"hovercon",
	"tankcon",
	"spidercon",
	"jumpcon",
	"amphcon",
	"shipcon",
	
	"cloakjammer",
	"shieldshield",
	
	"shiptorpraider",
	"subraider",
})

local lowMedRangeSkirmieeArray = NameToDefID({
	"cloakriot",
	"hoverassault",
	"spideremp",
	
	"shieldriot",
	"shieldassault",
	"vehassault",
	
	"shipscout",
	"shipriot",
})

local medRangeSkirmieeArray = NameToDefID({
	"spiderriot",
	"cloakassault",
	"amphimpulse",
	
	"spiderassault",
	"vehriot",
	
	"hoverriot",
	"shieldfelon",

	"tankassault",
	"tankheavyassault",
	"tankriot", -- banisher
	"striderscorpion",
	
	"shipassault",
})

for name, data in pairs(UnitDefNames) do -- add all comms to mid ranged skirm because they might be short ranged (and also explode)
	if data.customParams.commtype then
		medRangeSkirmieeArray[data.id] = true
	end
end

local longRangeSkirmieeArray = NameToDefID({
	"cloakskirm",
	"jumpskirm",
	"amphfloater",
	"hoverskirm", -- hover janus
	"vehcapture",
	"chickenc",
	"striderbantha",
	"turretlaser",
	"turretriot",
	"turretemp",
})

local artyRangeSkirmieeArray = NameToDefID({
	"spiderskirm",
	"shieldskirm",
	"vehsupport",
	"amphassault",
	"chicken_sporeshooter",
	"turretmissile",
	"turretheavylaser",
	"turretgauss",
	"turretheavy",
	"striderdetriment",
	"ampharty",
	
	"shipskirm",
})

local slasherSkirmieeArray = NameToDefID({
	"jumpsumo",
	"striderdante",
	"cloakriot",
	"hoverassault",
	"shieldriot",
	"shieldassault",
	"spiderriot",
	"cloakassault",
	"spiderassault",
	"vehassault",
	"vehriot",
	"hoverriot",
	"tankriot",
	"shieldfelon",
	"tankassault",
	"cloakskirm",
	"turretgauss",
	"turretlaser",
	"turretriot",
	"turretemp",
})

-- Nested union so long ranged things also skirm the things skirmed by short ranged things
shortRangeSkirmieeArray       = Union(shortRangeSkirmieeArray,veryShortRangeSkirmieeArray)
shortToRiotRangeSkirmieeArray = Union(shortToRiotRangeSkirmieeArray,shortRangeSkirmieeArray)
riotRangeSkirmieeArray        = Union(riotRangeSkirmieeArray,shortToRiotRangeSkirmieeArray)
lowMedRangeSkirmieeArray      = Union(lowMedRangeSkirmieeArray, riotRangeSkirmieeArray)
medRangeSkirmieeArray         = Union(medRangeSkirmieeArray, lowMedRangeSkirmieeArray)
longRangeSkirmieeArray        = Union(longRangeSkirmieeArray, medRangeSkirmieeArray)
artyRangeSkirmieeArray        = Union(artyRangeSkirmieeArray, longRangeSkirmieeArray)

---------------------------------------------------------------------------
-- Explosion avoidance
---------------------------------------------------------------------------

local veryShortRangeExplodables = NameToDefID({
	"energywind",
	"staticmex",
})

local shortRangeExplodables = NameToDefID({
	"energywind",
	"staticmex",
	"turretriot",
	"energypylon",
})

local diverExplodables = NameToDefID({
	"energypylon",
})

local medRangeExplodables = NameToDefID({
	"energyfusion", -- don't suicide vs fusions if possible.
	"energygeo",
	"energysingu", -- same with singu, at least to make an effort for survival.
	"energyheavygeo",
})

local explodableFull = Union(
	veryShortRangeExplodables,
	Union(shortRangeExplodables,
	Union(diverExplodables,
	medRangeExplodables
)))

-- Notably, this occurs after the skirm nested union
veryShortRangeSkirmieeArray = Union(veryShortRangeSkirmieeArray, veryShortRangeExplodables)

local diverSkirmieeArray = Union(shortRangeSkirmieeArray, diverExplodables)
shortRangeSkirmieeArray  = Union(shortRangeSkirmieeArray, shortRangeExplodables)
riotRangeSkirmieeArray   = Union(riotRangeSkirmieeArray, shortRangeExplodables)

lowMedRangeSkirmieeArray = Union(lowMedRangeSkirmieeArray, medRangeExplodables)
medRangeSkirmieeArray    = Union(medRangeSkirmieeArray, medRangeExplodables)
--longRangeSkirmieeArray   = Union(longRangeSkirmieeArray, medRangeExplodables)
--artyRangeSkirmieeArray   = Union(artyRangeSkirmieeArray, medRangeExplodables)

-- Stuff that mobile AA skirms

local skirmableAir = NameToDefID({
	"gunshipbomb",
	"gunshipemp",
	"gunshipraid",
	"gunshipskirm",
	"gunshipheavyskirm",
	"gunshipassault",
	"gunshipheavytrans",
	"gunshipkrow",
})

-- Brawler, for AA to swarm.
local brawler = NameToDefID({
	"gunshipheavyskirm",
})

-- Things that are fled by some things
local fleeables = NameToDefID({
	"turretlaser",
	"turretriot",
	"turretemp",
	"turretimpulse",
	
	"armcom",
	"armadvcom",
	"corcom",
	"coradvcom",
	
	"cloakriot",
	"cloakassault",
	
	"spideremp",
	"spiderriot",
	
	"shieldriot",
	
	"vehriot",
	"vehcapture",

	"hoverriot", -- mumbo
	"shieldfelon",
	"jumpsumo",
})

-- Not currently used as air scouts flee everything.
--local antiAirFlee = NameToDefID({
--	"cloakaa",
--	"shieldaa",
--	"jumpaa",
--	"spideraa",
--	"vehaa",
--	"tankaa",
--	"hoveraa",
--	"amphaa",
--	"gunshipaa",
--	"shipaa",
--
--	"turretmissile",
--	"turretaalaser",
--	"turretaaclose",
--	"turretaaflak",
--})

-- Submarines to be fled by some things
local subfleeables = NameToDefID({
	"subraider",
})

-- Some short ranged units dive everything that they don't skirm or swarm.
local shortRangeDiveArray = SetMinus(SetMinus(allGround, diverSkirmieeArray), lowRangeSwarmieeArray)

-- waterline(defaults to 0): Water level at which the unit switches between land and sea behaviour
-- floatWaterline (defalts to false): Use ground height instead of unit height for waterline check
-- sea: table of behaviour for sea. Note that these tables are optional.
-- land: table of behaviour for land

-- weaponNum(defaults to 1): Weapon to use when skirming
-- searchRange(defaults to 800): max range of GetNearestEnemy for the unit.
-- defaultAIState (defaults in config): (1 or 0) state of AI when unit is initialised
-- externallyHandled (defaults to nil): Enable to disable all tactical AI handling, only the state toggle is added.

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
-- reloadSkirmLeeway (defaults to false): Increase skirm range by reloadSkirmLeeway*remainingReloadFrames when reloading.
-- skirmBlockedApproachOnFight (defaults to false): Applies skirmBlockedApproachFrames to all commands.
-- skirmBlockedApproachFrames (defaults to false): Stop skirming after this many frames of being fully reloaded if not set to attack move.
-- skirmBlockApproachHeadingBlock (defaults to false): Blocks the effect of skirmBlockedApproachFrames if the dot product of enemyVector and unitFacing exceeds skirmBlockApproachHeadingBlock.
-- avoidHeightDiff (default in config): A table of targets that are not skirmed if they are too far above or below the unit.

--*** swarms(defaults to empty): the table of units that this unit will jink towards and strafe
-- maxSwarmLeeway (defaults to Weapon range): (Weapon range - maxSwarmLeeway) = Max range that the unit will begin strafing targets while swarming
-- minSwarmLeeway (defaults to Weapon range): (Weapon range - minSwarmLeeway) = Range that the unit will attempt to move further away from the target while swarming
-- jinkTangentLength (default in config): component of jink vector tangent to direction to enemy
-- jinkParallelLength (default in config): component of jink vector parallel to direction to enemy
-- jinkAwayParallelLength (defaults in config): component of jink vector parallel to direction to enemy when jinking away due to being too close
-- circleStrafe (defaults to false): when set to true the unit will run all around the target unit, false will cause the unit to jink back and forth
-- minCircleStrafeDistance (default in config): (weapon range - minCircleStrafeDistance) = distance at which the circle strafer will attempt to move away from target
-- strafeOrderLength (default in config): length of move order while strafing
-- swarmLeeway (defaults to 50): adds to enemy range when swarming
-- swarmEnemyDefaultRange (defaults to 800): range of the enemy used if it cannot be seen.
-- alwaysJinkFight (defaults to false): If enabled the unit with jink whenever it has a fight command
-- localJinkOrder (defaults in config): Causes move commands to be given near the unit, otherwise given next to opponent

--*** flees(defaults to empty): the table of units that this unit will flee like the coward it is!!!
-- fleeCombat (defaults to false): if true will flee everything without catergory UNARMED
-- fleeEverything (defaults to false): if true will flee all enemies
-- fleeLeeway (defaults to 100): adds to enemy range when fleeing
-- fleeDistance (defaults to 100): unit will flee to enemy range + fleeDistance away from enemy
-- fleeRadar (defaults to false): does the unit flee radar dots?
-- minFleeRange (defaults to 0): minumun range at which the unit will flee, will flee at higher range if the attacking unit outranges it
-- fleeOrderDis (defaults to 120): max distance the move order is from the unit when fleeing

--*** hugs(defaults to empty): the table of units to close range with.
-- hugRange (default in config): Range to close to

--*** fightOnlyUnits(defaults to empty): the table of units that the unit will only interact with when it has a fight command. No AI invoked with manual attack or leashing.
--*** fightOnlyOverride(defaults to empty): Table tbat overrides parameters when fighting fight only units.

local ENABLE_OLD_JINK_STRAFE = false

--- Array loaded into gadget
local behaviourDefaults = {
	defaultState = 1,
	defaultJinkTangentLength = 80,
	defaultJinkParallelLength = 200,
	defaultJinkAwayParallelLength = 170,
	defaultStrafeOrderLength = 100,
	defaultMinCircleStrafeDistance = 40,
	defaultLocalJinkOrder = true,
	defaultSkirmOrderDis = 120,
	defaultVelocityPrediction = 30,
	defaultHugRange = 50,
}

local behaviourConfig = {
	-- swarmers
	["cloakbomb"] = {
		defaultAIState = 0,
		skirms = {},
		swarms = lowRangeSwarmieeArray,
		flees = {},
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 40,
		jinkTangentLength = 100,
		minCircleStrafeDistance = 0,
		minSwarmLeeway = 100,
		swarmLeeway = 30,
		alwaysJinkFight = true,
	},
	
	["shieldbomb"] = {
		defaultAIState = 0,
		skirms = {},
		swarms = lowRangeSwarmieeArray,
		flees = {},
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 40,
		jinkTangentLength = 100,
		minCircleStrafeDistance = 0,
		minSwarmLeeway = 100,
		swarmLeeway = 30,
		alwaysJinkFight = true,
	},
	
	["amphbomb"] = {
		defaultAIState = 0,
		skirms = {},
		swarms = lowRangeSwarmieeArray,
		flees = {},
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 40,
		jinkTangentLength = 100,
		minCircleStrafeDistance = 0,
		minSwarmLeeway = 100,
		swarmLeeway = 30,
		alwaysJinkFight = true,
	},
	
	["jumpscout"] = {
		skirms = {},
		swarms = lowRangeSwarmieeArray,
		flees = {},
		localJinkOrder = false,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		minCircleStrafeDistance = 170,
		maxSwarmLeeway = 170,
		jinkTangentLength = 100,
		minSwarmLeeway = 100,
		swarmLeeway = 200,
	},
  
	["cloakraid"] = {
		skirms = veryShortRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = veryShortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 35,
		swarmLeeway = 50,
		skirmLeeway = 10,
		jinkTangentLength = 140,
		stoppingDistance = 10,
	},
	
	["spiderscout"] = {
		skirms = veryShortRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = fleeables,
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = veryShortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		skirmLeeway = 5,
		maxSwarmLeeway = 5,
		swarmLeeway = 30,
		stoppingDistance = 0,
		strafeOrderLength = 100,
		minCircleStrafeDistance = 20,
		fleeLeeway = 150,
		fleeDistance = 150,
	},
	["vehscout"] = {
		skirms = veryShortRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = fleeables,
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = veryShortRangeExplodables,
		fightOnlyOverride = {
			skirmLeeway = 40,
			skirmOrderDis = 30,
			stoppingDistance = 30,
		},
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
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
	["shieldraid"] = {
		skirms = riotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 35,
		swarmLeeway = 30,
		jinkTangentLength = 140,
		stoppingDistance = 10,
		minCircleStrafeDistance = 10,
		velocityPrediction = 30,
	},
	
	["amphraid"] = {
		waterline = -5,
		land = {
			weaponNum = 1,
			skirms = shortRangeSkirmieeArray,
			swarms = lowRangeSwarmieeArray,
			flees = {},
			avoidHeightDiff = explodableFull,
			fightOnlyUnits = shortRangeExplodables,
			circleStrafe = ENABLE_OLD_JINK_STRAFE,
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
			avoidHeightDiff = explodableFull,
			fightOnlyUnits = shortRangeExplodables,
			circleStrafe = ENABLE_OLD_JINK_STRAFE,
			maxSwarmLeeway = 35,
			swarmLeeway = 30,
			jinkTangentLength = 140,
			stoppingDistance = 25,
			minCircleStrafeDistance = 10,
			velocityPrediction = 30,
		},
	},
	
	["vehraid"] = {
		skirms = diverSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		hugs = shortRangeDiveArray,
		fightOnlyUnits = shortRangeExplodables,
		localJinkOrder = false,
		jinkTangentLength = 50,
		jinkAwayParallelLength = 120,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		strafeOrderLength = 100,
		minCircleStrafeDistance = 260,
		maxSwarmLeeway = 50,
		minSwarmLeeway = 120,
		swarmLeeway = 300,
		skirmLeeway = 10,
		stoppingDistance = 8,
		velocityPrediction = 20,
	},
	
	["hoverscout"] = {
		skirms = shortRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		jinkAwayParallelLength = 100,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		strafeOrderLength = 180,
		maxSwarmLeeway = 40,
		swarmLeeway = 40,
		stoppingDistance = 8,
		skirmOrderDis = 150,
	},
	
	["hoverraid"] = {
		skirms = shortRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		strafeOrderLength = 180,
		maxSwarmLeeway = 40,
		swarmLeeway = 40,
		stoppingDistance = 8,
		skirmOrderDis = 150,
	},
	["hoverheavyraid"] = {
		skirms = shortToRiotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		strafeOrderLength = 180,
		maxSwarmLeeway = 40,
		swarmLeeway = 50,
		stoppingDistance = 15,
		skirmOrderDis = 150,
	},

	["jumpraid"] = {
		skirms = shortToRiotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		jinkAwayParallelLength = 150,
		maxSwarmLeeway = 100,
		minSwarmLeeway = 200,
		swarmLeeway = 30,
		stoppingDistance = 8,
		velocityPrediction = 20
	},
	
	["tankraid"] = {
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 40,
		swarmLeeway = 30,
		stoppingDistance = 8,
		reloadSkirmLeeway = 1.2,
		skirmOrderDis = 150,
	},
  
	["tankheavyraid"] = {
		skirms = shortToRiotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		strafeOrderLength = 180,
		maxSwarmLeeway = 40,
		swarmLeeway = 50,
		stoppingDistance = 15,
		skirmOrderDis = 150,
	},
	
	["amphimpulse"] = {
		skirms = riotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 40,
		skirmLeeway = 30,
		minCircleStrafeDistance = 10,
		velocityPrediction = 20
	},
	
	["shiptorpraider"] = {
		skirms = shortRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
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
		avoidHeightDiff = explodableFull,
		hugs = shortRangeDiveArray,
		fightOnlyUnits = shortRangeExplodables,
		localJinkOrder = false,
		jinkTangentLength = 50,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		strafeOrderLength = 100,
		minCircleStrafeDistance = 260,
		maxSwarmLeeway = 0,
		minSwarmLeeway = 100,
		swarmLeeway = 300,
		skirmLeeway = 10,
		stoppingDistance = 8,
	},
	
	-- riots
	["cloakriot"] = {
		skirms = riotRangeSkirmieeArray,
		swarms = {},
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = 20,
		velocityPrediction = 20
	},
	["jumpcon"] = {
		skirms = lowMedRangeSkirmieeArray,
		swarms = {},
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = 0,
		velocityPrediction = 20
	},
	["spiderriot"] = {
		skirms = lowMedRangeSkirmieeArray,
		swarms = {},
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = 0,
		velocityPrediction = 20
	},
	["spideremp"] = {
		skirms = riotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 40,
		skirmLeeway = 30,
		minCircleStrafeDistance = 10,
		velocityPrediction = 20
	},
	["shieldriot"] = {
		skirms = riotRangeSkirmieeArray,
		swarms = {},
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = 50,
		velocityPrediction = 20
	},
	["vehriot"] = {
		skirms = lowMedRangeSkirmieeArray,
		swarms = {},
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = -30,
		stoppingDistance = 5,
		fightOnlyOverride = {
			skirmLeeway = 10,
			stoppingDistance = 10,
		},
	},
	
    ["shieldfelon"] = {
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = 50,
		stoppingDistance = 5,
		skirmBlockedApproachFrames = 40,
	},
	
	["hoverriot"] = {
		skirms = lowMedRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = -15,
		stoppingDistance = 5,
		skirmBlockedApproachFrames = 40,
		skirmBlockApproachHeadingBlock = 0,
		fightOnlyOverride = {
			skirmLeeway = 10,
		},
	},
	["tankriot"] = {
		skirms = medRangeSkirmieeArray,
		swarms = {},
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0,
		skirmOrderDis = 220,
		skirmLeeway = -30,
		reloadSkirmLeeway = 2,
		stoppingDistance = 10,
		fightOnlyOverride = {
			skirmLeeway = 10,
		},
	},
	["amphriot"] = {
		waterline = -5,
		land = {
			weaponNum = 1,
			skirms = riotRangeSkirmieeArray,
			swarms = {},
			flees = {},
			avoidHeightDiff = explodableFull,
			fightOnlyUnits = shortRangeExplodables,
			circleStrafe = ENABLE_OLD_JINK_STRAFE,
			maxSwarmLeeway = 40,
			skirmLeeway = 30,
			minCircleStrafeDistance = 10,
		},
		sea = {
			weaponNum = 2,
			skirms = {},
			swarms = {},
			flees = {},
			fightOnlyUnits = shortRangeExplodables,
			circleStrafe = ENABLE_OLD_JINK_STRAFE,
			maxSwarmLeeway = 40,
			skirmLeeway = 30,
			minCircleStrafeDistance = 10,
		},
	},
	
	["ampharty"] = {
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
			avoidHeightDiff = explodableFull,
			fightOnlyUnits = medRangeExplodables,
			skirmRadar = true,
			maxSwarmLeeway = 10,
			minSwarmLeeway = 130,
			skirmLeeway = 40,
		},
	},
	["shipscout"] = { -- scout boat
		skirms = lowMedRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = subfleeables,
		avoidHeightDiff = explodableFull,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
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
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = 5,
		stoppingDistance = 10,
		skirmOrderDis = 30,
		velocityPrediction = 30,
	},
	["hoverdepthcharge"] = {
		waterline = -5,
		floatWaterline = true,
		land = {
			weaponNum = 2,
			skirms = {},
			swarms = {},
			flees = {},
			skirmEverything = true,
			skirmLeeway = 0,
			stoppingDistance = 8,
			skirmOrderDis = 150,
		},
		sea = {
			weaponNum = 1,
			skirms = lowMedRangeSkirmieeArray,
			swarms = {},
			flees = {},
			avoidHeightDiff = explodableFull,
			fightOnlyUnits = medRangeExplodables,
			maxSwarmLeeway = 0,
			skirmLeeway = -15,
			skirmOrderDis = 30,
			stoppingDistance = -5,
			velocityPrediction = 0,
		},
	},
	
	--assaults
	["cloakassault"] = {
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 90,
		skirmLeeway = 40,
		skirmBlockedApproachFrames = 10,
	},
	["shieldassault"] = {
		skirms = riotRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 50,
		minSwarmLeeway = 120,
		skirmLeeway = 40,
	},
	["spiderassault"] = {
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 50,
		minSwarmLeeway = 120,
		skirmLeeway = 40,
	},
	
	["shipraider"] = {
		skirms = riotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 90,
		skirmLeeway = 60,
	},

	["vehassault"] = {
		skirms = riotRangeSkirmieeArray,
		swarms = {},
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 50,
		minSwarmLeeway = 120,
		skirmLeeway = 40,
	},
	["tankassault"] = {
		skirms = lowMedRangeSkirmieeArray,
		swarms = {},
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		skirmOrderDis = 220,
		skirmLeeway = 50,
	},
	
	-- med range skirms
	["cloakskirm"] = {
		skirms = Union(medRangeSkirmieeArray, NameToDefID({"turretriot"})),
		swarms = medRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 130,
		skirmLeeway = 10,
		skirmBlockedApproachFrames = 40,
	},
	["jumpskirm"] = {
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130,
		skirmLeeway = 20,
		skirmBlockedApproachFrames = 40,
	},
	["striderdante"] = {
		skirms = medRangeSkirmieeArray,
		swarms = {},
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		skirmLeeway = 40,
	},
	["amphfloater"] = {
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 130,
		skirmLeeway = 10,
		skirmBlockedApproachFrames = 40,
	},
	["hoverskirm"] = {
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 130,
		skirmLeeway = 30,
		skirmOrderDis = 200,
		velocityPrediction = 90,
		skirmBlockedApproachFrames = 60,
		skirmBlockApproachHeadingBlock = 0,
	},
	["tankheavyassault"] = {
		skirms = medRangeSkirmieeArray,
		swarms = {},
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		skirmOrderDis = 220,
		skirmLeeway = 50,
		skirmBlockedApproachFrames = 60,
	},
	["gunshipskirm"] = {
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		skirmOrderDis = 120,
		selfVelocityPrediction = true,
		velocityPrediction = 30,
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
		skirmBlockedApproachFrames = 40,
	},
	["shieldskirm"] = {
		skirms = longRangeSkirmieeArray,
		swarms = longRangeSwarmieeArray,
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 130,
		skirmLeeway = 10,
		skirmBlockedApproachFrames = 40,
	},
	["spiderskirm"] = {
		skirms = longRangeSkirmieeArray,
		swarms = longRangeSwarmieeArray,
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130,
		skirmLeeway = 10,
		skirmBlockedApproachFrames = 40,
	},
	["amphassault"] = {
		skirms = longRangeSkirmieeArray,
		swarms = longRangeSwarmieeArray,
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130,
		skirmLeeway = 20,
		skirmBlockedApproachFrames = 40,
	},
	["gunshipkrow"] = {
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130,
		skirmLeeway = 20,
	},
	["vehcapture"] = {
		skirms = longRangeSkirmieeArray,
		swarms = longRangeSwarmieeArray,
		flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 130,
		skirmLeeway = -5,
		skirmOrderDis = 120,
		velocityPrediction = 135,
		skirmBlockedApproachFrames = 40,
		skirmBlockApproachHeadingBlock = -0.3,
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
		skirmBlockedApproachFrames = 40,
		skirmBlockApproachHeadingBlock = -0.2,
	},
	
	-- weird stuff
	["vehsupport"] = {
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
	["cloaksnipe"] = {
		skirms = allMobileGround,
		skirmRadar = true,
		swarms = {},
		flees = {},
		skirmLeeway = 40,
		skirmBlockedApproachOnFight = true,
		skirmBlockedApproachFrames = 120,
	},
	
	["veharty"] = {
		skirms = allMobileGround,
		skirmRadar = true,
		swarms = {},
		flees = {},
		skirmLeeway = 20,
		skirmOrderDis = 200,
		skirmOrderDisMin = 100, -- Make it turn around.
	},
	
	["vehheavyarty"] = {
		skirms = allMobileGround,
		skirmRadar = true,
		swarms = {},
		flees = {},
		skirmLeeway = 100,
		stoppingDistance = -80,
		velocityPrediction = 0,
	},
	
	["tankarty"] = {
		skirms = allMobileGround,
		skirmRadar = true,
		swarms = {},
		flees = {},
		skirmLeeway = 200,
		skirmKeepOrder = true,
		stoppingDistance = -180,
		velocityPrediction = 0,
		skirmOrderDis = 250,
		skirmOnlyNearEnemyRange = 120,
	},
	
	["striderarty"] = {
		skirms = allMobileGround,
		skirmRadar = true,
		swarms = {},
		flees = {},
		skirmLeeway = 100,
	},
	
	["cloakarty"] = {
		skirms = allMobileGround,
		swarms = {},
		flees = {},
		skirmRadar = true,
		skirmLeeway = 40,
		skirmBlockedApproachFrames = 40,
	},
	["jumparty"] = {
		skirms = allMobileGround,
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
	["hoverarty"] = {
		skirms = allMobileGround,
		swarms = {},
		flees = {},
		skirmRadar = true,
		skirmKeepOrder = true,
		skirmLeeway = 150,
		skirmOrderDis = 200,
		stoppingDistance = -100,
		velocityPrediction = 0,
	},
	["striderbantha"] = {
		defaultAIState = 0,
		skirms = allMobileGround,
		swarms = {},
		flees = {},
		skirmRadar = true,
		skirmLeeway = 120,
	},
	["shiparty"] = {
		skirms = allMobileGround,
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
	["cloakjammer"] = {
		skirms = {},
		swarms = {},
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 400,
	},
	
	["shieldshield"] = {
		skirms = {},
		swarms = {},
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 450,
	},
	
	-- mobile AA
	["cloakaa"] = {
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
	["shieldaa"] = {
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
	["jumpaa"] = {
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
	["tankaa"] = {
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
	
	-- Flying scouts
	["planelightscout"] = {
		skirms = {},
		swarms = {},
		flees = {},
		searchRange = 1000,
		fleeEverything = true,
		minFleeRange = 600, -- Avoid enemies standing in front of Pickets
		fleeLeeway = 650,
		fleeDistance = 650,
	},
	["planescout"] = {
		skirms = {},
		swarms = {},
		flees = {},
		searchRange = 1200,
		fleeEverything = true,
		minFleeRange = 600, -- Avoid enemies standing in front of Pickets
		fleeLeeway = 850,
		fleeDistance = 850,
	},
	
	-- chickens
	["chicken_tiamat"] = {
		skirms = {},
		swarms = {},
		flees = {},
		hugs = allGround,
		hugRange = 100,
	},
	
	["chicken_dragon"] = {
		skirms = {},
		swarms = {},
		flees = {},
		hugs = allGround,
		hugRange = 150,
	},
	
	["chickenlandqueen"] = {
		skirms = {},
		swarms = {},
		flees = {},
		hugs = allGround,
		hugRange = 150,
	},
	
	-- Externally handled units
	["energysolar"] = {
		externallyHandled = true,
	},
}

return behaviourConfig, behaviourDefaults

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
