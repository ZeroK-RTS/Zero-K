if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
	return {
		name        = "Zombie helper api",
		desc        = "The place to handle your zombie esque needs!",
		author      = "TomFyuri, Stiofan",
		date        = "Mar 2014",
		license     = "GPL v2 or later",
		layer       = math.huge,
		enabled     = true
	}
end

VFS.Include("LuaRules/Configs/CAI/accessory/targetReachableTester.lua")

local GaiaTeamID     = Spring.GetGaiaTeamID()
local GaiaAllyTeamID = select(6, Spring.GetTeamInfo(GaiaTeamID, false))

local mapWidth
local mapHeight

local REZ_SOUND = "sounds/misc/resurrect.wav"

-- Considers features of "wreck" types always rezzable,
-- somewhat arbitrarily since this doesn't really happen either way,
-- although makes testing via /give less annoying
local function GetFeatureResurrectData(featureID)
	local featureDefName, facing = Spring.GetFeatureResurrect(featureID)
	if featureDefName == "" then
		local featureDef = FeatureDefs[Spring.GetFeatureDefID(featureID)]
		local featureName = featureDef.name or ""
		if featureDef.resurrectable == 1 then
			featureDefName = featureName:gsub('(.*)_.*', '%1') -- filter out _dead
			facing = facing or 0
		end
	end
	return featureDefName, facing
end

local function TurnFeatureIntoUnit(featureID, teamID, reclaimPercentHealth)
	local featureDefName, facing = GetFeatureResurrectData(featureID)
	local x, y, z = Spring.GetFeaturePosition(featureID)

	local partialReclaim = 1
	if reclaimPercentHealth then
		local currentMetal, maxMetal = Spring.GetFeatureResources(featureID)
		if currentMetal and maxMetal and (maxMetal > 0) then
			partialReclaim = currentMetal / maxMetal
		end
	end

	local unitID = Spring.CreateUnit(featureDefName, x, y, z, facing, teamID)
	Spring.DestroyFeature(featureID)

	if unitID then
		gadgetHandler:NotifyUnitCreatedByMechanic(unitID, false, "zombies")
		local size = UnitDefNames[featureDefName].xsize
		Spring.SpawnCEG("resurrect", x, y, z, 0, 0, 0, size)
		Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, CMD.FIRESTATE_FIREATWILL, 0)
		GG.PlayFogHiddenSound(REZ_SOUND, 12, x, y, z)
		if partialReclaim ~= 1 then
			local health = Spring.GetUnitHealth(unitID)
			if health then
				Spring.SetUnitHealth(unitID, health * partialReclaim)
			end
		end
	end

	return unitID
end

-- Just an attribute, works on non zombie units too.
local function SetZombieSpeedMult(unitID, speedMult)
	if type(speedMult) ~= 'number' or speedMult < 0 then
		error("SetZombieSpeedMult: mult must be number >= 0")
	end

	Spring.SetUnitRulesParam(unitID, "zombieSpeedMult", speedMult, LOS_ACCESS)
	GG.UpdateUnitAttributes(unitID)
end

-- Zombie commands
local function RandomFactoryOrders(unitID, unitDefID)
	if Spring.GetUnitIsDead(unitID) then
		return
	end

	local buildopts = UnitDefs[unitDefID].buildOptions
	if not buildopts or #buildopts <= 0 then
		return
	end

	local orders = {}
	for i = 1, math.random(10, 30) do
		local buildeeDefID = buildopts[math.random(1, #buildopts)]
		orders[#orders + 1] = {-buildeeDefID, 0, 0}
	end

	Spring.GiveOrderArrayToUnit(unitID, orders)
end

local function GetUnitNearestAlly(unitID, range)
	local best_ally
	local best_dist
	local x, y, z = Spring.GetUnitPosition(unitID)
	local units = Spring.GetUnitsInCylinder(x, z, range)
	for i = 1, #units do
		local allyID = units[i]
		local allyTeam = Spring.GetUnitTeam(allyID)
		local allyDefID = Spring.GetUnitDefID(allyID)
		if (allyID ~= unitID) and (allyTeam == GaiaTeamID) and (Spring.Utilities.getMovetype(UnitDefs[allyDefID]) ~= false) then
			local ox, oy, oz = Spring.GetUnitPosition(allyID)
			local dist = math.diag(x - ox, z - oz)
			if IsTargetReallyReachable(unitID, ox, oy, oz, x, y, z) and ((best_dist == nil) or (dist < best_dist)) then
				best_ally = allyID
				best_dist = dist
			end
		end
	end
	return best_ally
end

local function GiveZombiesRandomOrders(unitID)
	local unitDefID = (not Spring.GetUnitIsDead(unitID)) and Spring.GetUnitDefID(unitID)
	if not unitDefID then
		return
	end

	local x,y,z = Spring.GetUnitPosition(unitID)
	local orders = {}

	local near_ally
	if UnitDefs[unitDefID].canAttack then
		near_ally = GetUnitNearestAlly(unitID, 300)
		if near_ally
		and Spring.GetUnitCurrentCommand(near_ally) ~= CMD.GUARD -- avoid chain guards
		and math.random() < 0.6 -- 60% chance to guard nearest ally, arbitrary
		then
			orders[#orders + 1] = {CMD.GUARD, near_ally, 0}
		end
	end

	for i = 1, math.random(10, 30) do
		local rx = math.random(0, mapWidth)
		local rz = math.random(0, mapHeight)
		local ry = Spring.GetGroundHeight(rx, rz)
		if IsTargetReallyReachable(unitID, rx, ry, rz, x, y, z) then
			orders[#orders+1] = {CMD.FIGHT, {rx, ry, rz}, CMD.OPT_SHIFT}
		end
	end

	Spring.GiveOrderArrayToUnit(unitID, orders)

	if UnitDefs[unitDefID].isFactory then
		-- for factories, add build orders since the above is just the rally queue
		RandomFactoryOrders(unitID, unitDefID)
	end
end

function gadget:Initialize()

	mapWidth = Game.mapSizeX
	mapHeight = Game.mapSizeZ

	GG.Zombies = {
		TurnFeatureIntoUnit     = TurnFeatureIntoUnit,
		SetZombieSpeedMult      = SetZombieSpeedMult,
		SetZombieBehavior       = GiveZombiesRandomOrders,
		GetFeatureResurrectData = GetFeatureResurrectData
	}
end
