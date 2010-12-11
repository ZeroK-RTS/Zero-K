--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local hardModifier   = 0.9	--0.75
local suicidalModifier = 0.75

local eggsModifier = 0.8	--unused
alwaysEggs = true			--spawn limited-lifespan eggs when not in Eggs mode?
eggDecayTime = 180

spawnSquare          = 150       -- size of the chicken spawn square centered on the burrow
spawnSquareIncrement = 1         -- square size increase for each unit spawned
burrowName           = "roost"   -- burrow unit name
playerMalus          = 1         -- how much harder it becomes for each additional player, exponential (playercount^playerMalus = malus)
maxChicken           = 1000
lagTrigger           = 0.6       -- average cpu usage after which lag prevention mode triggers
triggerTolerance     = 0.05      -- increase if lag prevention mode switches on and off too fast
maxAge               = 5*60      -- chicken die at this age, seconds
queenName            = "chickenflyerqueen"
queenMorphName		 = "chickenlandqueen"
miniQueenName		 = "chicken_dragon"
waveRatio            = 0.6       -- waves are composed by two types of chicken, waveRatio% of one and (1-waveRatio)% of the other
defenderChance       = 0.1       -- amount of turrets spawned per wave, <1 is the probability of spawning a single turret
quasiAttackerChance  = 0.6		-- subtract defenderChance from this to get spawn chance if "defender" is tagged as a quasi-attacker
maxBurrows           = 40
minBurrows			 = 0		-- extra burrows (half of deficit or half of malus, whichever is lower) spawn each wave if there are presently fewer than this
minBurrowsIncrease	 = 0.15		-- increase each wave (multiplied by malus)
minBurrowsMax		 = 3.5    	-- multiplied by malus
burrowEggs           = 15       -- number of eggs each burrow spawns
--forceBurrowRespawn	 = false	-- burrows always respawn even if the modoption is set otherwise        
queenSpawnMult       = 4         -- how many times bigger is a queen hatch than a normal burrow hatch
alwaysVisible        = false     -- chicken are always visible
burrowSpawnRate      = 60        -- higher in games with many players, seconds
chickenSpawnRate     = 59
minBaseDistance      = 700      
maxBaseDistance      = 4500

gracePeriod          = 30       -- no chicken spawn in this period, seconds
graceBonus			 = 31		-- extended grace in seconds for each player less than...
graceMaxPlayers		 = 4

queenTime            = 50*60    -- time at which the queen appears, seconds
queenMorphTime		 = {60*30, 120*30}	--lower and upper bounds for delay between morphs, gameframes
miniQueenTime		= {}		-- times at which miniqueens are spawned (multiplier of queentime)
endMiniQueenWaves	= 7		-- waves per miniqueen in PvP endgame

burrowQueenTime		= 150		-- how much killing a burrow shaves off the queen timer, seconds (divided by malus)
burrowWaveBonus		= 0.2		-- size of temporary bonus to add to next wave (divided by playercount)
waveBonusDecay		= 0.05		-- linear rate at which burrow wave bonus decreases
burrowTechTime		= 10		-- how many seconds each burrow deducts from the tech time per wave (divided by playercount)
burrowRespawnChance = 0.15


gameMode		= Spring.GetModOption("camode")
tooltipMessage	= "Kill chickens and collect their eggs to get metal."
mexes = {
  "cormex", 
  "armmex"
}
commnames = {
	armcom=true,
	corcom=true,
	commrecon=true,
	commsupport=true,
	chickenbroodqueen=true,
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
    [5] = 'Chicken Eggs: Easy',
    [6] = 'Chicken Eggs: Normal',
    [7] = 'Chicken Eggs: Hard',
	[8] = 'Chicken: Suicidal',
}
defaultDifficulty = modes[2]
testBuilding 	= UnitDefNames["armestor"].id	--testing to place burrow
testBuildingQ 	= UnitDefNames["mahlazer"].id	--testing to place queen


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
  chicken        =  {time =  -5,  squadSize =   3, obsolete = 30},
  chicken_pigeon =  {time =  7,  squadSize =   1.4, obsolete = 50},
  chickens       =  {time = 14,  squadSize =   1, obsolete = 60},
  chickena       =  {time = 21,   squadSize = 0.5, obsolete = 50},
  chickenwurm       =  {time = 25,  squadSize =   0.7},
  chickenr       =  {time = 30,  squadSize = 1.2, obsolete = 60},
  chicken_sporeshooter =  {time = 35,  squadSize =   0.5},
  chicken_dodo   =  {time = 40,  squadSize =   2, obsolete = 70},
  chickenf       =  {time = 45,  squadSize = 0.5},
  chickenc       =  {time = 50,  squadSize = 0.5},
  chickenblobber =  {time = 55,  squadSize = 0.3},
  chicken_blimpy =  {time = 60,  squadSize = 0.2},
  chicken_tiamat =  {time = 70,  squadSize = 0.2},
}

