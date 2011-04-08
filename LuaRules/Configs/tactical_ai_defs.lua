--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function merge(t1, t2)
	for i, v in pairs(t2) do
		t1[i] = v
	end
end

-- swarm arrays
-- these are not strictly required they just help with inputting the units

local longRangeSwarmieeArray = { 
	["cormart"] = true,
	["firewalker"] = true,
	["armsptk"] = true,
	["corstorm"] = true,
	["armroy"] = true,
	["armham"] = true,
	["armpb"] = true,
}

local medRangeSwarmieeArray = { 
	["armrock"] = true,
	["chickens"] = true,
}

local lowRangeSwarmieeArray = {
	["corthud"] = true,
	["spiderassault"] = true,
	["corraid"] = true,
	["armzeus"] = true,
	["logkoda"] = true,
	
	["correap"] = true,
	["corgol"] = true,
	
	["armcrabe"] = true,
	["armmanni"] = true,
	
	["chickenr"] = true,
	["chickenblobber"] = true,
	["armsnipe"] = true, -- only worth swarming sniper at low range, too accurate otherwise.
}

merge(medRangeSwarmieeArray,longRangeSwarmieeArray)
merge(lowRangeSwarmieeArray,medRangeSwarmieeArray)


-- skirm arrays
-- these are not strictly required they just help with inputting the units

local veryShortRangeSkirmieeArray = {
	["corcan"] = true,
	["spherepole"] = true,
	["armtick"] = true,
	["puppy"] = true,
	["corroach"] = true,
	["chicken"] = true,
	["chickena"] = true,
	["chicken_tiamat"] = true,
}

local shortRangeSkirmieeArray = {
	["armflea"] = true,
	["armpw"] = true,
	["corfav"] = true,
	["corgator"] = true,
	["corpyro"] = true,
	["logkoda"] = true,
	["corsumo"] = true,
}

local riotRangeSkirmieeArray = {
	["corak"] = true,
	["panther"] = true,
	["corsh"] = true,
	["coresupp"] = true,
	["armcomdgun"] = true,
	["dante"] = true,
}

local medRangeSkirmieeArray = {
	["armcom"] = true,
	["armadvcom"] = true,
	["corcom"] = true,
	["coradvcom"] = true,
	["commsupport"] = true,
	["commadvsupport"] = true,
	
	["armwar"] = true,
	["armzeus"] = true,
	
	["arm_venom"] = true,
	["spiderassault"] = true,
	
	["corraid"] = true,
	["corlevlr"] = true,
	
	
	["hoverriot"] = true,
	["hoverassault"] = true,
	
	["cormak"] = true,
	["corthud"] = true,

	["correap"] = true,
	["corgol"] = true,
	["tawf114"] = true, -- banisher
}

for name,data in pairs(UnitDefNames) do -- add all comms to mid range skirm
	if data.isCommander then
		medRangeSkirmieeArray[name] = true
	end
end

local longRangeSkirmieeArray = {
	["armrock"] = true,
	["nsclash"] = true, -- hover janus
	["capturecar"] = true,
	["chickenc"] = true,
	["armbanth"] = true,
	["gorg"] = true,
}

local artyRangeSkirmieeArray = {
	["armsptk"] = true,
	["corstorm"] = true,
	["chicken_sporeshooter"] = true,
}

merge(shortRangeSkirmieeArray,veryShortRangeSkirmieeArray)
merge(riotRangeSkirmieeArray,shortRangeSkirmieeArray)
merge(medRangeSkirmieeArray,riotRangeSkirmieeArray)
merge(longRangeSkirmieeArray,medRangeSkirmieeArray)
merge(artyRangeSkirmieeArray,longRangeSkirmieeArray)


-- Things that are fled by some things

local fleeables = {
	["corllt"] = true,
	["armdeva"] = true,
	["armartic"] = true,
	["corgrav"] = true,
	
	["armcom"] = true,
	["armadvcom"] = true,
	["corcom"] = true,
	["coradvcom"] = true,
	
	["armwar"] = true,
	["armzeus"] = true,
	
	["arm_venom"] = true,
	
	["cormak"] = true,
	
	["corlevlr"] = true,
	["capturecar"] = true,

	["hoverriot"] = true, -- mumbo
	["corsumo"] = true,
}

local armedLand = {}
for name,data in pairs(UnitDefNames) do
	if data.canAttack and (not data.canFly) 
	and data.weapons[1] and data.weapons[1].onlyTargets.land then
		armedLand[name] = true 
	end
end

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
		skirms = veryShortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 35, 
		swarmLeeway = 50, 
		jinkTangentLength = 140, 
		stoppingDistance = 15,
	},
	
	["armflea"] = {
		skirms = veryShortRangeSkirmieeArray, 
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
		stoppingDistance = 15,
		minCircleStrafeDistance = 10,
	},
	["corgator"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		strafeOrderLength = 120,
		skirmLeeway = 60,
		maxSwarmLeeway =180, 
		minSwarmLeeway = 300, 
		swarmLeeway = 40, 
		stoppingDistance = 8
	},
	
	["corsh"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		strafeOrderLength = 180,
		maxSwarmLeeway = 40, 
		swarmLeeway = 40, 
		stoppingDistance = 8
	},
  
	["corpyro"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 100, 
		minSwarmLeeway = 200, 
		swarmLeeway = 30, 
		stoppingDistance = 8
	},
	
	["logkoda"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		swarmLeeway = 30, 
		stoppingDistance = 8
	},
  
	["panther"] = {
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		strafeOrderLength = 180,
		maxSwarmLeeway = 40, 
		swarmLeeway = 50, 
		stoppingDistance = 15
	},

	["armpt"] = { -- scout boat
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		maxSwarmLeeway = 40, 
		swarmLeeway = 30, 
		stoppingDistance = 8
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
		skirms = riotRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 50, 
		minSwarmLeeway = 120, 
		skirmLeeway = 40, 
	},
	["dante"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		skirmLeeway = 40, 
	},	
	["coresupp"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 90, 
		skirmLeeway = 60, 
	},		
	
	-- med range skirms
	["armbanth"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		skirmLeeway = 120, 
	},	
	
	["armrock"] = {
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
	},
	["dclship"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 30, 
	},	
	
	-- long range skirms
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
	["slowmort"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["capturecar"] = {
		skirms = longRangeSkirmieeArray, 
		swarms = longRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 30, 
		minSwarmLeeway = 130, 
		skirmLeeway = 30, 
	},
	
	-- arty range skirms
	["armsnipe"] = {
		skirms = artyRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	
	["corgarp"] = {
		skirms = artyRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	["armham"] = {
		skirms = artyRangeSkirmieeArray, 
		swarms = {}, 
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
	["shieldarty"] = {
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

	-- mobile AA
	["armjeth"] = {
		skirms = {}, 
		swarms = {}, 
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
	},
	["corcrash"] = {
		skirms = {}, 
		swarms = {}, 
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
	},
	["armaak"] = {
		skirms = {}, 
		swarms = {}, 
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
	},
	["hoveraa"] = {
		skirms = {}, 
		swarms = {}, 
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
	},
	["spideraa"] = {
		skirms = {}, 
		swarms = {}, 
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
	},
	["corsent"] = {
		skirms = {}, 
		swarms = {}, 
		flees = armedLand,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 500,
	},
}

return behaviourConfig

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
