--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local modoptions = Spring.GetModOptions() or {}

local eggsModifier = 0.8	--unused
alwaysEggs = true			--spawn limited-lifespan eggs when not in Eggs mode?
eggDecayTime = 180

spawnSquare          = 150       -- size of the chicken spawn square centered on the burrow
spawnSquareIncrement = 1         -- square size increase for each unit spawned
burrowName           = "roost"   -- burrow unit name
playerMalus          = 1         -- how much harder it becomes for each additional player, exponential (playercount^playerMalus = malus)	-- used only for burrow spawn rate and queen XP
lagTrigger           = 0.7       -- average cpu usage after which lag prevention mode triggers
triggerTolerance     = 0.05      -- increase if lag prevention mode switches on and off too fast
maxAge               = 5*60      -- chicken die at this age, seconds
queenName            = "chickenflyerqueen"
queenMorphName		 = "chickenlandqueen"
miniQueenName		 = "chicken_dragon"
waveRatio            = 0.6       -- waves are composed by two types of chicken, waveRatio% of one and (1-waveRatio)% of the other
baseWaveSize		 = 2.5		 -- multiplied by malus, 1 = 1 squadSize of chickens
waveSizeMult		 = 1
defenderChance       = 0.05		-- amount of turrets spawned per wave, <1 is the probability of spawning a single turret
quasiAttackerChance  = 0.65		-- subtract defenderChance from this to get spawn chance if "defender" is tagged as a quasi-attacker
maxBurrows           = 50
burrowEggs           = 15       -- number of eggs each burrow spawns
--forceBurrowRespawn	 = false	-- burrows always respawn even if the modoption is set otherwise        
queenSpawnMult       = 4         -- how many times bigger is a queen hatch than a normal burrow hatch
alwaysVisible        = false     -- chicken are always visible
burrowSpawnRate      = 60        -- higher in games with many players, seconds
chickenSpawnRate     = 59
minBaseDistance      = 700      
maxBaseDistance      = 3500

gracePeriod          = 180       -- no chicken spawn in this period, seconds
gracePenalty		 = 15		-- reduced grace per player over one, seconds
gracePeriodMin		 = 90

queenTime            = 60*60    -- time at which the queen appears, seconds
queenMorphTime		 = {60*30, 120*30}	--lower and upper bounds for delay between morphs, gameframes
queenHealthMod		 = 1
miniQueenTime		= {}		-- times at which miniqueens are spawned (multiplier of queentime)
endMiniQueenWaves	= 7		-- waves per miniqueen in PvP endgame

burrowQueenTime		= 15		-- how much killing a burrow shaves off the queen timer, seconds
burrowWaveSize		= 1.2		-- size of contribution each burrow makes to wave size (1 = 1 squadSize of chickens)
burrowRespawnChance = 0.15
burrowRegressTime	= 60		-- direct tech time regress from killing a burrow, divided by playercount

humanAggroPerBurrow	= 1			-- divided by playercount
humanAggroDecay		= 0.25		-- linear rate at which aggro decreases
humanAggroWaveFactor = 1
humanAggroWaveMax	= 5
humanAggroDefenseFactor = 1		-- multiplies aggro for defender spawn chance	-- this one uses per-wave delta rather than listed value
humanAggroSupportFactor	= 0.1	-- multiplies aggro for supporter spawn chance
humanAggroTechTimeProgress = 20	-- how much to increase chicken tech progress (* aggro), seconds
humanAggroTechTimeRegress = 0	-- how much to reduce chicken tech progress (* aggro), seconds
humanAggroQueenTimeFactor = 1	-- burrow queen time is multiplied by this and aggro (after clamping)
humanAggroQueenTimeMin = 0	-- min value of aggro for queen time calc
humanAggroQueenTimeMax = 8

techAccelPerPlayer	= 5		-- how much tech accel increases per player over one per wave, seconds
techTimeFloorFactor	= 0.5	-- tech timer can never be less than this * real time

scoreMult			= 1

gameMode		= true	--Spring.GetModOption("zkmode")
tooltipMessage	= "Kill chickens and collect their eggs to get metal."
mexes = {
  "cormex", 
  "armmex",
  --"armestor"	--pylon; needed for annis etc.
}
noTarget = {
	terraunit=true,
	armmine1=true,
	armmine2=true,
	armmine3=true,
	cormine1=true,
	cormine2=true,
	cormine3=true,
	cormine_impulse=true,
	roost=true,
}

