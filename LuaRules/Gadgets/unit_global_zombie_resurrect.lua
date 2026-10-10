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

local zombieTeamID = GaiaTeamID
local zombieAllyTeamID = GaiaAllyTeamID
local zombieTeamInput = tonumber(modOptions.zombies_team) or GaiaAllyTeamID -- 0 translates to gaia zombies
if zombieTeamInput ~= 0 and zombieTeamInput ~= GaiaAllyTeamID then
	zombieAllyTeamID = zombieTeamInput -1 --Teams are offset by 1 in the modoptions, and nil when 0
end
local zombieTeamFullSlow = tonumber(modOptions.zombies_team_full_slow) or 0

local ZOMBIES_REZ_SPEED = tonumber(modOptions.zombies_rezspeed) or 12

local ZOMBIES_PERMA_SLOW = tonumber(modOptions.zombies_permaslow) or 0.5

local ZOMBIES_REZ_MIN = tonumber(modOptions.zombies_delay) or 10 -- minimum of 10 seconds, max is determined by rez speed
local ZOMBIES_REZ_MAX = tonumber(modOptions.zombies_delay_max) or 100000 --600 only affects things above 7200 cost at 12 rezspeed.

local ZOMBIES_PARTIAL_RECLAIM = tonumber(modOptions.zombies_partial_reclaim) or 0

local zombieDeathOnCaptureChance = tonumber(modOptions.zombies_die_on_capture) or 0

local zombieReviveCyclesCount = tonumber(modOptions.zombies_revive_cycles) or 1
local zombieWrecksRemain = tonumber(modOptions.zombies_wrecks_remain) or 0

local zombiesReviveOptionsAsString = (modOptions.zombies_revive_options) or nil 
local zombieReviveOptionMultiRandomise = tonumber(modOptions.zombies_revive_options_multi_random) or nil
local zombieOverflowSpawn = tonumber(modOptions.zombies_revive_options_overflow_spawn) or 1

local zombieBudgetMult = tonumber(modOptions.zombies_budget_multiplier) or 1
local zombieBudgetMultScaler = tonumber(modOptions.zombies_budget_multiplier_scaler) or 0

local zombieFlatBudget = tonumber(modOptions.zombies_flat_budget) or 0
local zombieFlatBudgetScaler = tonumber(modOptions.zombies_flat_budget_scaler) or 0

local zombieUnits = {}
local featureReviveCycleCount = {}
local excessBudget = 0
local zombieReviveOptionCount = 0
local zombieReviveOptions = {} -- allows duplicates

--Diagnostic variables
local totalBaseRevivedBudget = 0
local totalRevivedBudget = 0
local totalRevivedValue = 0
local totalReviveCount = 0

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

local function DiagnosticsVarDump()
	--May be good to have a screen like chickens
	Spring.Echo("-------------")
	Spring.Echo("totalBaseRevivedBudget: "..totalBaseRevivedBudget)
	Spring.Echo("totalRevivedBudget: "..totalRevivedBudget)
	Spring.Echo("totalRevivedValue: "..totalRevivedValue)
	Spring.Echo("totalReviveCount: "..totalReviveCount)
	Spring.Echo("zombieExcessBudget: "..excessBudget)
	Spring.Echo("zombieFlatBudget: "..zombieFlatBudget)
	Spring.Echo("zombieBudgetMult: "..zombieBudgetMult)
	Spring.Echo("-------------")
end

-- TODO Is there a global utility function for this?
local function IsTeamInAllyTeam (allyTeamID, teamIDtoCheck)
	local allyTeamList = Spring.GetTeamList(allyTeamID)
	if not allyTeamList then -- shouldnt happen but oh well
		return false
	end
    for index, teamID in ipairs(allyTeamList) do
        if teamID == teamIDtoCheck then
            return true
        end
    end
    return false
end

local function GetRandomTeamIDFromAllyTeam(allyTeamID) -- function since the team zombies revive onto could be changed mid game.
	local allyTeamList = Spring.GetTeamList(allyTeamID)
	local teamMateCount = 0
	local teamToSpawnOn
	if allyTeamID == GaiaAllyTeamID or not allyTeamList then
		return GaiaTeamID
	end
	
	for _,_ in ipairs(allyTeamList) do
		teamMateCount = teamMateCount + 1 
	end
	teamToSpawnOn = allyTeamList[math.random(1,teamMateCount)] or nil
	return teamToSpawnOn
end

