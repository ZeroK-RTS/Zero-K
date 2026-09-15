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
local WARNING_TIME = 5 -- set to 5 for sounds and such to sync well.
local random = math.random
local floor = math.floor

local mapWidth
local mapHeight

local gameframe = 0

local NonZombies = {
	["asteroid"] = true,
}

local CEG_SPAWN = [[zombie]]
local REZ_SOUND = "sounds/misc/resurrect.wav"
local ZOMBIE_SOUNDS = {
	"sounds/misc/zombie_1.wav",
	"sounds/misc/zombie_2.wav",
	"sounds/misc/zombie_3.wav",
}

local resurrectingFeatures = {} -- contains inital gameframe, base rez time, frame rez should complete and a callback function if someone wants to reuse the functionality



-- unsure if necessary, seems like just an extra failsafe

-- Get Feature Defname and facing
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

-- Zombie resurrect
-- Turns a feature into a unit if applicable. Has a callback returning featureID and unitID for data transfer. Returns unitID.
local function TurnFeatureIntoUnit(featureID,teamID,reclaimPercentHealthBool, unitReviveCallback)
	local featureDefName,facing = GetFeatureResurrectData(featureID)
	local x, y, z = Spring.GetFeaturePosition(featureID)

	local unitID = Spring.CreateUnit(featureDefName, x, y, z, facing, teamID)

	if not (unitID) then
		return nil
	end

	gadgetHandler:NotifyUnitCreatedByMechanic(unitID, false, "zombies")
	local size = UnitDefNames[featureDefName].xsize
	Spring.SpawnCEG("resurrect", x, y, z, 0, 0, 0, size)
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, 2, 0)
	GG.PlayFogHiddenSound(REZ_SOUND, 12, x, y, z)

	if reclaimPercentHealthBool then
		local currentMetal, maxMetal = Spring.GetFeatureResources(featureID)
		if currentMetal and maxMetal and (maxMetal > 0) then
			local health = Spring.GetUnitHealth(unitID)
			if health then
				Spring.SetUnitHealth(unitID, health*(currentMetal/maxMetal))
			end
		end
	end

	-- Unit and Wreck exist both for value transfer
	if (unitReviveCallback) then
		unitReviveCallback(unitID,featureID)
	end

	Spring.DestroyFeature(featureID)
	return unitID
end
 
-- Sets the zombie specific speed multiplier. Works on non zombie units too.
local function SetZombieSpeedMult(unitID,speedMult)
	if type(speedMult) ~= 'number' or speedMult < 0 then
		error("SetZombieSpeedMult: mult must be number >= 0")
	end
	Spring.SetUnitRulesParam(unitID, "zombieSpeedMult", speedMult, LOS_ACCESS)
	GG.UpdateUnitAttributes(unitID)
end


-- Zombie commands

