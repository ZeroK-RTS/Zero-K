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
local zombieTeamID = Spring.GetGaiaTeamID()
local zombieAllyTeamID = tonumber(modOptions.zombies_team) or nil 
if zombieAllyTeamID then
	zombieAllyTeamID = zombieAllyTeamID -1 --Teams are offset by 1 in the modoptions, and nil when 0
end
local function GetRandomTeamIDFromAllyTeam(allyTeamID)
	local allyTeamList = Spring.GetTeamList(allyTeamID)
	local teamMateCount = 0
	
	for _,_ in ipairs(allyTeamList) do
		teamMateCount = teamMateCount + 1 
	end
	return allyTeamList[math.random(1,teamMateCount)]
end

local zombieUnits = {}
local featureReviveCycleCount = {}
local totalBaseZombieBudget = 0
local excessBudget = 0

local ZOMBIES_REZ_SPEED = tonumber(modOptions.zombies_rezspeed) or 12

local ZOMBIES_PERMA_SLOW = tonumber(modOptions.zombies_permaslow) or 0.5

local ZOMBIES_REZ_MIN = tonumber(modOptions.zombies_delay) or 10 -- minimum of 10 seconds, max is determined by rez speed
local ZOMBIES_REZ_MAX = tonumber(modOptions.zombies_delay_max) or 100000 --600 only affects things above 7200 cost at 12 rezspeed.

local ZOMBIES_PARTIAL_RECLAIM = tonumber(modOptions.zombies_partial_reclaim) or nil

local zombieDeathOnCaptureChance = tonumber(modOptions.zombies_die_on_capture) or nil

local zombieReviveCyclesCount = tonumber(modOptions.zombies_revive_cycles) or 1
local zombieWrecksRemain = tonumber(modOptions.zombies_wrecks_remain) or nil

local zombiesReviveOptionsAsString = (modOptions.zombies_revive_options) or nil 
local zombieReviveOptionMultiRandomise = tonumber(modOptions.zombies_revive_options_multi_random) or nil
local zombieOverflowSpawn = tonumber(modOptions.zombies_revive_options_overflow_spawn) or 1

local zombieBudgetMult = tonumber(modOptions.zombies_budget_multiplier) or 1
local zombieBudgetMultScaler = tonumber(modOptions.zombies_budget_multiplier_scaler) or nil

local zombieFlatBudget = tonumber(modOptions.zombies_flat_budget) or 0
local zombieFlatBudgetScaler = tonumber(modOptions.zombies_flat_budget_scaler) or nil

local zombieReviveOptionCount = 0
local zombieReviveOptions = {} -- allows duplicates

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
	local unitID = Spring.CreateUnit(zombieUnitDefID, x, y, z, facing, zombieTeamID)
	zombieUnits[unitID] = true
	GG.Zombies.SetZombieBehavior(unitID)
	if ZOMBIES_PERMA_SLOW then
		GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
	end
	gadgetHandler:NotifyUnitCreatedByMechanic(unitID, false, "zombies")
	return unitID
end