modes = {
    [0] = 0,
    [1] = 'Chicken: Very Easy',
    [2] = 'Chicken: Easy',
    [3] = 'Chicken: Normal',
    [4] = 'Chicken: Hard',
	[5] = 'Chicken: Suicidal',
    [6] = 'Chicken Eggs: Easy',
    [7] = 'Chicken Eggs: Normal',
    [8] = 'Chicken Eggs: Hard',
    [9] = 'Chicken Eggs: Suicidal',
	[10] = 'Chicken: Custom',
	[11] = 'Chicken Eggs: Custom',
	[12] = 'Chicken: Speed'
}
defaultDifficulty = modes[2]
testBuilding 	= UnitDefNames["armestor"].id	--testing to place burrow
testBuildingQ 	= UnitDefNames["chicken_dragon"].id	--testing to place queen


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Copy(original)   -- Warning: circular table references lead to
  local copy = {}               -- an infinite loop.
  for k, v in pairs(original) do
    if (type(v) == "table") then
      copy[k] = Copy(v)
    else
      copy[k] = v
    end
  end
  return copy
end


local function TimeModifier(d, mod)
  for chicken, t in pairs(d) do
    t.time = t.time*mod
    if (t.obsolete) then
      t.obsolete = t.obsolete*mod
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- times in minutes
local chickenTypes = {
  chicken        =  {time =  -60,  squadSize =   3, obsolete = 30},
  chicken_pigeon =  {time =  6,  squadSize =   1.4, obsolete = 40},
  chickens       =  {time = 12,  squadSize =   1, obsolete = 40},
  chickena       =  {time = 18,   squadSize = 0.5, obsolete = 45},
  chickenr       =  {time = 24,  squadSize = 1.2, obsolete = 50},
  --chicken_leaper =  {time = 24,  squadSize = 2, obsolete = 45},  
  chickenwurm    =  {time = 28,  squadSize =   0.7},
  chicken_roc	 =  {time = 28,  squadSize =   0.5},  
  chicken_sporeshooter =  {time = 32,  squadSize =   0.5},
  chickenf       =  {time = 36,  squadSize = 0.5},
  chickenc       =  {time = 42,  squadSize = 0.5},
  chickenblobber =  {time = 48,  squadSize = 0.3},
  chicken_blimpy =  {time = 55,  squadSize = 0.2},
  chicken_tiamat =  {time = 60,  squadSize = 0.2},
  
  --chicken_shield =  {time = 99999,  squadSize = 0.01},	--workaround to get it into a list
}

local defenders = {
  chickend = {time = 20, squadSize = 0.65 },
  chicken_dodo = {time = 30,  squadSize = 2}, 
  chicken_spidermonkey =  {time = 25, squadSize = 0.7},
  --chicken_rafflesia =  {time = 30, squadSize = 0.4 },
}

local supporters = {
  --chickenspire =  {time = 50, squadSize = 0.1},
  chicken_shield =  {time = 30, squadSize = 0.6},
  chicken_spidermonkey =  {time = 20, squadSize = 0.7},
}

-- TODO
-- cooldown is in waves
local specialPowers = {
	{name = "Digger Ambush", maxAggro = -2, time = 15, obsolete = 40, unit = "chicken_digger", burrowRatio = 1.25, minDist = 100, maxDist = 450, cooldown = 3, targetHuman = true},
	--{name = "Wurmsign", maxAggro = -3, time = 40, unit = "chickenwurm", burrowRatio = 0.2, cooldown = 4},
	{name = "Spire Sprout", maxAggro = -4.5, time = 20, unit = "chickenspire", burrowRatio = 0.15, tieToBurrow = true, cooldown = 3},
	{name = "Rising Dragon", maxAggro = -8, time = 30, unit = "chicken_dragon", burrowRatio = 1/12, minDist = 250, maxDist = 1200, cooldown = 5, targetHuman = true},
	--{name = "Dino Killer", maxAggro = -12, time = 40, unit = "chicken_silo", minDist = 1500},
}

local function SetCustomMiniQueenTime()
	if modoptions.miniqueentime then
		if modoptions.miniqueentime == 0 then return nil
		else return modoptions.miniqueentime end
	else return 0.6 end
end    
    