local function RandomFactoryOrders(unitID, unitDefID) -- give factory something to do
	if Spring.GetUnitIsDead(unitID) then
		return
	end
	local buildopts = UnitDefs[unitDefID].buildOptions
	if (not buildopts) or #buildopts <= 0 then
		return
	end
	local orders = {}
	for i = 1, random(10, 30) do
		orders[#orders + 1] = {-buildopts[random(1, #buildopts)], 0, 0 }
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

-- Applies Random Attackmove orders and Factory commands to units.
local function SetZombieBehavior(unitID)
	local unitDefID = (not Spring.GetUnitIsDead(unitID)) and Spring.GetUnitDefID(unitID)
	if not unitDefID then
		return
	end
	
	Spring.GiveOrderToUnit(unitID, CMD.MOVE_STATE, 2, 0)
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
	if (near_ally) and  random(0, 5) < 4 then -- 60% chance to guard nearest ally
		orders[#orders + 1] = {CMD.GUARD, {near_ally}, 0}
	end
	for i = 1, random(10, 30) do
		local rx = random(0, mapWidth)
		local rz = random(0, mapHeight)
		local ry = Spring.GetGroundHeight(rx,rz)
		if IsTargetReallyReachable(unitID, rx, ry, rz, x, y, z) then
			orders[#orders+1] = {CMD.FIGHT, {rx, ry, rz}, CMD.OPT_SHIFT}
		end
	end
	
	Spring.GiveOrderArrayToUnit(unitID,orders)
	if (UnitDefs[unitDefID].isFactory) then
		RandomFactoryOrders(unitID, unitDefID) -- give factory something to do
	end
end
	
-- Adds a wreck into the zombie countdown table and returns it for further modification.
-- Use the rezFrameCallback to repurpose the system for other effects or chain into TurnFeatureIntoUnit for a revived unit with ID Callback.
-- If no callback is provided, revives the wreck as a unslowed zombie unit.
local function AddFeatureToZombieCountdown(featureID, buildpower, minRezTime, rezFrameCallback)
	local resName, face = GetFeatureResurrectData(featureID)
	if resName and face and not resurrectingFeatures[featureID] then
		local ud = resName and UnitDefNames[resName]
		if ud and not NonZombies[resName] then
			local rezBaseTime = ud.metalCost / buildpower
			local rezTime = rezBaseTime
			local _,_,_,_,reclaimPercent,_ = Spring.GetFeatureResources(featureID)
			
			rezTime = rezBaseTime + rezBaseTime * (1 - reclaimPercent)

			if (rezTime < minRezTime) then
				rezTime = minRezTime
			end
			resurrectingFeatures[featureID] = {
				rezInitFrame = gameframe, 				-- frame Feature was queued
				rezBaseTime = rezBaseTime, 				-- base resurrect time in seconds
				rezFrame = gameframe + rezTime * 32,	-- frame the resurrect completes or the callback is fired.
				rezFrameCallback = rezFrameCallback, 	-- callback function fired on rezFrame
				rezWarningTime = WARNING_TIME,			-- warning time in seconds for base particles and sfx, set 0 to hide.
				reclaimPercent = reclaimPercent, 		-- reclaim left in feature in % to compare and adjust reztime
			}
			return resurrectingFeatures[featureID]
		end
	end
	return nil
end

-- Get and modify the table as you wish.
local function GetZombieResurrectData()
	return resurrectingFeatures
end

-- Reclaiming the wreck can stretch the revive time up to 2x the base time.
function gadget:AllowFeatureBuildStep(builderID, builderTeam, featureID, featureDefID, part)
	if (resurrectingFeatures[featureID]) then
		local rezInitFrame = resurrectingFeatures[featureID].rezInitFrame
		local rezBaseTime = resurrectingFeatures[featureID].rezBaseTime
		local reclaimPercent = resurrectingFeatures[featureID].reclaimPercent
		
		reclaimPercent = reclaimPercent + part
		local rezTime = rezBaseTime + rezBaseTime * (1 - reclaimPercent)
		resurrectingFeatures[featureID].rezFrame = rezInitFrame + rezTime * 32
		
		resurrectingFeatures[featureID].reclaimPercent = reclaimPercent
	end
	return true
end

function gadget:FeatureDestroyed(featureID, allyTeam)
	if (resurrectingFeatures[featureID]) then
		resurrectingFeatures[featureID] = nil
	end
end

function gadget:GameFrame(f)
	gameframe = f
	if f%32 ~= 0 then
		return
	end
	local spSpawnCEG = Spring.SpawnCEG -- putting the localization here because cannot localize in global scope since spring 97
	for featureID in pairs(resurrectingFeatures) do
		local rezFrame = resurrectingFeatures[featureID].rezFrame
		if rezFrame <= gameframe then
			if (resurrectingFeatures[featureID].rezFrameCallback) then
				resurrectingFeatures[featureID].rezFrameCallback(featureID)
			else
				local unitID = TurnFeatureIntoUnit(featureID,GaiaTeamID,true,nil)
				SetZombieBehavior(unitID)
			end
		else
			local secondsTillRezCall = floor((rezFrame - f) / 32)
			local rezWarningTime = resurrectingFeatures[featureID].rezWarningTime
			--Spring.Echo("Time left for "..featureID..": "..secondsTillRezCall)
			if secondsTillRezCall <= rezWarningTime then
				local r = Spring.GetFeatureRadius(featureID)
				local x, y, z = Spring.GetFeaturePosition(featureID)
				spSpawnCEG(CEG_SPAWN, x, y, z, 0, 0, 0, 10 + r, 10 + r)

				if secondsTillRezCall == rezWarningTime then
					local z_sound = ZOMBIE_SOUNDS[random(#ZOMBIE_SOUNDS)]
					GG.PlayFogHiddenSound(z_sound, 4, x, y, z)
				end
			end
		end
	end
end

function gadget:Initialize()

	mapWidth = Game.mapSizeX
	mapHeight = Game.mapSizeZ

	GG.Zombies = {
		TurnFeatureIntoUnit     	= TurnFeatureIntoUnit,
		SetZombieSpeedMult      	= SetZombieSpeedMult,
		SetZombieBehavior       	= SetZombieBehavior,
		GetFeatureResurrectData 	= GetFeatureResurrectData,
		GetZombieResurrectData 		= GetZombieResurrectData, -- I want to expose these for modification from outside if desired
		AddFeatureToZombieCountdown	= AddFeatureToZombieCountdown
	}
end