local defenders = {
  chickend =  {time = 20, squadSize = 0.65 },
  chickenspire =  {time = 50, squadSize = 0.2, quasiAttacker = true, },
  chicken_shield =  {time = 30, squadSize = 0.6, quasiAttacker = true, },
  --chicken_rafflesia =  {time = 30, squadSize = 0.4 },
}
    
    
difficulties = {
  ['Chicken: Very Easy'] = {
    chickenSpawnRate = 120, 
    burrowSpawnRate  = 120,
    gracePeriod      = 240,
    firstSpawnSize   = 1.6,
    timeSpawnBonus   = .02,     -- how much each time level increases spawn size
    chickenTypes     = Copy(chickenTypes),
    defenders        = Copy(defenders),
	queenTime		 = 40*60,
	queenName        = "chicken_dragon",
	queenMorphName	 = '',
	miniQueenName	 = "chicken_tiamat",
	maxBurrows       = 12,	
	minBurrows		 = 0,
	minBurrowsIncrease = 0,
  },

  ['Chicken: Easy'] = {
    chickenSpawnRate = 60, 
    burrowSpawnRate  = 50,
    gracePeriod      = 60,
    firstSpawnSize   = 1.2,
    timeSpawnBonus   = .03,
    queenName        = "chickenqueenlite",
	queenMorphName	 = "chickenqueenlite2",
    chickenTypes     = Copy(chickenTypes),
    defenders        = Copy(defenders),
  },

  ['Chicken: Normal'] = {
    chickenSpawnRate = 50, 
    burrowSpawnRate  = 45,
    firstSpawnSize   = 1.4,
    timeSpawnBonus   = .04,
    chickenTypes     = Copy(chickenTypes),
    defenders        = Copy(defenders),
	miniQueenTime		= {0.6},	
  },

  ['Chicken: Hard'] = {
    chickenSpawnRate = 45, 
    burrowSpawnRate  = 45,
    firstSpawnSize   = 1.8,
    timeSpawnBonus   = .05,
    chickenTypes     = Copy(chickenTypes),
    defenders        = Copy(defenders),
	burrowWaveBonus	 = 0.2,
	burrowTechTime	 = 12,
	queenSpawnMult   = 5,     
	miniQueenTime	 = {0.5},		
  },
  
  ['Chicken: Suicidal'] = {
    chickenSpawnRate = 45, 
    burrowSpawnRate  = 40,
    firstSpawnSize   = 2.2,
    timeSpawnBonus   = .05,
    chickenTypes     = Copy(chickenTypes),
    defenders        = Copy(defenders),
	burrowQueenTime	 = 180,
	burrowWaveBonus	 = 0.25,
	burrowTechTime	 = 15,
	burrowRespawnChance = 0.25,
	queenSpawnMult   = 5,
	queenTime		 = 40*60,
	miniQueenTime	 = {0.37, 0.75},
	endMiniQueenWaves	= 6,
  },
}

-- minutes to seconds
for _, d in pairs(difficulties) do
  d.timeSpawnBonus = d.timeSpawnBonus/60
  TimeModifier(d.chickenTypes, 60)
  TimeModifier(d.defenders, 60)
end

TimeModifier(difficulties['Chicken: Hard'].chickenTypes, hardModifier)
TimeModifier(difficulties['Chicken: Hard'].defenders,    hardModifier)
TimeModifier(difficulties['Chicken: Suicidal'].chickenTypes, suicidalModifier)
TimeModifier(difficulties['Chicken: Suicidal'].defenders,    suicidalModifier)

difficulties['Chicken Eggs: Very Easy']   = Copy(difficulties['Chicken: Very Easy'])
difficulties['Chicken Eggs: Easy']   = Copy(difficulties['Chicken: Easy'])
difficulties['Chicken Eggs: Normal'] = Copy(difficulties['Chicken: Normal'])
difficulties['Chicken Eggs: Hard']   = Copy(difficulties['Chicken: Hard'])

difficulties['Chicken: Very Easy'].chickenTypes.chicken_tiamat = nil

--for i,v in pairs(difficulties) do v.eggs = true end

difficulties['Chicken Eggs: Easy'].eggs   = true
difficulties['Chicken Eggs: Normal'].eggs = true
difficulties['Chicken Eggs: Hard'].eggs   = true

defaultDifficulty = 'Chicken: Normal'

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
