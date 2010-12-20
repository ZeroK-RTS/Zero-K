--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


-- swarm arrays
-- these are not strictly required they just help with inputting the units


local lowRangeSwarmieeArray = { 
	"armrock",
	"armham",
	"corstorm",
	"corthud",
	"spiderassault",
  
	"armstump",
	"corraid",
  
	"armsptk",
	"armzeus",
	"armcrabe",
	"cormort",
	"cormortgold",
	"punisher",
	"firewalker",
  
	"armbull",
	"armmanni",
	"correap",
	"corgol",
	"cormart",
  
	"armanac",
	"corseal",
	
	"hoverartillery",
	"hoverassault",
	
	"chickenr",
	"chickenblobber",
	
	"armroy",
	"armsub",
	"corsub",
}

local medRangeSwarmieeArray = { 
	"armrock",
	"armham",
	"corstorm",
	"armsptk",
	"cormort",
	"cormortgold",
	"punisher",
	"firewalker",
  
	"cormart",
	"hoverartillery",
	"hoverassault",
	
	"chickenr",
	"chickenblobber",
	
	"armroy",
	"armsub",
	"corsub",
}

local longRangeSwarmieeArray = { 
	"cormart",
	
	"hoverartillery",
	"hoverassault",
}

-- skirm arrays
-- these are not strictly required they just help with inputting the units

local artyRangeSkirmieeArray = {
	"corcan",
	"armtick",
	"corroach",
	"chicken",
	"chickena",
	"chicken_tiamat",
	
	"armpw",
	"spherepole",
	"corak",
	"armfav",
	"corfav",
	"armflash",
	"corgator",
	"corpyro",
	"panther",
	"armst",
	"logkoda",
	
	"armcom",
	"armcomdgun",
	"corcom",
	"corcomdgun",
	
	"armwar",
	"armzeus",
	"arm_venom",
	"cormak",
	"corlevlr",
	"capturecar",
	"armwar",
	"armstump",
	"corraid",
	"tawf003", -- mumbo
	"tawf114", -- banisher
	"corthud",
	"spiderassault",
	
	"armrock",
	"corstorm",
	"armjanus",
	"chickens",
	"chickenc",
	
	"armsptk",
	"cormort",
	"armsnipe",
	
	"armmist",
	"cormist",
	"chicken_sporeshooter",
	
	"hoverriot",
	"hoverassault",
	"nsaclash",
	"corsh",
	
	"decade",
	"coresupp",
}

local longRangeSkirmieeArray = {
	"corcan",
	"armtick",
	"corroach",
	"chicken",
	"chickena",
	"chicken_tiamat",
	
	"armpw",
	"corak",
	"armfav",
	"corfav",
	"armflash",
	"corgator",
	"corpyro",
	"panther",
	"armst",
	"logkoda",
	
	"armcom",
	"armcomdgun",
	"corcom",
	"corcomdgun",
	
	"armwar",
	"armzeus",
	"arm_venom",
	"cormak",
	"corlevlr",
	"capturecar",
	"armwar",
	"armstump",
	"armbull",
	"correap",
	"corgol",
	"corraid",
	"tawf003", -- mumbo
	"tawf114", -- banisher
	"corthud",
	"spiderassault",
	
	"armrock",
	"corstorm",
	"armjanus",
	"chickens",
	"chickenc",
	
	"hoverriot",
	"hoverassault",
	"nsaclash",
	"corsh",
	
	"decade",
	"coresupp",
}

local medRangeSkirmieeArray = {
	"corcan",
	"armtick",
	"corroach",
	"chicken",
	"chickena",
	"chicken_tiamat",
	
	"armpw",
	"spherepole",
	"corak",
	"armfav",
	"corfav",
	"armflash",
	"corgator",
	"corpyro",
	"panther",
	"armst",
	"logkoda",
	
	"armcom",
	"armcomdgun",
	"corcom",
	"corcomdgun",
	
	"armwar",
	"armzeus",
	"arm_venom",
	"cormak",
	"corlevlr",
	"capturecar",
	"tawf003", -- mumbo
	"tawf114", -- banisher
	"corthud",
	"spiderassault",

	"armstump",
	"corraid",
	"armbull",
	"correap",
	"corgol",
	
	"hoverriot",
	"hoverassault",
	"corsh",
	
	"decade",
	"coresupp",
}

