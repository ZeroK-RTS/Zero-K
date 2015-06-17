--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function merge(t1, t2)
	for i, v in pairs(t2) do
		t1[i] = v
	end
end

local function NameTableToUnitDefID(nameTable)
	local defTable = {}
	for unitName,_  in pairs(nameTable) do
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
		copy[i] = v
	end
	for _, unitName in ipairs(exclusion) do
		local ud = UnitDefNames[unitName]
		if ud and ud.id then
			copy[ud.id] = nil
		end
	end
	return copy
end

-- swarm arrays
-- these are not strictly required they just help with inputting the units

local longRangeSwarmieeArray = { 
	["cormart"] = true,
	["firewalker"] = true,
	["armsptk"] = true,
	["corstorm"] = true,
	["shiparty"] = true,
	["armham"] = true,
}

local medRangeSwarmieeArray = { 
	["armrock"] = true,
	["amphfloater"] = true,
	["chickens"] = true,
}

local lowRangeSwarmieeArray = {
	["corthud"] = true,
	["spiderassault"] = true,
	["corraid"] = true,
	["armzeus"] = true,
	["logkoda"] = true,
	["hoverassault"] = true,
	
	["correap"] = true,
	["corgol"] = true,
	
	["armcrabe"] = true,
	["armmanni"] = true,
	
	["chickenr"] = true,
	["chickenblobber"] = true,
	["armsnipe"] = true, -- only worth swarming sniper at low range, too accurate otherwise.
}

longRangeSwarmieeArray = NameTableToUnitDefID(longRangeSwarmieeArray)
medRangeSwarmieeArray = NameTableToUnitDefID(medRangeSwarmieeArray)
lowRangeSwarmieeArray = NameTableToUnitDefID(lowRangeSwarmieeArray)

merge(medRangeSwarmieeArray,longRangeSwarmieeArray)
merge(lowRangeSwarmieeArray,medRangeSwarmieeArray)


-- skirm arrays
-- these are not strictly required they just help with inputting the units

local veryShortRangeSkirmieeArray = {
	["corclog"] = true,
	["corcan"] = true,
	["spherepole"] = true,
	["armtick"] = true,
	["puppy"] = true,
	["corroach"] = true,
	["chicken"] = true,
	["chickena"] = true,
	["chicken_tiamat"] = true,
	["chicken_dragon"] = true,
	["hoverdepthcharge"] = true,
}

local shortRangeSkirmieeArray = {
	["armflea"] = true,
	["armpw"] = true,
	["corfav"] = true,
	["corgator"] = true,
	["corpyro"] = true,
	["logkoda"] = true,
	["amphraider3"] = true,
	["corsumo"] = true,
	
	["corsktl"] = true,
}

local riotRangeSkirmieeArray = {
	["corak"] = true,
	["panther"] = true,
	["corsh"] = true,
	["hoverscout"] = true,
	["shipscout"] = true,
	["shipraider"] = true,
	["subraider"] = true,
	["amphriot"] = true,
	["armcomdgun"] = true,
	["dante"] = true,
	
	["armjeth"] = true,
	["corcrash"] = true,
	["armaak"] = true,
	["hoveraa"] = true,
	["spideraa"] = true,
	["amphaa"] = true,
	["shipaa"] = true,
	
	["armrectr"] = true,
	["cornecro"] = true,
	["corned"] = true,
	["corch"] = true,
	["coracv"] = true,
	["arm_spider"] = true,
	["corfast"] = true,
	["amphcon"] = true,
	["shipcon"] = true,
	
	["spherecloaker"] = true,
	["core_spectre"] = true,
}

local lowMedRangeSkirmieeArray = {
	["armcom"] = true,
	["armadvcom"] = true,

	["armwar"] = true,
	["hoverassault"] = true,
	["arm_venom"] = true,
	
	["cormak"] = true,
	["corthud"] = true,
	["corraid"] = true,
}

local medRangeSkirmieeArray = {
	["corcom"] = true,
	["coradvcom"] = true,
	["commsupport"] = true,
	["commadvsupport"] = true,
	
	["spiderriot"] = true,
	["armzeus"] = true,
	["amphraider2"] = true,
	
	["spiderassault"] = true,
	["corlevlr"] = true,
	
	["hoverriot"] = true,
    ["shieldfelon"] = true,

	["correap"] = true,
	["corgol"] = true,
	["tawf114"] = true, -- banisher
}

for name,data in pairs(UnitDefNames) do -- add all comms to mid range skirm
	if data.customParams.commtype then
		medRangeSkirmieeArray[name] = true
	end
end

local longRangeSkirmieeArray = {
	["armrock"] = true,
	["slowmort"] = true,
	["amphfloater"] = true,
	["nsclash"] = true, -- hover janus
	["capturecar"] = true,
	["chickenc"] = true,
	["armbanth"] = true,
	["gorg"] = true,
	["corllt"] = true,
	["armdeva"] = true,
	["armartic"] = true,
}

local artyRangeSkirmieeArray = {
	["shipskirm"] = true,
	["armsptk"] = true,
	["corstorm"] = true,
	["cormist"] = true,
	["amphassault"] = true,
	["chicken_sporeshooter"] = true,
	["corrl"] = true,
	["corhlt"] = true,
	["armpb"] = true,
	["cordoom"] = true,
	["armorco"] = true,
	["amphartillery"] = true,
}

