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
	"amphsupport",
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
-- Idle flee arrays
---------------------------------------------------------------------------

-- The riot flee arrrays. Mostly useful for bots as they have turn rate.
local skirmRangeRiotIdleFleeArray = NameToDefID({
	"hoverskirm",
	"jumpskirm",
	"jumpblackhole",
	"shieldfelon",
	
	"cloakskirm",
	"shieldskirm",
	"spiderskirm",
	"amphfloater",
})

local longRangeRiotIdleFleeArray = NameToDefID({
	"tankriot",
	"hoverriot",
	"cloakassault",
	"amphimpulse",
})

local medRangeRiotIdleFleeArray = NameToDefID({
	"spiderriot",
})

local shortRangeRiotIdleFleeArray = NameToDefID({
	"vehriot",
	"cloakriot",
})

longRangeRiotIdleFleeArray = Union(longRangeRiotIdleFleeArray, skirmRangeRiotIdleFleeArray)
medRangeRiotIdleFleeArray = Union(medRangeRiotIdleFleeArray, longRangeRiotIdleFleeArray)
shortRangeRiotIdleFleeArray = Union(shortRangeRiotIdleFleeArray, medRangeRiotIdleFleeArray)

-- Things that raiders should back away from when idle, or be sniped.
local longRangeRaiderIdleFleeArray = NameToDefID({
	"cloakriot",
	"cloakassault",
	
	"shieldfelon",
	"shieldriot",
	
	"vehriot",
	
	"hoverheavyraid",
	"hoverriot",
	"hoverskirm",
	
	"tankheavyraid",
	"tankriot",
	
	"spiderriot",
	
	"jumpraid",
	"jumpskirm",
	"jumpblackhole",
	
	"amphimpulse",
	"amphriot",
	
	"shipriot",
	"striderdante",
})

local medRangeRaiderIdleFleeArray = NameToDefID({
	"tankraid",
	"vehraid",
	"hoverraid",
	"spideremp",
})

local shortRangeRaiderIdleFleeArray = NameToDefID({
	"amphraid",
	"shieldraid",
})

local veryShortRangeRaiderIdleFleeArray = NameToDefID({
	"cloakraid",
})

local torpedoIdleFleeArray = NameToDefID({
	"shiptorpraider",
	"subraider",
	"amphraid",
	"amphriot",
})

medRangeRaiderIdleFleeArray = Union(medRangeRaiderIdleFleeArray, longRangeRaiderIdleFleeArray)
shortRangeRaiderIdleFleeArray = Union(shortRangeRaiderIdleFleeArray, medRangeRaiderIdleFleeArray)
veryShortRangeRaiderIdleFleeArray = Union(veryShortRangeRaiderIdleFleeArray, shortRangeRaiderIdleFleeArray)

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
	"amphimpulse",
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
	"jumpblackhole",
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
	"hoverskirm",
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
-- fleeLeeway (defaults to 120): adds to enemy range when fleeing
-- fleeDistance (defaults to 120): unit will flee to enemy range + fleeDistance away from enemy
-- fleeRadar (defaults to false): does the unit flee radar dots?
-- minFleeRange (defaults to 0): minumun range at which the unit will flee, will flee at higher range if the attacking unit outranges it
-- fleeOrderDis (defaults to 120): max distance the move order is from the unit when fleeing
-- fleeVelPrediction (defaults to 10): velocity prediction that overrides general velocity prediction for fleeing.

