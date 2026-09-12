--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- pathing tester. Is this the correct way to import these things?
VFS.Include("LuaRules/Configs/CAI/accessory/targetReachableTester.lua")

-- unsure if these are different, differentiating between gaia and "zombie" team somehow may be good?
local GaiaTeamID     = Spring.GetGaiaTeamID()
local GaiaAllyTeamID = select(6, Spring.GetTeamInfo(GaiaTeamID, false))

local mapWidth
local mapHeight

local REZ_SOUND = "sounds/misc/resurrect.wav"

--unused, may be used depending on how things shake out
local ZOMBIE_SOUNDS = {
	"sounds/misc/zombie_1.wav",
	"sounds/misc/zombie_2.wav",
	"sounds/misc/zombie_3.wav",
}




-- Zombie resurrect

-- unsure if necessary, seems like just an extra failsafe
local function GetFeatureResurrectData(featureID)
	local featureDefName, facing = Spring.GetFeatureResurrect(featureID)
	if featureDefName == "" then
		local featureDef = FeatureDefs[Spring.GetFeatureDefID(featureID)]
		local featureName = featureDef.name or ""
		if featureDef.resurrectable == 1 then
			featureDefName = featureName:gsub('(.*)_.*', '%1') --filter out _dead
			facing = facing or 0
		end
	end
	return featureDefName, facing
end

local function TurnFeatureIntoUnit(featureID,teamID,reclaimPercentHealth)
  
  local featureDefName,facing = GetFeatureResurrectData(featureID)
  local x, y, z = Spring.GetFeaturePosition(featureID)
  
  local unitID = Spring.CreateUnit(featureDefName, x, y, z, facing, teamID)
  
  -- Unit and Wreck exist both
  -- could let there be a function passed to this function, that returns the Unit ID for transfer of values

 	if (unitID) then
		gadgetHandler:NotifyUnitCreatedByMechanic(unitID, false, "zombies")
		local size = UnitDefNames[featureDefName].xsize
		Spring.SpawnCEG("resurrect", x, y, z, 0, 0, 0, size)
		Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, 2, 0)
		GG.PlayFogHiddenSound(REZ_SOUND, 12, x, y, z)
		
		if reclaimPercentHealth then
			local currentMetal, maxMetal = Spring.GetFeatureResources(featureID)
			if currentMetal and maxMetal and (maxMetal > 0) then
				local health = Spring.GetUnitHealth(unitID)
				if health then
					Spring.SetUnitHealth(unitID, health*(currentMetal/maxMetal))
				end
			end
		end
    end
	
  Spring.DestroyFeature(featureID)
  return unitID
end

-- Works on non zombie units too.
local function SetZombieSpeedMult(unitID,speedMult)
	if type(speedMult) ~= 'number' or speedMult < 0 then
		error("SetZombieSpeedMult: mult must be number >= 0")
	end
	Spring.SetUnitRulesParam(unitID, "zombieSpeedMult", speedMult, LOS_ACCESS)
	GG.UpdateUnitAttributes(unitID)
end


-- Zombie commands

local function RandomFactoryOrders(unitID, unitDefID) -- give factory something to do
	if not Spring.GetUnitIsDead(unitID) then
		local buildopts = UnitDefs[unitDefID].buildOptions
		if (not buildopts) or #buildopts <= 0 then
			return
		end
		local orders = {}
		for i = 1, math.random(10, 30) do
			orders[#orders + 1] = {-buildopts[math.random(1, #buildopts)], 0, 0 }
			Spring.GiveOrderArrayToUnit(unitID, orders)
		end
	end
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
			local dist = math.diag(x, z, ox ,oz)
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
	
	local rx,rz,ry
	local orders = {}
	local near_ally
	if (UnitDefs[unitDefID].canAttack) then
    -- May be uncessecary, but it depends on the kind of behavior that is wanted. I suppose mirroring the previous behavior is the objective
		near_ally = GetUnitNearestAlly(unitID, 300)
		if (near_ally) then
			if Spring.GetUnitCurrentCommand(near_ally) == CMD.GUARD then
				near_ally = nil -- avoiding chain guards
			end
		end
	end
	local x,y,z = Spring.GetUnitPosition(unitID)
	if (near_ally) and  math.random(0, 5) < 4 then -- 60% chance to guard nearest ally
		orders[#orders + 1] = {CMD.GUARD, {near_ally}, 0}
	end
	for i = 1, math.random(10, 30) do
		rx = math.random(0, mapWidth)
		rz = math.random(0, mapHeight)
		ry = Spring.GetGroundHeight(rx,rz)
		if IsTargetReallyReachable(unitID, rx, ry, rz, x, y, z) then
			orders[#orders+1] = {CMD.FIGHT, {rx, ry, rz}, CMD.OPT_SHIFT}
		end
	end
	if (#orders > 0) then
		if not Spring.GetUnitIsDead(unitID) then
			Spring.GiveOrderArrayToUnitArray({unitID},orders)
		end
	end
	if (UnitDefs[unitDefID].isFactory) then
		RandomFactoryOrders(unitID, unitDefID) -- give factory something to do
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
