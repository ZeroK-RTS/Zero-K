--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local version = "0.1.3"

function gadget:GetInfo()
	return {
		name        = "Zombies!",
		desc        = "Features are dangerous, reclaim them, as fast, as possible! Version "..version,
		author      = "Tom Fyuri",		-- original gadget was mapmod for trololo by banana_Ai, this is revamped version as a zk anymap gamemode. Thanks Anarchid!
		date        = "Mar 2014",
		license     = "GPL v2 or later",
		layer       = math.huge,
		enabled     = true
	}
end

--SYNCED-------------------------------------------------------------------

-- changelog
-- 6 august 2014 - 0.1.3. Some magic which might fix crash. (At least it fixed the original zombie gadget)
-- 7 april 2014 - 0.1.2. Added permaslow option. Default on. 50% is max slow for now.
-- 5 april 2014 - 0.1.1. Sfx, gfx, factory orders added. Slow down upon reclaim added. Thanks Anarchid.
-- 5 april 2014 - 0.1.0. Release.

local modOptions = Spring.GetModOptions()

local getMovetype = Spring.Utilities.getMovetype

-- Now to load utilities and/or configuration
VFS.Include("LuaRules/Configs/CAI/accessory/targetReachableTester.lua")
-- I'm scared... what exactly did including that file do and how do I use it?

local spGetUnitDefID              = Spring.GetUnitDefID
local spGetUnitTeam               = Spring.GetUnitTeam
local spGetAllUnits               = Spring.GetAllUnits
local spGetGameFrame              = Spring.GetGameFrame
local spGetAllFeatures            = Spring.GetAllFeatures
local spGiveOrderToUnit           = Spring.GiveOrderToUnit
local spGetUnitCommandCount       = Spring.GetUnitCommandCount
local spSetTeamResource           = Spring.SetTeamResource
local spGetUnitHealth             = Spring.GetUnitHealth

local GaiaTeamID     = Spring.GetGaiaTeamID()
local GaiaAllyTeamID = select(6, Spring.GetTeamInfo(GaiaTeamID, false))

local zombieUnits = {}
local featureReviveCycleCount = {}

local ZOMBIES_REZ_SPEED = tonumber(modOptions.zombies_rezspeed) or 12

local ZOMBIES_PERMA_SLOW = tonumber(modOptions.zombies_permaslow) or 0.5

local ZOMBIES_REZ_MIN = tonumber(modOptions.zombies_delay) or 10 -- minimum of 10 seconds, max is determined by rez speed
local ZOMBIES_REZ_MAX = tonumber(modOptions.zombies_delay_max) or 600 --600 only affects things above 7200 cost at 12 rezspeed.

local ZOMBIES_PARTIAL_RECLAIM = (tonumber(modOptions.zombies_partial_reclaim) == 1)

local zombiesDeathOnCaptureChance = tonumber(modOptions.zombies_die_on_capture) or nil

local zombiesReviveCyclesCount = tonumber(modOptions.zombies_revive_cycles) or 1
local zombiesWrecksRemain = tonumber(modOptions.zombies_wrecks_remain) or nil

local zombiesReviveOptionsAsString = (modOptions.zombies_revive_options) or nil 
local zombiesReviveOptionMultiRandomise = tonumber(modOptions.zombies_revive_options_multi_random) or 1
local zombiesReviveOptionsOverflowSpawn = tonumber(modOptions.zombies_revive_options_overflow_spawn) or 1

local zombiesBudgetMultiplier = tonumber(modOptions.zombies_budget_multiplier) or 1
local zombiesPermanentBudgetMultiplier = tonumber(modOptions.zombies_permanent_budget) or nil

local zombieReviveOptionCount = 0
local zombieReviveOptions = {} -- allows duplicates
local zombieGlobalBudget = 0