local function HandleZombieRevive(featureID, currentBudget,unitDefIDTable)
	local resDefName, facing = GG.Zombies.GetFeatureResurrectData(featureID)
	local zombieUnitDefID = nil --nil means we use the features default revival thingy
	local zombieCost = UnitDefNames[resDefName].cost
	
	if unitDefIDTable then
		zombieUnitDefID = unitDefIDTable[math.random(1,#unitDefIDTable)]
		zombieCost = UnitDefs[zombieUnitDefID].cost
	end

	while currentBudget >= zombieCost do --TODO zombie cost can end up as a float somehow?
		local unitID = GG.Zombies.TurnFeatureIntoUnit(featureID,zombieTeamID,zombieUnitDefID)
		if unitID then
			zombieUnits[unitID] = true
			GG.Zombies.SetZombieBehavior(unitID)
			if ZOMBIES_PERMA_SLOW then
				GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
			end
			totalReviveCount = totalReviveCount +1
			totalRevivedValue = math.floor(totalRevivedValue + zombieCost)
		end
		currentBudget = currentBudget - zombieCost
		if zombieReviveOptionMultiRandomise and zombieUnitDefID then -- Randomises to a new unit if desired
			zombieUnitDefID = unitDefIDTable[math.random(1,#unitDefIDTable)]
			zombieCost = UnitDefs[zombieUnitDefID].cost
		end
		--TODO do we randomise for each spawn?
		if zombieAllyTeamID ~= GaiaAllyTeamID then
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
		if not ZOMBIES_PARTIAL_RECLAIM == 1 then
			return 0
		end
		totalReviveCount = totalReviveCount +1
		totalRevivedValue = math.floor(totalRevivedValue + zombieCost)
		
		local health = Spring.GetUnitHealth(unitID) -- TODO something breaks here, check if unit exists?
		if health then --Last zombie spawned gets its health cut by the % of metal it overspent
			Spring.SetUnitHealth(unitID, health*((UnitDefs[unitDefID].cost + currentBudget)/UnitDefs[unitDefID].cost))
			currentBudget = 0
		end
	end
	return math.floor(currentBudget)
end

local function ZombieBudgetProcessing(featureID,excessBudget)
	local thisFeatureBudget
	local currentMetal, maxMetal = Spring.GetFeatureResources(featureID)
	local resDefName, facing = GG.Zombies.GetFeatureResurrectData(featureID)
	local zombieBudget = UnitDefNames[resDefName].cost
	
	if ZOMBIES_PARTIAL_RECLAIM == 1 then -- partial reclaim reduces the available metal to spawn units
		zombieBudget =  math.ceil(zombieBudget * (currentMetal/maxMetal))
	end
	thisFeatureBudget = math.floor(excessBudget + zombieFlatBudget + zombieBudget * zombieBudgetMult)
	
	if zombieFlatBudgetScaler ~= 0 then
		zombieFlatBudget = math.floor(zombieFlatBudget + zombieFlatBudgetScaler * zombieBudget/100)
	end
	
	if zombieBudgetMultScaler ~= 0 then
		zombieBudgetMult = zombieBudgetMult + 0.000001 * math.floor(zombieBudgetMultScaler  * zombieBudget^1.05)
	end
	totalBaseRevivedBudget = math.floor(totalBaseRevivedBudget + zombieBudget)
	totalRevivedBudget = math.floor(totalRevivedBudget + thisFeatureBudget)
	return thisFeatureBudget
end

local function CheckZombieOrders()	-- Only Gaia units recheck their orders
	for unitID, _ in pairs(zombieUnits) do
		if spGetUnitTeam(unitID) == GaiaTeamID then
			local queueSize = spGetUnitCommandCount(unitID)
			if not (queueSize) or not (queueSize > 0) then
				GG.Zombies.SetZombieBehavior(unitID)
			end
		end
	end
end

function gadget:GameFrame(f)
	if (f%640) == 1 then
		CheckZombieOrders()
		DiagnosticsVarDump()
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
	-- Taking a unit that is marked as a zombie unslows it/rolls for death on capture.
	if zombieUnits[unitID] then
		if zombieDeathOnCaptureChance > math.random(0,1) then
			Spring.DestroyUnit(unitID)
			return
		end
		GG.Zombies.SetZombieSpeedMult(unitID, 1)
		zombieUnits[unitID] = nil
		return
	end
	-- if Gaia captures, applies movement and slow
	if newTeamID == GaiaTeamID then
		zombieUnits[unitID] = true
		GG.Zombies.SetZombieBehavior(unitID)
		GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
		return
	end
	-- if a zombieallyteam with full slow enabled captures, the unit is slowed but is not given orders
	if IsTeamInAllyTeam(zombieAllyTeamID,newTeamID) and zombieTeamFullSlow == 1 then
		zombieUnits[unitID] = true
		GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
	end
end


function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	-- GaiaTeam units are slowed and behave like zombies by default
	if teamID == GaiaTeamID then
		zombieUnits[unitID] = true
		GG.Zombies.SetZombieBehavior(unitID)
		GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
		return
	end
	-- If on Zombie Allyteam with Full slow enabled, slows all created units
	if IsTeamInAllyTeam(zombieAllyTeamID,teamID) and zombieTeamFullSlow == 1 then
		zombieUnits[unitID] = true
		GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
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
	
	if zombieAllyTeamID ~= GaiaAllyTeamID then
		zombieTeamID = GetRandomTeamIDFromAllyTeam(zombieAllyTeamID)
	end

	local zombieBudget = ZombieBudgetProcessing(featureID,excessBudget)
	
	if zombieReviveOptionCount == 0 then
		excessBudget = HandleZombieRevive(featureID, zombieBudget, nil)
	else
		excessBudget = HandleZombieRevive(featureID, zombieBudget, zombieReviveOptions)
	end
	
	local zombieCyclesRemaining = 0
	if zombieReviveCyclesCount > 1 then
		zombieCyclesRemaining = FeatureReviveCycles(featureID)
	end
	if zombieCyclesRemaining > 0 then
		GG.Zombies.AddFeatureToZombieCountdown(featureID, ZOMBIES_REZ_SPEED, ZOMBIES_REZ_MIN, ZOMBIES_REZ_MAX, RezFrameCallback)
		return
	end
	
	if zombieWrecksRemain == 0 then
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

local function SetGlobalReviveAllyTeam(newZombieAllyTeamID)
	zombieAllyTeamID = newZombieAllyTeamID
	if newZombieAllyTeamID == GaiaAllyTeamID then
		zombieTeamID = GaiaTeamID
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
	
	GG.ZombiesGlobal = {
		SetGlobalReviveAllyTeam = SetGlobalReviveAllyTeam,
	}
end

function gadget:GameStart()
	ReInit() -- anything it does doesnt mess with existing zombies
end