difficulties = {
  ['Chicken: Very Easy'] = {
    chickenSpawnRate = 120, 
    burrowSpawnRate  = 60,
    gracePeriod      = 300,
	waveSizeMult	 = 0.9,
    timeSpawnBonus   = .02,     -- how much each time level increases spawn size
	queenTime		 = 40*60,
	queenName        = "chicken_dragon",
	queenMorphName	 = '',
	miniQueenName	 = "chicken_tiamat",
	maxBurrows       = 12,
	specialPowers	 = {},
	scoreMult		 = 0.25,
  },

  ['Chicken: Easy'] = {
    chickenSpawnRate = 60, 
    burrowSpawnRate  = 50,
    gracePeriod      = 180,
	waveSizeMult	 = 0.9,
    timeSpawnBonus   = .03,
	queenHealthMod	 = 0.75,
	techAccelPerPlayer = 4,
	scoreMult		 = 0.66,
  },

  ['Chicken: Normal'] = {
    chickenSpawnRate = 50, 
    burrowSpawnRate  = 45,
    timeSpawnBonus   = .04,
	miniQueenTime		= {0.6},	
  },

  ['Chicken: Hard'] = {
    chickenSpawnRate = 45, 
    burrowSpawnRate  = 45,
	waveSizeMult	 = 1.2,
    timeSpawnBonus   = .05,
	burrowWaveSize	 = 1.4,
	queenHealthMod	 = 1.5,
	queenSpawnMult   = 5,
	miniQueenTime	 = {0.5},
	techAccelPerPlayer	= 7.5,
	scoreMult		 = 1.25,
	timeModifier	 = 0.875,
  },
  
  ['Chicken: Suicidal'] = {
    chickenSpawnRate = 45, 
	waveSizeMult	 = 1.5,
    burrowSpawnRate  = 40,
    timeSpawnBonus   = .06,
	burrowWaveSize	 = 1.6,	
	gracePeriod		 = 150,
	gracePeriodMin	 = 30,
	burrowRespawnChance = 0.25,
	burrowRegressTime	= 50,
	queenSpawnMult   = 5,
	queenTime		 = 50*60,
	queenHealthMod	 = 2,
	miniQueenTime	 = {0.45}, --{0.37, 0.75},
	endMiniQueenWaves	= 6,
	techAccelPerPlayer	= 10,
	timeModifier	 = 0.75,
	scoreMult		 = 2,
  },

  ['Chicken: Custom'] = {
    chickenSpawnRate = modoptions.chickenspawnrate or 50, 
    burrowSpawnRate  = modoptions.burrowspawnrate or 45,
    timeSpawnBonus   = .04,
--    chickenTypes     = Copy(chickenTypes),
--    defenders        = Copy(defenders),
	queenTime		 = (modoptions.queentime or 60)*60,
	miniQueenTime	= {	SetCustomMiniQueenTime() },
	gracePeriod		= (modoptions.graceperiod and modoptions.graceperiod * 60) or 180,
	gracePenalty	= 0,
	gracePeriodMin	= 30,
	burrowQueenTime	= (modoptions.burrowqueentime and modoptions.burrowqueentime) or 30,
	timeModifier	= modoptions.techtimemult or 1,
	scoreMult		= 0,
  },
  
  ['Chicken: Speed'] = {
    chickenSpawnRate = 50, 
    burrowSpawnRate  = 45,  
	waveSizeMult	 = 0.85,	
	gracePeriod		 = 90,
	gracePenalty	 = 10,
	gracePeriodMin	 = 20,
	burrowRespawnChance	= 0,
	queenTime		 = 20*60,
	queenHealthMod	 = 0.2,
	miniQueenTime	 = {},
	endMiniQueenWaves	= 6,
	techAccelPerPlayer	= 0,
	humanAggroQueenTimeFactor	= 0.35,
	humanAggroTechTimeProgress	= 7,
	burrowRegressTime	= 20,
	queenSpawnMult	 = 2.5, 
	timeModifier	 = 0.35,
	scoreMult		 = 0,
  },  
}

-- minutes to seconds
TimeModifier(chickenTypes, 60)
TimeModifier(defenders, 60)
TimeModifier(supporters, 60)
TimeModifier(specialPowers, 60)

--[[
for chicken, t in pairs(chickenTypes) do
    t.timeBase = t.time
end
for chicken, t in pairs(supporters) do
    t.timeBase = t.time
end
for chicken, t in pairs(defenders) do
    t.timeBase = t.time
end
]]--

for _, d in pairs(difficulties) do
  d.timeSpawnBonus = (d.timeSpawnBonus or 0)/60
  d.chickenTypes = Copy(chickenTypes)
  d.defenders = Copy(defenders)
  d.supporters = Copy(supporters)
  d.specialPowers = d.specialPowers or Copy(specialPowers)
  
  TimeModifier(d.chickenTypes, d.timeModifier or 1)
  TimeModifier(d.defenders, d.timeModifier or 1)
  TimeModifier(d.supporters, d.timeModifier or 1)
end

difficulties['Chicken Eggs: Very Easy']   = Copy(difficulties['Chicken: Very Easy'])
difficulties['Chicken Eggs: Easy']   = Copy(difficulties['Chicken: Easy'])
difficulties['Chicken Eggs: Normal'] = Copy(difficulties['Chicken: Normal'])
difficulties['Chicken Eggs: Hard']   = Copy(difficulties['Chicken: Hard'])
difficulties['Chicken Eggs: Suicidal']   = Copy(difficulties['Chicken: Suicidal'])
difficulties['Chicken Eggs: Custom']   = Copy(difficulties['Chicken: Custom'])

difficulties['Chicken: Very Easy'].chickenTypes.chicken_tiamat.time = 999999

--for i,v in pairs(difficulties) do v.eggs = true end

difficulties['Chicken Eggs: Easy'].eggs   	= true
difficulties['Chicken Eggs: Normal'].eggs 	= true
difficulties['Chicken Eggs: Hard'].eggs   	= true
difficulties['Chicken Eggs: Suicidal'].eggs	= true
difficulties['Chicken Eggs: Custom'].eggs	= true

defaultDifficulty = 'Chicken: Normal'

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