--TODO there seems to be something with the comnames adding some more stuff?
local UnitDefBothNames = {} -- Includes humanName and name
local function AddName(name, unitDefId)
	name = name:lower()
	UnitDefBothNames[name] = UnitDefBothNames[name] or {}
	UnitDefBothNames[name][#UnitDefBothNames[name] + 1] = unitDefId
end

if zombiesReviveOptionsAsString then -- TODO pilfered from lockunits_modoption, would there be a better way to do this? Maybe should have an api :O
	zombiesReviveOptionsAsString = zombiesReviveOptionsAsString:gsub("[%s%+]*%+[%s%+]*","+"):gsub("^%s*",""):gsub("%s*$",""):lower()

	for unitDefID = 1, #UnitDefs do
		AddName(UnitDefs[unitDefID].humanName, unitDefID)
		AddName(UnitDefs[unitDefID].name, unitDefID)
	end

	for name in string.gmatch(zombiesReviveOptionsAsString, '([^+]+)') do
		if UnitDefBothNames[name] then
			for i = 1, #UnitDefBothNames[name] do
				local unitDefID = UnitDefBothNames[name][i]
				zombieReviveOptionCount = zombieReviveOptionCount + 1
				zombieReviveOptions[zombieReviveOptionCount] = unitDefID
			end
		end
	end
end



local function SpawnReviveOption(x,y,z,facing,zombieUnitDefID)
	local unitID = Spring.CreateUnit(zombieUnitDefID, x, y, z, facing, GaiaTeamID)
	zombieUnits[unitID] = true
	GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
	GG.Zombies.SetZombieBehavior(unitID)
	gadgetHandler:NotifyUnitCreatedByMechanic(unitID, false, "zombies")
	return unitID
end

local currentBudget = 0
local function HandleZombieReviveOptions(featureID)
	local x, y, z = Spring.GetFeaturePosition(featureID)
	local currentMetal, maxMetal = Spring.GetFeatureResources(featureID)
	local resDefName, facing = GG.Zombies.GetFeatureResurrectData(featureID)
	local zombieBudget = math.floor(zombiesBudgetMultiplier * UnitDefNames[resDefName].cost)
	
	if ZOMBIES_PARTIAL_RECLAIM then -- partial reclaim reduces the available metal to spawn units
		zombieBudget = math.floor(zombieBudget * (currentMetal/maxMetal))
	end
	currentBudget = zombieBudget + zombieGlobalBudget + currentBudget
	
	local zombieUnitDefID = zombieReviveOptions[math.random(1,zombieReviveOptionCount)]
	local zombieCost = UnitDefs[zombieUnitDefID].cost
	while currentBudget >= zombieCost do
		SpawnReviveOption(x,y,z,facing,zombieUnitDefID)
		currentBudget = currentBudget - zombieCost
		if zombiesReviveOptionMultiRandomise == 1 then -- Randomises to a new unit if desired
			zombieUnitDefID = zombieReviveOptions[math.random(1,zombieReviveOptionCount)]
			zombieCost = UnitDefs[zombieUnitDefID].cost
		end
	end
	
	if zombiesReviveOptionsOverflowSpawn == 1 then -- We make a partial health zombie or overflow the budget to the next spawn
		local unitID = SpawnReviveOption(x,y,z,facing,zombieUnitDefID)
		currentBudget = currentBudget - zombieCost
		local health = Spring.GetUnitHealth(unitID) -- TODO something breaks here, check if unit exists?
		if health then --Last zombie spawned gets its health cut by the % of metal it overspent
			Spring.SetUnitHealth(unitID, health*((UnitDefs[zombieUnitDefID].cost + currentBudget)/UnitDefs[zombieUnitDefID].cost))
			currentBudget = 0
		end
	end
	
	if zombiesPermanentBudgetMultiplier then
		zombieGlobalBudget = zombieGlobalBudget + zombieBudget * zombiesPermanentBudgetMultiplier
		Spring.Echo("ZombiePermanentBudget:"..zombieGlobalBudget)
	end
end

local function CheckZombieOrders()	-- i can't rely on Idle because if for example unit is unloaded it doesnt count as idle... weird
	for unitID, _ in pairs(zombieUnits) do
		local queueSize = spGetUnitCommandCount(unitID)
		if not (queueSize) or not (queueSize > 0) then
			GG.Zombies.SetZombieBehavior(unitID)
		end
	end
end

function gadget:GameFrame(f)
	if (f%640) == 1 then
		CheckZombieOrders()
	end
	if f == 1 then
		spSetTeamResource(GaiaTeamID, "ms", 500)
		spSetTeamResource(GaiaTeamID, "es", 10500)
	end
end
-- settings gaiastorage before frame 1 somehow doesnt work, well i can guess why...

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if zombieUnits[unitID] then
		zombieUnits[unitID] = nil
	end
end

function gadget:UnitTaken(unitID, unitDefID, teamID, newTeamID)
	if zombieUnits[unitID] and newTeamID ~= GaiaTeamID then
		zombieUnits[unitID] = nil
		if zombiesDeathOnCaptureChance and zombiesDeathOnCaptureChance >= math.random(0,1) then
			Spring.DestroyUnit(unitID)
		end
		-- taking away zombie from zombie team unpermaslows it
		if ZOMBIES_PERMA_SLOW then
			GG.Zombies.SetZombieSpeedMult(unitID, 1)
		end
	elseif newTeamID == GaiaTeamID then
		GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
		GG.Zombies.SetZombieBehavior(unitID)
		zombieUnits[unitID] = true
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	if (teamID == GaiaTeamID) and (builderID == GaiaTeamID) then
		GG.Zombies.SetZombieBehavior(unitID)
		zombieUnits[unitID] = true
		if ZOMBIES_PERMA_SLOW then
			local maxHealth = select(2, spGetUnitHealth(unitID)) -- TODO is this check something necessary? or could it be removed
			if maxHealth then
				GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
			end
		end
	end
end

local function FeatureReviveCycles(featureID)
	if featureReviveCycleCount[featureID] == nil then
		featureReviveCycleCount[featureID] = zombiesReviveCyclesCount - 1 -- one cycle has passed to reach this point
	else 
		featureReviveCycleCount[featureID] = featureReviveCycleCount[featureID] - 1
	end
	return featureReviveCycleCount[featureID]
end

local function RezFrameCallback(featureID)
	
	if zombieReviveOptionCount == 0 then
		local unitID = GG.Zombies.TurnFeatureIntoUnit(featureID,GaiaTeamID)
		zombieUnits[unitID] = true
		GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
		GG.Zombies.SetZombieBehavior(unitID)
		if ZOMBIES_PARTIAL_RECLAIM then
			GG.Zombies.SetHealthByReclaimPercent(featureID,unitID)
		end
	else
		HandleZombieReviveOptions(featureID)
	end
	
	local zombieCyclesRemaining = 0
	if zombiesReviveCyclesCount > 1 then
		zombieCyclesRemaining = FeatureReviveCycles(featureID)
	end
	if zombieCyclesRemaining > 0 then
		GG.Zombies.AddFeatureToZombieCountdown(featureID, ZOMBIES_REZ_SPEED, ZOMBIES_REZ_MIN, ZOMBIES_REZ_MAX, RezFrameCallback)
		return
	end
	
	if not zombiesWrecksRemain then
		Spring.DestroyFeature(featureID)
	end
end

function gadget:FeatureCreated(featureID, allyTeam)
	GG.Zombies.AddFeatureToZombieCountdown(featureID, ZOMBIES_REZ_SPEED, ZOMBIES_REZ_MIN, ZOMBIES_REZ_MAX, RezFrameCallback)
end

local function ReInit()
	local units = spGetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		local unitTeam = spGetUnitTeam(unitID)
		if (unitTeam == GaiaTeamID) then
			zombieUnits[unitID] = true
			GG.Zombies.SetZombieSpeedMult(unitID,ZOMBIES_PERMA_SLOW)
			GG.Zombies.SetZombieBehavior(unitID)
		end
	end
	local features = spGetAllFeatures()
	for i = 1, #features do
		GG.Zombies.AddFeatureToZombieCountdown(features[i], ZOMBIES_REZ_SPEED, ZOMBIES_REZ_MIN, ZOMBIES_REZ_MAX, RezFrameCallback)
	end
end

function gadget:Initialize()
	if not (tonumber(modOptions.zombies) == 1) then
		gadgetHandler:RemoveGadget()
		return
	end
	if (spGetGameFrame() > 1) then
		ReInit()
	end
end

function gadget:GameStart()
	ReInit() -- anything it does doesnt mess with existing zombies
end