--*** idleFlee (defaults to empty): Units that this unit will flea when idle and not on hold position.
-- 

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
	{
		name = "cloakbomb",
		defaultAIState = 0,
		--skirms = {},
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 40,
		jinkTangentLength = 100,
		minCircleStrafeDistance = 0,
		minSwarmLeeway = 100,
		swarmLeeway = 30,
		alwaysJinkFight = true,
	},
	{
		name = "shieldbomb",
		defaultAIState = 0,
		--skirms = {},
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 40,
		jinkTangentLength = 100,
		minCircleStrafeDistance = 0,
		minSwarmLeeway = 100,
		swarmLeeway = 30,
		alwaysJinkFight = true,
	},
	{
		name = "amphbomb",
		defaultAIState = 0,
		--skirms = {},
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 40,
		jinkTangentLength = 100,
		minCircleStrafeDistance = 0,
		minSwarmLeeway = 100,
		swarmLeeway = 30,
		alwaysJinkFight = true,
	},
	{
		name = "jumpscout",
		--skirms = {},
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		localJinkOrder = false,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		minCircleStrafeDistance = 170,
		maxSwarmLeeway = 170,
		jinkTangentLength = 100,
		minSwarmLeeway = 100,
		swarmLeeway = 200,
	},
	{
		name = "cloakraid",
		skirms = veryShortRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		idleFlee = veryShortRangeRaiderIdleFleeArray,
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = veryShortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 35,
		swarmLeeway = 50,
		skirmLeeway = 10,
		jinkTangentLength = 90,
		stoppingDistance = 10,
		fleeLeeway = 140,
		idleCommitDistMult = 0.05,
	},
	{
		name = "spiderscout",
		skirms = veryShortRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = fleeables,
		idleFlee = veryShortRangeRaiderIdleFleeArray,
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = veryShortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		skirmLeeway = 5,
		maxSwarmLeeway = 5,
		swarmLeeway = 30,
		stoppingDistance = 0,
		strafeOrderLength = 90,
		minCircleStrafeDistance = 20,
		fleeLeeway = 160,
		fleeDistance = 150,
	},
	{
		name = "vehscout",
		skirms = veryShortRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = fleeables,
		idleFlee = veryShortRangeRaiderIdleFleeArray,
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
		fleeLeeway = 140,
		fleeDistance = 150,
	},
	-- longer ranged swarmers
	{
		name = "shieldraid",
		skirms = riotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		idleFlee = shortRangeRaiderIdleFleeArray,
		idleFlee = medRangeRaiderIdleFleeArray,
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 35,
		swarmLeeway = 30,
		jinkTangentLength = 90,
		stoppingDistance = 10,
		minCircleStrafeDistance = 10,
		fleeLeeway = 140,
		velocityPrediction = 30,
	},
	{
		name = "amphraid",
		waterline = -5,
		land = {
			weaponNum = 1,
			skirms = shortRangeSkirmieeArray,
			swarms = lowRangeSwarmieeArray,
			--flees = {},
			idleFlee = shortRangeRaiderIdleFleeArray,
			avoidHeightDiff = explodableFull,
			fightOnlyUnits = shortRangeExplodables,
			circleStrafe = ENABLE_OLD_JINK_STRAFE,
			maxSwarmLeeway = 35,
			swarmLeeway = 30,
			jinkTangentLength = 90,
			stoppingDistance = 25,
			minCircleStrafeDistance = 10,
			fleeLeeway = 140,
			velocityPrediction = 30,
		},
		sea = {
			weaponNum = 2,
			skirms = shortRangeSkirmieeArray,
			swarms = lowRangeSwarmieeArray,
			--flees = {},
			idleFlee = torpedoIdleFleeArray,
			avoidHeightDiff = explodableFull,
			fightOnlyUnits = shortRangeExplodables,
			circleStrafe = ENABLE_OLD_JINK_STRAFE,
			maxSwarmLeeway = 35,
			swarmLeeway = 30,
			jinkTangentLength = 90,
			stoppingDistance = 25,
			minCircleStrafeDistance = 10,
			velocityPrediction = 30,
			fleeLeeway = 180,
		},
	},
	{
		name = "vehraid",
		skirms = diverSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		idleFlee = medRangeRaiderIdleFleeArray,
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
		fleeLeeway = 120,
		idlePushAggressDist = 320,
	},
	{
		name = "hoverscout",
		skirms = shortRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
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
	{
		name = "hoverraid",
		skirms = shortRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		idleFlee = shortRangeRaiderIdleFleeArray,
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		strafeOrderLength = 180,
		maxSwarmLeeway = 40,
		swarmLeeway = 40,
		stoppingDistance = 8,
		skirmOrderDis = 150,
		fleeLeeway = 120,
	},
	{
		name = "hoverheavyraid",
		skirms = shortToRiotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		idleFlee = longRangeRaiderIdleFleeArray,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		strafeOrderLength = 180,
		maxSwarmLeeway = 40,
		swarmLeeway = 50,
		stoppingDistance = 15,
		skirmOrderDis = 150,
	},
	{
		name = "jumpraid",
		skirms = shortToRiotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		idleFlee = longRangeRaiderIdleFleeArray,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		jinkAwayParallelLength = 150,
		maxSwarmLeeway = 100,
		minSwarmLeeway = 200,
		swarmLeeway = 30,
		stoppingDistance = 8,
		velocityPrediction = 20,
		fleeLeeway = 120,
	},
	{
		name = "tankraid",
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		--flees = {},
		idleFlee = veryShortRangeRaiderIdleFleeArray,
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 40,
		swarmLeeway = 30,
		stoppingDistance = 8,
		reloadSkirmLeeway = 1.2,
		skirmOrderDis = 150,
		idlePushAggressDist = 350,
		fleeLeeway = 120,
	},
	{
		name = "tankheavyraid",
		skirms = shortToRiotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		idleFlee = longRangeRaiderIdleFleeArray,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		strafeOrderLength = 180,
		maxSwarmLeeway = 40,
		swarmLeeway = 50,
		stoppingDistance = 15,
		skirmOrderDis = 150,
	},
	{
		name = "amphimpulse",
		skirms = riotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		idleFlee = longRangeRaiderIdleFleeArray,
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 40,
		skirmLeeway = 30,
		minCircleStrafeDistance = 10,
		velocityPrediction = 20
	},
	{
		name = "shiptorpraider",
		skirms = shortRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		idleFlee = Union(shortRangeRaiderIdleFleeArray, NameToDefID({"subraider"})),
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
	{
		name = "shipriot",
		skirms = diverSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
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
	{
		name = "cloakriot",
		skirms = riotRangeSkirmieeArray,
		--swarms = {},
		--flees = {},
		idleFlee = longRangeRiotIdleFleeArray,
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = 20,
		velocityPrediction = 20,
		idlePushAggressDist = 100,
		idleChaseEnemyLeeway = 200,
		idleCommitDistMult = 0.5,
		idleEnemyDistMult = 0.5,
	},
	{
		name = "jumpcon",
		skirms = lowMedRangeSkirmieeArray,
		--swarms = {},
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = 0,
		velocityPrediction = 20,
	},
	{
		name = "spiderriot",
		skirms = lowMedRangeSkirmieeArray,
		--swarms = {},
		--flees = {},
		idleFlee = medRangeRiotIdleFleeArray,
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = 0,
		velocityPrediction = 20,
		idlePushAggressDist = 100,
		idleChaseEnemyLeeway = 200,
		idleCommitDistMult = 0.5,
		idleEnemyDistMult = 0.5,
	},
	{
		name = "spideremp",
		skirms = riotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		idleFlee = shortRangeRiotIdleFleeArray,
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		circleStrafe = ENABLE_OLD_JINK_STRAFE,
		maxSwarmLeeway = 40,
		skirmLeeway = 30,
		minCircleStrafeDistance = 10,
		velocityPrediction = 20,
		idlePushAggressDist = 200,
	},
	{
		name = "shieldriot",
		skirms = riotRangeSkirmieeArray,
		--swarms = {},
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = 50,
		velocityPrediction = 20,
	},
	{
		name = "vehriot",
		skirms = lowMedRangeSkirmieeArray,
		--swarms = {},
		--flees = {},
		idleFlee = skirmRangeRiotIdleFleeArray,
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = -30,
		stoppingDistance = 5,
		fightOnlyOverride = {
			skirmLeeway = 10,
			stoppingDistance = 10,
		},
		idlePushAggressDist = 100,
		idleChaseEnemyLeeway = 200,
		idleCommitDistMult = 0.5,
		idleEnemyDistMult = 0.5,
	},
	{
		name = "shieldfelon",
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = 50,
		stoppingDistance = 5,
		skirmBlockedApproachFrames = 40,
	},
	{
		name = "hoverriot",
		skirms = lowMedRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		idleFlee = skirmRangeRiotIdleFleeArray,
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
		idlePushAggressDist = 100,
		idleChaseEnemyLeeway = 200,
		idleCommitDistMult = 0.5,
		idleEnemyDistMult = 0.5,
	},
	{
		name = "tankriot",
		skirms = medRangeSkirmieeArray,
		--swarms = {},
		--flees = {},
		idleFlee = skirmRangeRiotIdleFleeArray,
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
		idlePushAggressDist = 100,
		idleChaseEnemyLeeway = 200,
		idleCommitDistMult = 0.5,
		idleEnemyDistMult = 0.5,
	},
	{
		name = "amphriot",
		waterline = -5,
		land = {
			weaponNum = 1,
			skirms = riotRangeSkirmieeArray,
			--swarms = {},
			--flees = {},
			idleFlee = medRangeRiotIdleFleeArray,
			avoidHeightDiff = explodableFull,
			fightOnlyUnits = shortRangeExplodables,
			circleStrafe = ENABLE_OLD_JINK_STRAFE,
			maxSwarmLeeway = 40,
			skirmLeeway = 30,
			minCircleStrafeDistance = 10,
			idlePushAggressDist = 100,
			idleChaseEnemyLeeway = 200,
			idleCommitDistMult = 0.5,
			idleEnemyDistMult = 0.5,
		},
		sea = {
			weaponNum = 2,
			--skirms = {},
			--swarms = {},
			--flees = {},
			fightOnlyUnits = shortRangeExplodables,
			circleStrafe = ENABLE_OLD_JINK_STRAFE,
			maxSwarmLeeway = 40,
			skirmLeeway = 30,
			minCircleStrafeDistance = 10,
		},
	},
	{
		name = "ampharty",
		waterline = -5,
		land = {
			weaponNum = 1,
			skirms = artyRangeSkirmieeArray,
			--swarms = {},
			--flees = {},
			fightOnlyUnits = medRangeExplodables,
			skirmRadar = true,
			maxSwarmLeeway = 10,
			minSwarmLeeway = 130,
			skirmLeeway = 40,
		},
		sea = {
			weaponNum = 2,
			skirms = medRangeSkirmieeArray,
			--swarms = {},
			--flees = {},
			avoidHeightDiff = explodableFull,
			fightOnlyUnits = medRangeExplodables,
			skirmRadar = true,
			maxSwarmLeeway = 10,
			minSwarmLeeway = 130,
			skirmLeeway = 40,
		},
	},
	{
		name = "shipscout", -- scout boat
		skirms = lowMedRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		flees = subfleeables,
		idleFlee = shortRangeRaiderIdleFleeArray,
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
	{
		name = "shipassault",
		skirms = lowMedRangeSkirmieeArray,
		--swarms = {},
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 0,
		skirmLeeway = 5,
		stoppingDistance = 10,
		skirmOrderDis = 30,
		velocityPrediction = 30,
	},
	{
		name = "hoverdepthcharge",
		waterline = -5,
		floatWaterline = true,
		land = {
			weaponNum = 2,
			--skirms = {},
			--swarms = {},
			--flees = {},
			skirmEverything = true,
			skirmLeeway = 0,
			stoppingDistance = 8,
			skirmOrderDis = 150,
		},
		sea = {
			weaponNum = 1,
			skirms = lowMedRangeSkirmieeArray,
			--swarms = {},
			--flees = {},
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
	{
		name = "cloakassault",
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 90,
		skirmLeeway = 40,
		skirmBlockedApproachFrames = 10,
	},
	{
		name = "shieldassault",
		skirms = riotRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 50,
		minSwarmLeeway = 120,
		skirmLeeway = 40,
	},
	{
		name = "spiderassault",
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 50,
		minSwarmLeeway = 120,
		skirmLeeway = 40,
	},
	{
		name = "shipraider",
		skirms = riotRangeSkirmieeArray,
		swarms = lowRangeSwarmieeArray,
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 90,
		skirmLeeway = 60,
	},
	{
		name = "vehassault",
		skirms = riotRangeSkirmieeArray,
		--swarms = {},
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		maxSwarmLeeway = 50,
		minSwarmLeeway = 120,
		skirmLeeway = 40,
	},
	{
		name = "tankassault",
		skirms = lowMedRangeSkirmieeArray,
		--swarms = {},
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		skirmOrderDis = 220,
		skirmLeeway = 50,
	},
	
	-- med range skirms
	{
		name = "cloakskirm",
		skirms = Union(medRangeSkirmieeArray, NameToDefID({"turretriot"})),
		swarms = medRangeSwarmieeArray,
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 130,
		skirmLeeway = 10,
		skirmBlockedApproachFrames = 40,
	},
	{
		name = "jumpskirm",
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130,
		skirmOrderDis = 150,
		skirmLeeway = 5,
		skirmBlockedApproachFrames = 60,
	},
	{
		name = "striderdante",
		skirms = medRangeSkirmieeArray,
		--swarms = {},
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		skirmLeeway = 40,
	},
	{
		name = "amphfloater",
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		--flees = {},
		avoidHeightDiff = explodableFull,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 130,
		skirmLeeway = 10,
		skirmBlockedApproachFrames = 40,
	},
	{
		name = "hoverskirm",
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		--flees = {},
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
	{
		name = "tankheavyassault",
		skirms = medRangeSkirmieeArray,
		--swarms = {},
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = shortRangeExplodables,
		skirmOrderDis = 220,
		skirmLeeway = 50,
		skirmBlockedApproachFrames = 60,
	},
	{
		name = "gunshipskirm",
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		skirmOrderDis = 120,
		selfVelocityPrediction = true,
		velocityPrediction = 30,
	},
	
	-- long range skirms
	{
		name = "jumpblackhole",
		skirms = longRangeSkirmieeArray,
		swarms = longRangeSwarmieeArray,
		--flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 130,
		skirmLeeway = 20,
		skirmBlockedApproachFrames = 40,
	},
	{
		name = "shieldskirm",
		skirms = longRangeSkirmieeArray,
		swarms = longRangeSwarmieeArray,
		--flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 130,
		skirmLeeway = 10,
		skirmBlockedApproachFrames = 40,
	},
	{
		name = "spiderskirm",
		skirms = longRangeSkirmieeArray,
		swarms = longRangeSwarmieeArray,
		--flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130,
		skirmLeeway = 10,
		skirmBlockedApproachFrames = 40,
	},
	{
		name = "amphassault",
		skirms = longRangeSkirmieeArray,
		swarms = longRangeSwarmieeArray,
		--flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130,
		skirmLeeway = 20,
		skirmBlockedApproachFrames = 40,
	},
	{
		name = "gunshipkrow",
		skirms = medRangeSkirmieeArray,
		swarms = medRangeSwarmieeArray,
		--flees = {},
		avoidHeightDiff = explodableFull,
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130,
		skirmLeeway = 20,
	},
	{
		name = "vehcapture",
		skirms = longRangeSkirmieeArray,
		swarms = longRangeSwarmieeArray,
		--flees = {},
		fightOnlyUnits = medRangeExplodables,
		maxSwarmLeeway = 30,
		minSwarmLeeway = 130,
		skirmLeeway = -5,
		skirmOrderDis = 120,
		velocityPrediction = 135,
		skirmBlockedApproachFrames = 40,
		skirmBlockApproachHeadingBlock = -0.3,
	},
	{
		name = "shipskirm",
		skirms = longRangeSkirmieeArray,
		swarms = longRangeSwarmieeArray,
		--flees = {},
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
	{
		name = "vehsupport",
		defaultAIState = 0,
		skirms = slasherSkirmieeArray,
		--swarms = {},
		--flees = {},
		skirmLeeway = -400,
		skirmOrderDis = 700,
		skirmKeepOrder = true,
		velocityPrediction = 10,
		skirmOnlyNearEnemyRange = 80
	},
	
	-- arty range skirms
	{
		name = "cloaksnipe",
		skirms = allMobileGround,
		skirmRadar = true,
		--swarms = {},
		--flees = {},
		skirmLeeway = 40,
		skirmBlockedApproachOnFight = true,
		skirmBlockedApproachFrames = 120,
	},
	{
		name = "veharty",
		skirms = allMobileGround,
		skirmRadar = true,
		--swarms = {},
		--flees = {},
		skirmLeeway = 20,
		skirmOrderDis = 200,
		skirmOrderDisMin = 100, -- Make it turn around.
	},
	{
		name = "vehheavyarty",
		skirms = allMobileGround,
		skirmRadar = true,
		--swarms = {},
		--flees = {},
		skirmLeeway = 100,
		stoppingDistance = -80,
		velocityPrediction = 0,
	},
	{
		name = "tankarty",
		skirms = allMobileGround,
		skirmRadar = true,
		--swarms = {},
		--flees = {},
		skirmLeeway = 200,
		skirmKeepOrder = true,
		stoppingDistance = -180,
		velocityPrediction = 0,
		skirmOrderDis = 250,
		skirmOnlyNearEnemyRange = 120,
	},
	{
		name = "striderarty",
		skirms = allMobileGround,
		skirmRadar = true,
		--swarms = {},
		--flees = {},
		skirmLeeway = 100,
	},
	{
		name = "cloakarty",
		skirms = allMobileGround,
		--swarms = {},
		--flees = {},
		skirmRadar = true,
		skirmLeeway = 40,
		skirmBlockedApproachFrames = 40,
	},
	{
		name = "jumparty",
		skirms = allMobileGround,
		--swarms = {},
		--flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130,
		skirmLeeway = 20,
	},
	{
		name = "shieldarty",
		skirms = Union(artyRangeSkirmieeArray, skirmableAir),
		--swarms = {},
		--flees = {},
		fightOnlyUnits = medRangeExplodables,
		skirmRadar = true,
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130,
		skirmLeeway = 150,
	},
	{
		name = "hoverarty",
		skirms = allMobileGround,
		--swarms = {},
		--flees = {},
		skirmRadar = true,
		skirmKeepOrder = true,
		skirmLeeway = 150,
		skirmOrderDis = 200,
		stoppingDistance = -100,
		velocityPrediction = 0,
	},
	{
		name = "striderbantha",
		defaultAIState = 0,
		skirms = allMobileGround,
		--swarms = {},
		--flees = {},
		skirmRadar = true,
		skirmLeeway = 120,
	},
	{
		name = "shiparty",
		skirms = allMobileGround,
		--swarms = {},
		--flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130,
		skirmLeeway = 40,
	},
	
	-- cowardly support units
	--[[
	{
		name = "example",
		--skirms = {},
		--swarms = {},
		--flees = {},
		fleeCombat = true,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
	},
	--]]

	-- support
	{
		name = "cloakjammer",
		--skirms = {},
		--swarms = {},
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 400,
	},
	{
		name = "shieldshield",
		--skirms = {},
		--swarms = {},
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 450,
	},
	
	-- mobile AA
	{
		name = "cloakaa",
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
	{
		name = "shieldaa",
		skirms = skirmableAir,
		swarms = brawler,
		flees = armedLand,
		minSwarmLeeway = 500,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
        skirmLeeway = 50,
	},
	{
		name = "vehaa",
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
	{
		name = "jumpaa",
		skirms = skirmableAir,
		swarms = brawler,
		flees = armedLand,
		minSwarmLeeway = 300,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
        skirmLeeway = 50,
	},
	{
		name = "hoveraa",
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
	{
		name = "spideraa",
		skirms = skirmableAir,
		swarms = brawler,
		flees = armedLand,
		minSwarmLeeway = 300,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
		skirmLeeway = 50,
	},
	{
		name = "tankaa",
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
	{
		name = "amphaa",
		skirms = skirmableAir,
		swarms = brawler,
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
		skirmLeeway = 50,
		skirmOrderDis = 200,
	},
	{
		name = "gunshipaa",
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
	{
		name = "shipaa",
		skirms = skirmableAir,
		--swarms = {},
		--flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130,
		skirmLeeway = 40,
	},
	
	-- Flying scouts
	{
		name = "planelightscout",
		--skirms = {},
		--swarms = {},
		--flees = {},
		searchRange = 1000,
		fleeEverything = true,
		minFleeRange = 600, -- Avoid enemies standing in front of Pickets
		fleeLeeway = 650,
		fleeDistance = 650,
	},
	{
		name = "planescout",
		--skirms = {},
		--swarms = {},
		--flees = {},
		searchRange = 1200,
		fleeEverything = true,
		minFleeRange = 600, -- Avoid enemies standing in front of Pickets
		fleeLeeway = 850,
		fleeDistance = 850,
	},
	
	-- only handle idleness
	{
		name = "shieldscout",
		onlyIdleHandling = true,
	},
	{
		name = "cloakheavyraid",
		onlyIdleHandling = true,
	},
	{
		name = "gunshipraid",
		onlyIdleHandling = true,
		idleFlee = longRangeRaiderIdleFleeArray,
		idleChaseEnemyLeeway = 350,
	},
	{
		name = "gunshipheavyskirm",
		onlyIdleHandling = true,
	},
	{
		name = "gunshipassault",
		onlyIdleHandling = true,
	},
	{
		name = "hoverassault",
		onlyIdleHandling = true,
	},
	{
		name = "spidercrabe",
		onlyIdleHandling = true,
	},
	{
		name = "jumpassault",
		onlyIdleHandling = true,
	},
	{
		name = "tankcon",
		onlyIdleHandling = true,
	},
	{
		name = "tankheavyarty",
		onlyIdleHandling = true,
	},
	{
		name = "subraider",
		onlyIdleHandling = true,
		idleFlee = torpedoIdleFleeArray,
	},
	{
		name = "striderantiheavy",
		onlyIdleHandling = true,
	},
	{
		name = "striderscorpion",
		onlyIdleHandling = true,
	},
	{
		name = "striderdetriment",
		onlyIdleHandling = true,
	},
	{
		name = "shipheavyarty",
		onlyIdleHandling = true,
	},
	
	-- chickens
	{
		name = "chicken_tiamat",
		--skirms = {},
		--swarms = {},
		--flees = {},
		hugs = allGround,
		hugRange = 100,
	},
	{
		name = "chicken_dragon",
		--skirms = {},
		--swarms = {},
		--flees = {},
		hugs = allGround,
		hugRange = 150,
	},
	{
		name = "chickenlandqueen",
		--skirms = {},
		--swarms = {},
		--flees = {},
		hugs = allGround,
		hugRange = 150,
	},
	
	-- Externally handled units
	{
		name = "energysolar",
		externallyHandled = true,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Load Ai behaviour

local function GetBehaviourTable(behaviourData, ud)
	local weaponRange
	if behaviourData.weaponNum and ud.weapons[behaviourData.weaponNum] then
		local weaponDefID = ud.weapons[behaviourData.weaponNum].weaponDef
		weaponRange = WeaponDefs[weaponDefID].range
	else
		weaponRange = ud.maxWeaponRange
	end
	
	behaviourData.weaponNum               = (behaviourData.weaponNum or 1)
	behaviourData.searchRange             = (behaviourData.searchRange or math.max(weaponRange + 100, 800))
	behaviourData.idleSearchRange         = 500
	
	-- Used for idle leash
	behaviourData.leashAgressRange        = 400
	behaviourData.leashEnemyRangeLeeway   = 20
	behaviourData.idlePushAggressDistSq   = (behaviourData.idlePushAggressDist or math.min(500, weaponRange + 50))^2
	behaviourData.idleChaseEnemyLeeway    = behaviourData.idleChaseEnemyLeeway or 350
	behaviourData.idleCommitDist          = behaviourData.idleCommitDist or math.min(500, weaponRange*0.3 + 150)
	behaviourData.idleCommitDistMult      = behaviourData.idleCommitDistMult or 0.15
	behaviourData.idleEnemyDistMult       = behaviourData.idleEnemyDistMult or 0.85
	
	local hasFlee = (behaviourData.flees or behaviourData.fleeEverything or behaviourData.fleeCombat or behaviourData.idleFlee or behaviourData.idleFleeCombat)
	local hasSkirm = (behaviourData.skirms or behaviourData.skirmRadar or behaviourData.skirmEverything)
	local hasSwarm = (behaviourData.alwaysJinkFight or behaviourData.swarms)
	
	if hasFlee then
		behaviourData.fleeOrderDis            = (behaviourData.fleeOrderDis or 120)
		behaviourData.fleeLeeway              = (behaviourData.fleeLeeway or 100)
		behaviourData.fleeDistance            = (behaviourData.fleeDistance or 120)
		behaviourData.minFleeRange            = (behaviourData.minFleeRange or 0) - behaviourData.fleeLeeway
	end
	
	if hasFlee or hasSkirm then
		-- Used by skirm and flee.
		behaviourData.skirmRange              = weaponRange
		behaviourData.stoppingDistance        = (behaviourData.stoppingDistance or 0)
		behaviourData.velocityPrediction      = (behaviourData.velocityPrediction or behaviourDefaults.defaultVelocityPrediction)
	end
	
	if hasSkirm then
		behaviourData.mySpeed                 = ud.speed/30
		behaviourData.skirmOrderDis           = (behaviourData.skirmOrderDis or behaviourDefaults.defaultSkirmOrderDis)
		behaviourData.hugRange                = (behaviourData.hugRange or behaviourDefaults.defaultHugRange)
		behaviourData.skirmLeeway             = (behaviourData.skirmLeeway or 0)
	end
	
	if hasSwarm then
		behaviourData.maxSwarmRange           = weaponRange - (behaviourData.maxSwarmLeeway or 0)
		behaviourData.minSwarmRange           = weaponRange - (behaviourData.minSwarmLeeway or weaponRange/2)
		behaviourData.minCircleStrafeDistance = weaponRange - (behaviourData.minCircleStrafeDistance or behaviourDefaults.defaultMinCircleStrafeDistance)
		behaviourData.jinkTangentLength       = (behaviourData.jinkTangentLength or behaviourDefaults.defaultJinkTangentLength)
		behaviourData.jinkParallelLength      = (behaviourData.jinkParallelLength or behaviourDefaults.defaultJinkParallelLength)
		behaviourData.jinkAwayParallelLength  = (behaviourData.jinkAwayParallelLength or behaviourDefaults.defaultJinkAwayParallelLength)
		behaviourData.localJinkOrder          = (behaviourData.alwaysJinkFight or behaviourDefaults.defaultLocalJinkOrder)
		behaviourData.strafeOrderLength       = (behaviourData.strafeOrderLength or behaviourDefaults.defaultStrafeOrderLength)
		behaviourData.swarmLeeway             = (behaviourData.swarmLeeway or 50)
	end
	
	if behaviourData.fightOnlyOverride then
		for k, v in pairs(behaviourData) do
			if not (k == "fightOnlyOverride" or behaviourData.fightOnlyOverride[k]) then
				behaviourData.fightOnlyOverride[k] = v
			end
		end
		behaviourData.fightOnlyOverride = GetBehaviourTable(behaviourData.fightOnlyOverride, ud)
	end
	
	return behaviourData
end

local function LoadBehaviour()
	local unitAIBehaviour = {}
	for i = 1, #behaviourConfig do
		local behaviourData = behaviourConfig[i]
		local ud = UnitDefNames[behaviourConfig[i].name]
		
		if ud then
			if behaviourData.land and behaviourData.sea then
				unitAIBehaviour[ud.id] = {
					defaultAIState = (behaviourData.defaultAIState or behaviourDefaults.defaultState),
					waterline = (behaviourData.waterline or 0),
					floatWaterline = behaviourData.floatWaterline,
					land = GetBehaviourTable(behaviourData.land, ud),
					sea = GetBehaviourTable(behaviourData.sea, ud),
				}
			else
				unitAIBehaviour[ud.id] = GetBehaviourTable(behaviourData, ud)
				unitAIBehaviour[ud.id].defaultAIState = (behaviourData.defaultAIState or behaviourDefaults.defaultState)
			end
		end
	end
	
	return unitAIBehaviour
end

return LoadBehaviour()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
