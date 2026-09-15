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

local zombies = {}

local ZOMBIES_REZ_MIN = tonumber(modOptions.zombies_delay)
if (tonumber(ZOMBIES_REZ_MIN) == nil) then
	-- minimum of 10 seconds, max is determined by rez speed
	ZOMBIES_REZ_MIN = 10
end

local ZOMBIES_REZ_SPEED = tonumber(modOptions.zombies_rezspeed)
if (tonumber(ZOMBIES_REZ_SPEED) == nil) then
	-- 12m/s, big units have a really long time to respawn
	ZOMBIES_REZ_SPEED = 12
end

local ZOMBIES_PERMA_SLOW = tonumber(modOptions.zombies_permaslow)
if (tonumber(ZOMBIES_PERMA_SLOW) == nil) then
	-- from 0 to 1, symbolises from 0% to 50% slow which is always on
	ZOMBIES_PERMA_SLOW = 1
end

if ZOMBIES_PERMA_SLOW == 0 then
	ZOMBIES_PERMA_SLOW = nil
else
	ZOMBIES_PERMA_SLOW = 1 - ZOMBIES_PERMA_SLOW*0.5
end

local ZOMBIES_PARTIAL_RECLAIM = (tonumber(modOptions.zombies_partial_reclaim) == 1)

local function CheckZombieOrders()	-- i can't rely on Idle because if for example unit is unloaded it doesnt count as idle... weird
	for unitID, _ in pairs(zombies) do
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
	if zombies[unitID] then
		zombies[unitID] = nil
	end
end

function gadget:UnitTaken(unitID, unitDefID, teamID, newTeamID)
	if zombies[unitID] and newTeamID ~= GaiaTeamID then
		zombies[unitID] = nil
		-- taking away zombie from zombie team unpermaslows it
		if ZOMBIES_PERMA_SLOW then
			GG.Zombies.SetZombieSpeedMult(unitID, 1)
		end
	elseif newTeamID == GaiaTeamID then
		GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
		GG.Zombies.SetZombieBehavior(unitID)
		zombies[unitID] = true
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	if (teamID == GaiaTeamID) and (builderID == GaiaTeamID) then
		GG.Zombies.SetZombieBehavior(unitID)
		zombies[unitID] = true
		if ZOMBIES_PERMA_SLOW then
			local maxHealth = select(2, spGetUnitHealth(unitID)) -- TODO is this check something necessary? or could it be removed
			if maxHealth then
				GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
			end
		end
	end
end

local function RezFrameCallback(featureID)
	local unitID = GG.Zombies.TurnFeatureIntoUnit(featureID,GaiaTeamID,ZOMBIES_PARTIAL_RECLAIM, nil)
	zombies[unitID] = true
	GG.Zombies.SetZombieSpeedMult(unitID, ZOMBIES_PERMA_SLOW)
	GG.Zombies.SetZombieBehavior(unitID)
end

function gadget:FeatureCreated(featureID, allyTeam)
	GG.Zombies.AddFeatureToZombieCountdown(featureID, ZOMBIES_REZ_SPEED, ZOMBIES_REZ_MIN, RezFrameCallback) 
end

local function ReInit()
	local units = spGetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		local unitTeam = spGetUnitTeam(unitID)
		if (unitTeam == GaiaTeamID) then
			zombies[unitID] = true
			GG.Zombies.SetZombieSpeedMult(unitID,ZOMBIES_PERMA_SLOW)
			GG.Zombies.SetZombieBehavior(unitID)
		end
	end
	local features = spGetAllFeatures()
	for i = 1, #features do
		GG.Zombies.AddFeatureToZombieCountdown(features[i], ZOMBIES_REZ_SPEED, ZOMBIES_REZ_MIN, RezFrameCallback)
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