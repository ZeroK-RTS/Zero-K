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
local initalAllianceCount = -1 --subtract gaia
	for index, allyTeamID in ipairs(Spring.GetAllyTeamList()) do
		local teamlist = Spring.GetTeamList(allyTeamID)
		Spring.Echo(#teamlist)
		if (#teamlist) >0 then
			initalAllianceCount = initalAllianceCount +1
		end
	end
local zombieAllyTeamID = GaiaAllyTeamID
local zombieTeamInput = tonumber(modOptions.zombies_team) or 0 

if zombieTeamInput == 0 then -- 0 translates to gaia zombies
	zombieAllyTeamID = GaiaAllyTeamID
elseif zombieTeamInput > initalAllianceCount then -- larger than teamcount mean things revive onto their parent teams
	zombieAllyTeamID = math.huge
else -- if inbetween 0 and max teamcount, we have a team to spawn on!
	zombieAllyTeamID = zombieTeamInput -1 -- -1 for offset 
	if zombieAllyTeamID == GaiaAllyTeamID then --TODO there is likely a better solution, it seems sometimes Gaia is not the last team in the list
		zombieAllyTeamID = zombieAllyTeamID + 1
	end
end

local zombieTeamFullSlow = tonumber(modOptions.zombies_team_full_speed_mult) or 0
local zombieTeamStartsDead = tonumber(modOptions.zombies_team_starts_dead) or 0
local zombieTeamRevive = tonumber(modOptions.zombies_team_wrecks_revive) or 1


local zombieRezSpeed = tonumber(modOptions.zombies_rezspeed) or 12
local zombieRezSpeedScaler = tonumber(modOptions.zombies_rezspeed_scaler) or 0
local zombieRezSpeedMinuteAdd = tonumber(modOptions.zombies_rezspeed_minute_add) or 0

local ZOMBIES_PERMA_SLOW = tonumber(modOptions.zombies_speed_mult) or 0.5

local ZOMBIES_REZ_MIN = tonumber(modOptions.zombies_delay_min) or 10 -- minimum of 10 seconds
local ZOMBIES_REZ_MAX = tonumber(modOptions.zombies_delay_max) or 100000 --600 only affects things above 7200 cost at 12 rezspeed.

local ZOMBIES_PARTIAL_RECLAIM = tonumber(modOptions.zombies_partial_reclaim) or 0
local zombieOverflowSpawn = tonumber(modOptions.zombies_partial_spawn) or 1

local zombieDeathOnCaptureChance = tonumber(modOptions.zombies_die_on_capture) or 0

local zombieReviveCyclesCount = tonumber(modOptions.zombies_revive_cycles) or 1
local zombieWrecksRemain = tonumber(modOptions.zombies_wrecks_remain) or 0

local zombiesReviveOptionsAsString = (modOptions.zombies_revive_options) or nil 
local zombieReviveOptionMultiRandomise = tonumber(modOptions.zombies_revive_options_multi_random) or 0

local zombieBudgetMult = tonumber(modOptions.zombies_budget_multiplier) or 1
local zombieBudgetMultScaler = tonumber(modOptions.zombies_budget_multiplier_scaler) or 0
local zombieBudgetMultMinuteAdd = tonumber(modOptions.zombies_budget_multiplier_minute_add) or 0

local zombieFlatBudget = tonumber(modOptions.zombies_flat_budget) or 0
local zombieFlatBudgetScaler = tonumber(modOptions.zombies_flat_budget_scaler) or 0
local zombieFlatBudgetMinuteAdd = tonumber(modOptions.zombies_flat_budget_minute_add) or 0

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
	Spring.Echo("totalUnmodifiedReviveBudget: "..totalBaseRevivedBudget)
	Spring.Echo("totalModifiedReviveBudget: "..totalRevivedBudget)
	Spring.Echo("totalRevivedValue: "..totalRevivedValue)
	Spring.Echo("totalReviveCount: "..totalReviveCount)
	Spring.Echo("zombieFlatBudget: "..zombieFlatBudget)
	Spring.Echo("zombieBudgetMult: "..zombieBudgetMult)
	Spring.Echo("currentReviveSpeed: "..zombieRezSpeed)
	Spring.Echo("zombieOverflowBudget: "..excessBudget)
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
	local allyTeamList = Spring.GetTeamList(allyTeamID) or GaiaAllyTeamID
	local teamMateCount = 0
	local teamToSpawnOn
	if allyTeamID == GaiaAllyTeamID then
		return GaiaTeamID
	end
	
	for _,_ in ipairs(allyTeamList) do
		teamMateCount = teamMateCount + 1 
	end
	teamToSpawnOn = allyTeamList[math.random(1,teamMateCount)] or nil
	return teamToSpawnOn
end

local function HandleZombieRevive(featureID, reviveBudget,reviveTeamID,unitDefIDTable)
	local resDefName, facing = GG.Zombies.GetFeatureResurrectData(featureID)
	local zombieUnitDefID = nil --nil means we use the features default revival thingy
	local zombieCost = UnitDefNames[resDefName].metalCost
	if not zombieCost or zombieCost <= 0 then
		zombieCost = UnitDefNames[resDefName].buildTime
	end
	if unitDefIDTable then
		zombieUnitDefID = unitDefIDTable[math.random(1,#unitDefIDTable)]
		zombieCost = UnitDefs[zombieUnitDefID].metalCost or 0
		if zombieCost or zombieCost <= 0 then
			zombieCost = UnitDefs[zombieUnitDefID].buildTime
		end
	end
	
	if not zombieCost or zombieCost <= 0 then
		zombieCost = 200
		Spring.Echo("Unit has no cost set, defaulting to 200")
	end
	local rerollThresholdStep = reviveBudget * zombieReviveOptionMultiRandomise
	local rerollThreshold = reviveBudget - rerollThresholdStep
	Spring.Echo(rerollThresholdStep)
	Spring.Echo(rerollThreshold)
	while reviveBudget >= zombieCost do
		local unitID = GG.Zombies.TurnFeatureIntoUnit(featureID,reviveTeamID,zombieUnitDefID)
		if unitID then
			zombieUnits[unitID] = true
			GG.Zombies.SetZombieBehavior(unitID)
			GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
			totalReviveCount = totalReviveCount +1
			totalRevivedValue = math.floor(totalRevivedValue + zombieCost)
		end
		reviveBudget = reviveBudget - zombieCost
		if zombieUnitDefID and reviveBudget < rerollThreshold then -- Randomises to a new unit if desired
			Spring.Echo("rerolled at ".. reviveBudget)
			rerollThreshold = rerollThreshold - rerollThresholdStep
			zombieUnitDefID = unitDefIDTable[math.random(1,#unitDefIDTable)]
			zombieCost = UnitDefs[zombieUnitDefID].metalCost or 0 
			if not zombieCost or zombieCost <= 0 then
				zombieCost = UnitDefs[zombieUnitDefID].buildTime
			end
			if not zombieCost or zombieCost <= 0 then
				zombieCost = 200
				Spring.Echo("Unit has no cost set, defaulting to 200")
			end
		end
		--TODO should we randomise for each spawn? So far yes, since it gives every possible member of the team a chance for a unit
		if zombieAllyTeamID ~= GaiaAllyTeamID and not (zombieAllyTeamID > initalAllianceCount) then
			reviveTeamID = GetRandomTeamIDFromAllyTeam(zombieAllyTeamID)
		end
	end
	if zombieOverflowSpawn == 1 and math.floor(reviveBudget) > 0 then -- We make a partial health zombie or overflow the budget to the next spawn
		local unitID = GG.Zombies.TurnFeatureIntoUnit(featureID,reviveTeamID,zombieUnitDefID)
		if not unitID then
			return reviveBudget
		end
		zombieUnits[unitID] = true
		GG.Zombies.SetZombieBehavior(unitID)
		GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
		if not ZOMBIES_PARTIAL_RECLAIM == 1 then
			return 0
		end
		totalReviveCount = totalReviveCount +1
		totalRevivedValue = math.floor(totalRevivedValue + zombieCost)
		local health = Spring.GetUnitHealth(unitID) -- TODO something breaks here, check if unit exists?
		if health then --Last zombie spawned gets its health cut by the % of metal it overspent
			Spring.SetUnitHealth(unitID, health*(reviveBudget/zombieCost))
			reviveBudget = 0
		end
	end
	return math.floor(reviveBudget)
end

local function ZombieBudgetProcessing(featureID,excessBudget)
	local thisFeatureBudget
	local currentMetal, maxMetal = Spring.GetFeatureResources(featureID)
	local resDefName, facing = GG.Zombies.GetFeatureResurrectData(featureID)
	local zombieBudget = UnitDefNames[resDefName].metalCost
	
	if ZOMBIES_PARTIAL_RECLAIM == 1 then -- partial reclaim reduces the available metal to spawn units
		zombieBudget =  math.floor(zombieBudget * (currentMetal/maxMetal))
	end
	thisFeatureBudget = math.floor(excessBudget + zombieFlatBudget + zombieBudget * zombieBudgetMult)
	
	--TODO these scaling functions could use improvement in terms of design goal and intended effect
	if zombieFlatBudgetScaler ~= 0 then
		zombieFlatBudget = zombieFlatBudget + zombieFlatBudgetScaler * zombieBudget/100 --TODO Took out flooring, lets see if it desyncs eventually?
	end
	if zombieBudgetMultScaler ~= 0 then
		zombieBudgetMult = zombieBudgetMult + 0.000001 * math.floor(zombieBudgetMultScaler  * zombieBudget^1.05)
	end
	if zombieRezSpeedScaler ~= 0 then
		zombieRezSpeed = zombieRezSpeed + zombieRezSpeedScaler * zombieBudget/1000 --TODO Took out flooring, lets see if it desyncs eventually?
	end
	
	totalBaseRevivedBudget = math.floor(totalBaseRevivedBudget + zombieBudget)
	totalRevivedBudget = math.floor(totalRevivedBudget + thisFeatureBudget)
	return thisFeatureBudget
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
	local reviveTeamID = GaiaTeamID
	if zombieAllyTeamID ~= GaiaAllyTeamID and not (zombieAllyTeamID > initalAllianceCount) then
		reviveTeamID = GetRandomTeamIDFromAllyTeam(zombieAllyTeamID)
	end
	if zombieAllyTeamID > initalAllianceCount then
		reviveTeamID = Spring.GetFeatureTeam(featureID) or GaiaTeamID
	end
	
	local zombieBudget = ZombieBudgetProcessing(featureID,excessBudget)
	if zombieBudget <= 0 then
		return
	end
	
	if #zombieReviveOptions == 0 then
		excessBudget = HandleZombieRevive(featureID, zombieBudget,reviveTeamID, nil)
	else
		excessBudget = HandleZombieRevive(featureID, zombieBudget,reviveTeamID, zombieReviveOptions)
	end
	
	local zombieCyclesRemaining = 0
	if zombieReviveCyclesCount > 1 then
		zombieCyclesRemaining = FeatureReviveCycles(featureID)
	end
	if zombieCyclesRemaining > 0 then
		GG.Zombies.AddFeatureToZombieCountdown(featureID, zombieRezSpeed, ZOMBIES_REZ_MIN, ZOMBIES_REZ_MAX, RezFrameCallback)
		return
	end
	
	if zombieWrecksRemain == 0 then
		Spring.DestroyFeature(featureID)
	end
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
	if f%1800 == 1 and f ~= 1 then
		zombieBudgetMult 	= zombieBudgetMult 	+ zombieBudgetMultMinuteAdd
		zombieFlatBudget 	= zombieFlatBudget 	+ zombieFlatBudgetMinuteAdd
		zombieRezSpeed 		= zombieRezSpeed 	+ zombieRezSpeedMinuteAdd
	end
	if f == 1 then
		spSetTeamResource(GaiaTeamID, "ms", 500)
		spSetTeamResource(GaiaTeamID, "es", 10500)
		if zombieTeamStartsDead == 1 then -- TODO doing it on game start lets people plop a fac. maybe there is some other way of doing things
			for _, unitID in ipairs(spGetAllUnits()) do
				if zombieAllyTeamID == Spring.GetUnitAllyTeam(unitID)then
					Spring.DestroyUnit(unitID)
				end
			end
		end
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

function gadget:FeatureCreated(featureID, allyTeam)
	if zombieTeamRevive == 0 and allyTeam == zombieAllyTeamID then
		return
	end
	GG.Zombies.AddFeatureToZombieCountdown(featureID, zombieRezSpeed, ZOMBIES_REZ_MIN, ZOMBIES_REZ_MAX, RezFrameCallback)
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
		GG.Zombies.AddFeatureToZombieCountdown(features[i], zombieRezSpeed, ZOMBIES_REZ_MIN, ZOMBIES_REZ_MAX, RezFrameCallback)
	end
end

local function SetGlobalReviveAllyTeam(newZombieAllyTeamID)
	zombieAllyTeamID = newZombieAllyTeamID
end

local function GetGlobalReviveAllyTeam()
	return zombieAllyTeamID
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
		GetGlobalReviveAllyTeam = GetGlobalReviveAllyTeam,
	}
end

function gadget:GameStart()
	ReInit() -- anything it does doesnt mess with existing zombies
	Spring.Echo("zombieAllyTeamID: "..zombieAllyTeamID)
	Spring.Echo("AllyTeamCount: "..initalAllianceCount)
	Spring.Echo("GaiaAllyTeamID: "..GaiaAllyTeamID)
end