local riotRangeSkirmieeArray = {
	"corcan",
	"armtick",
	"corroach",
	"chicken",
	"chickena",
	"chicken_tiamat",
	
	"armcom",
	"armcomdgun",
	"corcom",
	"corcomdgun",
	
	"armpw",
	"spherepole",
	"corak",
	"armfav",
	"corfav",
	"armflash",
	"corgator",
	"corpyro",
	"panther",
	"armst",
	"logkoda",
	
	"corsh",
}

local raiderRangeSkirmieeArray = {
	"corcan",
	"armtick",
	"corroach",
	"chicken",
	"chickena",
	"chicken_tiamat",
}

local fleeables = {
	"armllt",
	"corllt",
	"armdeva",
	"armartic",
	"corgrav",
	"corpre",
	"armwar",
	"armzeus",
	"arm_venom",
	"cormak",
	"corlevlr",
	"capturecar",
	"armwar",
	"armstump",
	"armbull",
	"correap",
	"corgol",
	"corraid",
	"tawf003", -- mumbo
	"tawf114", -- banisher
	"corthud",
	"spiderassault",
	"armcom",
	"armcomdgun",
	"corcom",
	"corcomdgun",
	"commrecon",
	"commsupport",
	"decade",
	"coresupp",
	"armcrus",
	"corcrus",
}


-- searchRange(defaults to 800): max range of GetNearestEnemy for the unit.
-- defaultAIState (defaults to 1): (1 or 0) state of AI when unit is initialised

--*** skirms(defaults to empty): the table of units that this unit will attempt to keep at max range
-- skirmEverything (defaults to false): Skirms everything (does not skirm radar with this enabled only)
-- skirmLeeway: (Weapon range - skirmLeeway) = distance that the unit will try to keep from units while skirming
-- stoppingDistance (defaults to 0): (skirmLeeway - stoppingDistance) = max distance from target unit that move commands can be given while skirming
-- skirmRadar (defaults to false): Skirms radar dots
-- skirmOrderDis (defaults to 120): max distance the move order is from the unit when skirming


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


--*** flees(defaults to empty): the table of units that this unit will flee like the coward it is!!!
-- fleeCombat (defaults to false): if true will flee everything without catergory UNARMED
-- fleeLeeway (defaults to 100): adds to enemy range when fleeing
-- fleeDistance (defaults to 100): unit will flee to enemy range + fleeDistance away from enemy
-- fleeRadar (defaults to false): does the unit flee radar dots?
-- minFleeRange (defaults to 0): minumun range at which the unit will flee, will flee at higher range if the attacking unit outranges it
-- fleeOrderDis (defaults to 120): max distance the move order is from the unit when fleeing