local slasherSkirmieeArray = {
	["corsumo"] = true,
	["dante"] = true,
	["armwar"] = true,
	["hoverassault"] = true,
	["cormak"] = true,
	["corthud"] = true,
	["spiderriot"] = true,
	["armzeus"] = true,
	["spiderassault"] = true,
	["corraid"] = true,
	["corlevlr"] = true,
	["hoverriot"] = true,
    ["shieldfelon"] = true,
	["correap"] = true,
	["armrock"] = true,
}

veryShortRangeSkirmieeArray = NameTableToUnitDefID(veryShortRangeSkirmieeArray)
shortRangeSkirmieeArray = NameTableToUnitDefID(shortRangeSkirmieeArray)
riotRangeSkirmieeArray = NameTableToUnitDefID(riotRangeSkirmieeArray)
lowMedRangeSkirmieeArray = NameTableToUnitDefID(lowMedRangeSkirmieeArray)
medRangeSkirmieeArray = NameTableToUnitDefID(medRangeSkirmieeArray)
longRangeSkirmieeArray = NameTableToUnitDefID(longRangeSkirmieeArray)
artyRangeSkirmieeArray = NameTableToUnitDefID(artyRangeSkirmieeArray)

slasherSkirmieeArray = NameTableToUnitDefID(slasherSkirmieeArray)

merge(shortRangeSkirmieeArray,veryShortRangeSkirmieeArray)
merge(riotRangeSkirmieeArray,shortRangeSkirmieeArray)
merge(lowMedRangeSkirmieeArray, riotRangeSkirmieeArray)
merge(medRangeSkirmieeArray, lowMedRangeSkirmieeArray)
merge(longRangeSkirmieeArray,medRangeSkirmieeArray)
merge(artyRangeSkirmieeArray,longRangeSkirmieeArray)

-- Stuff that mobile AA skirms

local skirmableAir = {
	["blastwing"] = true,
	["bladew"] = true,
	["armkam"] = true,
	["gunshipsupport"] = true,
	["armbrawl"] = true,
	["blackdawn"] = true,
	["corbtrans"] = true,
	["corcrw"] = true,
}

-- Brawler, for AA to swarm.
local brawler = {
	["armbrawl"] = true,
}

brawler = NameTableToUnitDefID(brawler)
skirmableAir = NameTableToUnitDefID(skirmableAir)

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
	["spiderriot"] = true,
	
	["cormak"] = true,
	
	["corlevlr"] = true,
	["capturecar"] = true,

	["hoverriot"] = true, -- mumbo
    ["shieldfelon"] = true,
	["corsumo"] = true,
}

local armedLand = {}
for name,data in pairs(UnitDefNames) do
	if data.canAttack and (not data.canFly) 
	and data.weapons[1] and data.weapons[1].onlyTargets.land then
		armedLand[name] = true 
	end
end

fleeables = NameTableToUnitDefID(fleeables)
armedLand = NameTableToUnitDefID(armedLand)

-- waterline(defaults to 0): Water level at which the unit switches between land and sea behaviour
-- sea: table of behaviour for sea. Note that these tables are optional.
-- land: table of behaviour for land 

-- weaponNum(defaults to 1): Weapon to use when skirming
-- searchRange(defaults to 800): max range of GetNearestEnemy for the unit.
-- defaultAIState (defaults in config): (1 or 0) state of AI when unit is initialised

--*** skirms(defaults to empty): the table of units that this unit will attempt to keep at max range
-- skirmEverything (defaults to false): Skirms everything (does not skirm radar with this enabled only)
-- skirmLeeway: (Weapon range - skirmLeeway) = distance that the unit will try to keep from units while skirming
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
		stoppingDistance = 10,
		velocityPrediction = 20,
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
		skirms = shortRangeSkirmieeArray, 
		swarms = lowRangeSwarmieeArray, 
		flees = {},
		circleStrafe = true, 
		strafeOrderLength = 120,
		skirmLeeway = 60,
		maxSwarmLeeway =180, 
		minSwarmLeeway = 300, 
		swarmLeeway = 40, 
		stoppingDistance = 8,
		skirmOrderDis = 150,
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
	
	-- riots
	["armwar"] = {
		skirms = riotRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = 0, 
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
		skirms = lowMedRangeSkirmieeArray, 
		swarms = medRangeSwarmieeArray, 
		flees = {},
		maxSwarmLeeway = 0, 
		skirmLeeway = -30, 
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
	["dante"] = {
		skirms = medRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
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
		skirmLeeway = 30,
		stoppingDistance = 15,
		skirmOrderDis = 180,
		velocityPrediction = 50,
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
	["armbanth"] = {
		skirms = artyRangeSkirmieeArray,
		swarms = {}, 
		flees = {},
		skirmLeeway = 60, 
	},	
	
	["armsnipe"] = {
		skirms = artyRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		maxSwarmLeeway = 10,
		minSwarmLeeway = 130, 
		skirmLeeway = 10, 
	},
	
	["corgarp"] = {
		skirms = SetMinus(artyRangeSkirmieeArray, {"corhlt"}), 
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
	["subraider"] = {
		skirms = artyRangeSkirmieeArray, 
		swarms = {}, 
		flees = {},
		skirmRadar = true,
		maxSwarmLeeway = 10, 
		minSwarmLeeway = 130, 
		skirmLeeway = 80, 
		skirmOrderDis = 250,
		velocityPrediction = 40,
	},
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
	["armmanni"] = {
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
        skirmLeeway = 50, 
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
}

return behaviourConfig, behaviourDefaults

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