local function HandleZombieRevive(featureID, currentBudget,unitDefIDTable)
	local resDefName, facing = GG.Zombies.GetFeatureResurrectData(featureID)
	local zombieUnitDefID = nil --nil means we use the features default revival thingy
	local zombieCost = UnitDefNames[resDefName].cost
	
	if unitDefIDTable then
		zombieUnitDefID = unitDefIDTable[math.random(1,#unitDefIDTable)]
		zombieCost = UnitDefs[zombieUnitDefID].cost
	end

	while currentBudget >= zombieCost do
		local unitID = GG.Zombies.TurnFeatureIntoUnit(featureID,zombieTeamID,zombieUnitDefID)
		if unitID then
			zombieUnits[unitID] = true
			GG.Zombies.SetZombieBehavior(unitID)
			if ZOMBIES_PERMA_SLOW then
				GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
			end
		end
		currentBudget = currentBudget - zombieCost
		if zombieReviveOptionMultiRandomise and zombieUnitDefID then -- Randomises to a new unit if desired
			zombieUnitDefID = unitDefIDTable[math.random(1,#unitDefIDTable)]
			zombieCost = UnitDefs[zombieUnitDefID].cost
		end
		--TODO do we randomise for each spawn?
		if zombieAllyTeamID then
			zombieTeamID = GetRandomTeamIDFromAllyTeam(zombieAllyTeamID)
		end
	end
		
	if zombieOverflowSpawn == 1 and currentBudget > 0 then -- We make a partial health zombie or overflow the budget to the next spawn
		local unitID = GG.Zombies.TurnFeatureIntoUnit(featureID,zombieTeamID,zombieUnitDefID)
		if not unitID then
			return currentBudget
		end
		zombieUnits[unitID] = true
		GG.Zombies.SetZombieBehavior(unitID)
		if ZOMBIES_PERMA_SLOW then
			GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
		end
		local unitDefID = Spring.GetUnitDefID(unitID)
		currentBudget = currentBudget - zombieCost
		if not ZOMBIES_PARTIAL_RECLAIM then
			return 0
		end
		local health = Spring.GetUnitHealth(unitID) -- TODO something breaks here, check if unit exists?
		if health then --Last zombie spawned gets its health cut by the % of metal it overspent
			Spring.SetUnitHealth(unitID, health*((UnitDefs[unitDefID].cost + currentBudget)/UnitDefs[unitDefID].cost))
			currentBudget = 0
		end
	end
	return currentBudget
end

local function ZombieBudgetProcessing(featureID,excessBudget)
	local thisFeatureBudget
	local currentMetal, maxMetal = Spring.GetFeatureResources(featureID)
	local resDefName, facing = GG.Zombies.GetFeatureResurrectData(featureID)
	local zombieBudget = UnitDefNames[resDefName].cost
	
	if ZOMBIES_PARTIAL_RECLAIM then -- partial reclaim reduces the available metal to spawn units
		zombieBudget = math.floor(zombieBudget * (currentMetal/maxMetal))
	end
	thisFeatureBudget = math.floor(excessBudget + zombieFlatBudget + zombieBudget * zombieBudgetMult)
	
	if zombieFlatBudgetScaler then
		zombieFlatBudget = zombieFlatBudget + zombieFlatBudgetScaler * zombieBudget/100
	end
	
	if zombieBudgetMultScaler then
		zombieBudgetMult = zombieBudgetMult +  zombieBudgetMultScaler * 0.000001 * zombieBudget^1.05
	end
	totalBaseZombieBudget = totalBaseZombieBudget + zombieBudget
	return thisFeatureBudget
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
		Spring.Echo("totalBaseBudgetValue: "..totalBaseZombieBudget)
		Spring.Echo("zombieFlatBudget: "..zombieFlatBudget)
		Spring.Echo("zombieBudgetMult: "..zombieBudgetMult)
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

--TODO Only gaia unit capture becomes slowed
function gadget:UnitTaken(unitID, unitDefID, teamID, newTeamID)
	if zombieUnits[unitID] and newTeamID ~= GaiaTeamID then
		zombieUnits[unitID] = nil
		if zombieDeathOnCaptureChance and zombieDeathOnCaptureChance >= math.random(0,1) then
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

--TODO Only gaia created unit become slowed
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
		featureReviveCycleCount[featureID] = zombieReviveCyclesCount - 1 -- one cycle has passed to reach this point
	else 
		featureReviveCycleCount[featureID] = featureReviveCycleCount[featureID] - 1
	end
	return featureReviveCycleCount[featureID]
end

local function RezFrameCallback(featureID)
	
	if zombieAllyTeamID then
		zombieTeamID = GetRandomTeamIDFromAllyTeam(zombieAllyTeamID)
	end

	local zombieBudget = ZombieBudgetProcessing(featureID,excessBudget)
	
	if zombieReviveOptionCount == 0 then
		excessBudget = HandleZombieRevive(featureID, zombieBudget, nil, nil)
	else
		excessBudget = HandleZombieRevive(featureID, zombieBudget, zombieReviveOptions,zombieReviveOptionCount)
	end
	
	local zombieCyclesRemaining = 0
	if zombieReviveCyclesCount > 1 then
		zombieCyclesRemaining = FeatureReviveCycles(featureID)
	end
	if zombieCyclesRemaining > 0 then
		GG.Zombies.AddFeatureToZombieCountdown(featureID, ZOMBIES_REZ_SPEED, ZOMBIES_REZ_MIN, ZOMBIES_REZ_MAX, RezFrameCallback)
		return
	end
	
	if not zombieWrecksRemain then
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