--- Array loaded into gadget 
local behaviourConfig = { 
	
	defaultJinkTangentLength = 80,
	defaultJinkParallelLength = 150,
	defaultStrafeOrderLength = 100,
	defaultMinCircleStrafeDistance = 40,
	
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
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		jinkTangentLength = 100, 
		minCircleStrafeDistance = 0,
		minSwarmLeeway = 100,
		swarmLeeway = 30, 
		alwaysJinkFight = true,	
	},
  
	["armpw"] = {
		skirms = raiderRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 35, 
		swarmLeeway = 50, 
		jinkTangentLength = 140, 
		stoppingDistance = 15,
	},
	
	["armflea"] = {
		skirms = raiderRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = fleeables,
		circleStrafe = true, 
		maxSwarmLeeway = 5, 
		swarmLeeway = 30, 
		stoppingDistance = 0,
		strafeOrderLength = 100,
		minCircleStrafeDistance = 20,
		fleeLeeway = 150,
		fleeDistance = 150,
	},
	
	["corak"] = {
		skirms = raiderRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 35, 
		swarmLeeway = 30, 
		jinkTangentLength = 140, 
		stoppingDistance = 15,
		minCircleStrafeDistance = 10,
	},

	["armfav"] = { -- jeffy
		skirms = raiderRangeSkirmieeArray, 
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
	
	["corfav"] = { -- weasel
		skirms = raiderRangeSkirmieeArray, 
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
  
	["armflash"] = {
		skirms = raiderRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		strafeOrderLength = 180,
		maxSwarmLeeway = 40, 
		swarmLeeway = 40, 
		stoppingDistance = 8
	},
	
	["corgator"] = {
		skirms = raiderRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		strafeOrderLength = 180,
		skirmLeeway = 60,
		maxSwarmLeeway = 40, 
		swarmLeeway = 40, 
		stoppingDistance = 8
	},
	
	["corsh"] = {
		skirms = raiderRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		strafeOrderLength = 180,
		maxSwarmLeeway = 40, 
		swarmLeeway = 40, 
		stoppingDistance = 8
	},
  
	["armfast"] = {
		skirms = raiderRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		swarmLeeway = 30, 
		stoppingDistance = 8
	},
	
	["corpyro"] = {
		skirms = raiderRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 160, 
		swarmLeeway = 30, 
		stoppingDistance = 8
	},
	
	["armst"] = {
		skirms = raiderRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		swarmLeeway = 30, 
		stoppingDistance = 8
	},
	
	["logkoda"] = {
		skirms = raiderRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		swarmLeeway = 30, 
		stoppingDistance = 8
	},
  
	["panther"] = {
		skirms = raiderRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		strafeOrderLength = 180,
		maxSwarmLeeway = 40, 
		swarmLeeway = 50, 
		stoppingDistance = 15
	},

	["armpt"] = { -- scout boat
		skirms = raiderRangeSkirmieeArray, 
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
	
	-- riots
	["armwar"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = 0, 
	},
	["arm_venom"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true,
		maxSwarmLeeway = 40,
		skirmLeeway = 30, 
		minCircleStrafeDistance = 10,
	},
	["cormak"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = 50, 
	},
	["corlevlr"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = -30, 
		stoppingDistance = 5
	},
	["tawf003"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = -30, 
		stoppingDistance = 5
	},
	["hoverriot"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = -30, 
		stoppingDistance = 5
	},
	["tawf114"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = -30, 
		stoppingDistance = 10
	},
		
	--assaults
	["armzeus"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 90, 
		skirmLeeway = 20, 
	},
	["corthud"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 50, 
		minSwarmLeeway = 120, 
		skirmLeeway = 40, 
	},
	["spiderassault"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 50, 
		minSwarmLeeway = 120, 
		skirmLeeway = 40, 
	},
	["armraz"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		skirmLeeway = 40, 
	},	
	["corkarg"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		skirmLeeway = 40, 
	},
	["dante"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		skirmLeeway = 40, 
	},	
	["armbanth"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		skirmLeeway = 120, 
	},	
	["decade"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 90, 
		skirmLeeway = 20, 
	},	
	["coresupp"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 90, 
		skirmLeeway = 20, 
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
	["corstorm"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["armjanus"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 30, 
	},
	["nsaclash"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 30, 
	},
	
	-- long range skirms
	["armsptk"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["armsnipe"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["cormort"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["cormortgold"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["slowmort"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["corgarp"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	
	-- arty range skirms
	["corhrk"] = {
		skirms = artyRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["armham"] = {
		skirms = artyRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 40, 
	},
	["punisher"] = {
		skirms = artyRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 40, 
	},
	["firewalker"] = {
		skirms = artyRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 40, 
	},	
	-- cowardly support units
	["arm_marky"] = {
		skirms = {}, 
		swarms = {}, 
		flees = {},
		fleeCombat = true,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
	},
	
	["corvrad"] = {
		skirms = {}, 
		swarms = {}, 
		flees = {},
		fleeCombat = true,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
	},
	
}

return behaviourConfig

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
