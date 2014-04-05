local version = "0.1.0"

function gadget:GetInfo()
	return {
		name		= "Zombies!",
		desc		= "Features are dangerous, reclaim them, as fast, as possible! Version "..version,
		author		= "Tom Fyuri",		-- original gadget was mapmod for trololo by banana_Ai, this is revamped version as a zk anymap gamemode
		date		= "Mar 2014",
		license		= "GPL v2 or later",
		layer		= -3,
		enabled	 	= true
	}
end

--SYNCED-------------------------------------------------------------------

--TODO need ambient sfx to tell players something is gonna res... soon...
--TODO maybe slow down res-zombie timer if feature is getting reclaimed?

-- changelog
-- 5 april 2014 - 0.1.0. Release.

local modOptions = Spring.GetModOptions()
if (gadgetHandler:IsSyncedCode()) then

local getMovetype = Spring.Utilities.getMovetype
  
VFS.Include("LuaRules/Configs/CAI/accessory/targetReachableTester.lua")

local spGetGroundHeight			= Spring.GetGroundHeight
local spGetUnitPosition			= Spring.GetUnitPosition
local spGetTeamInfo			= Spring.GetTeamInfo
local spGetFeaturePosition		= Spring.GetFeaturePosition
local spCreateUnit			= Spring.CreateUnit
local spGetUnitDefID			= Spring.GetUnitDefID
local GaiaTeamID			= Spring.GetGaiaTeamID()
local spGetUnitTeam			= Spring.GetUnitTeam
local spGetAllUnits			= Spring.GetAllUnits
local spGetGameFrame			= Spring.GetGameFrame
local spGetAllFeatures			= Spring.GetAllFeatures
local spGiveOrderToUnit			= Spring.GiveOrderToUnit
local spGetCommandQueue			= Spring.GetCommandQueue
local spDestroyFeature			= Spring.DestroyFeature
local spGetFeatureResurrect		= Spring.GetFeatureResurrect
local spGetUnitIsDead	  		= Spring.GetUnitIsDead
local spGiveOrderArrayToUnitArray	= Spring.GiveOrderArrayToUnitArray
local spGetUnitsInCylinder		= Spring.GetUnitsInCylinder

local waterLevel = modOptions.waterlevel and tonumber(modOptions.waterlevel) or 0
local GaiaAllyTeamID					= select(6,spGetTeamInfo(GaiaTeamID))

local random = math.random

local mapWidth
local mapHeight

local zombies_to_spawn = {}
local zombies = {}

local WARNING_TIME = 5; -- seconds to start being scary before actual reanimation event
local ZOMBIES_REZ_MIN = tonumber(modOptions.zombies_delay)
if (tonumber(ZOMBIES_REZ_MIN)==nil) then ZOMBIES_REZ_MIN = 10 end -- minimum of 10 seconds, max is determined by rez speed
local ZOMBIES_REZ_SPEED = tonumber(modOptions.zombies_rezspeed)
if (tonumber(ZOMBIES_REZ_SPEED)==nil) then ZOMBIES_REZ_SPEED = 25 end -- 25m/s, big units have a really long time to respawn

local CMD_REPEAT = CMD.REPEAT
local CMD_MOVE_STATE = CMD.MOVE_STATE
local CMD_INSERT = CMD.INSERT
local CMD_FIGHT = CMD.FIGHT
local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local CMD_GUARD = CMD.GUARD

local CEG_SPAWN = [[zombie]];

local function CheckZombieOrders(unitID)	-- i can't rely on Idle because if for example unit is unloaded it doesnt count as idle... weird
	for unitID, _ in pairs(zombies) do
		local cQueue = spGetCommandQueue(unitID, 1)
		if not(cQueue) or not(#cQueue > 0) then -- oh
			BringingDownTheHeavens(unitID)
		end
	end
end

local function disSQ(x1,y1,x2,y2)
	return (x1 - x2)^2 + (y1 - y2)^2
end

local function GetUnitNearestAlly(unitID, range)
	local best_ally
	local best_dist
	local x,y,z = spGetUnitPosition(unitID)
	local units = spGetUnitsInCylinder(x,z,range)
	for i=1, #units do
		local allyID = units[i]
		local allyTeam = spGetUnitTeam(allyID)
		local allyDefID = spGetUnitDefID(allyID)
		if (allyID ~= unitID) and (allyTeam == GaiaTeamID) and (getMovetype(UnitDefs[allyDefID]) ~= false) then
			local ox,oy,oz = spGetUnitPosition(allyID)
			local dist = disSQ(x,z,ox,oz)
			if IsTargetReallyReachable(unitID, ox, oy, oz, x, y, z) and ((best_dist == nil) or (dist < best_dist)) then
				best_ally = allyID
				best_dist = dist
			end
		end
	end
	return best_ally
end

-- in halloween gadget, sometimes giving order to unit would result in crash because unit happened to be dead at the time order was given
-- TODO probably same units in groups could get same orders...
local function BringingDownTheHeavens(unitID)
	if (spGetUnitIsDead(unitID) == false) then
		local rx,rz,ry
		local orders = {}
		local unitDefID = spGetUnitDefID(unitID)
		local near_ally
		if (UnitDefs[unitDefID].canAttack) then
			near_ally = GetUnitNearestAlly(unitID, 300)
			if (near_ally) then
				local cQueue = spGetCommandQueue(near_ally, 1)
				if cQueue and (#cQueue > 0) and cQueue[1].id == CMD_GUARD then -- oh
					near_ally = nil -- i dont want chain guards...
				end
			end
		end
		local x,y,z = spGetUnitPosition(unitID)
		if (near_ally) and random(0,5)<4 then -- 60% chance to guard nearest ally
			orders[#orders+1] =  { CMD_GUARD, {near_ally}, {} }
		end
		for i=1,random(10,30) do
			rx = random(0,mapWidth)
			rz = random(0,mapHeight)
			ry = spGetGroundHeight(rx,rz)
			if IsTargetReallyReachable(unitID, rx, ry, rz, x, y, z) then
				orders[#orders+1] = { CMD_FIGHT, {rx,ry,rz}, CMD_OPT_SHIFT }
			end
		end
		if (#orders > 0) then
			if (spGetUnitIsDead(unitID) == false) then
				spGiveOrderArrayToUnitArray({unitID},orders)
-- 			else
-- 				zombies[unitID] = nil
			end
		end
-- 	else
-- 		zombies[unitID] = nil
	end
end

function gadget:GameFrame(f)
	if (f%32)==0 then
		local spSpawnCEG = Spring.SpawnCEG -- putting the localization here because cannot localize in global scope since spring 97
		for id, time_to_spawn in pairs(zombies_to_spawn) do
			local x,y,z=spGetFeaturePosition(id)
			
			if time_to_spawn <= f then
				zombies_to_spawn[id] = nil
				local resName,face=spGetFeatureResurrect(id)
				spDestroyFeature(id)
				local unitID=spCreateUnit(resName,x,y,z,face,GaiaTeamID)
				if (unitID) then
					spGiveOrderToUnit(unitID,CMD_REPEAT,{1},{})
					spGiveOrderToUnit(unitID,CMD_MOVE_STATE,{2},{})
					BringingDownTheHeavens(unitID);
					
					local size = UnitDefNames[resName].xsize
					spSpawnCEG("resurrect", x, y, z, 0, 0, 0, size)
					SendToUnsynced("rez_sound", x, y, z);
					zombies[unitID] = true
				end
			else
				local steps_to_spawn = math.floor((time_to_spawn-f) / 32)
				local resName,face=spGetFeatureResurrect(id);
				if steps_to_spawn <= WARNING_TIME then
					local r = Spring.GetFeatureRadius(id);
					
					spSpawnCEG( CEG_SPAWN,
						x,y,z,
						0,0,0,
						10+r, 10+r
					);
					
					if steps_to_spawn == WARNING_TIME then
						SendToUnsynced("zombie_sound", x, y, z);
					end
				end
			end 
		end
	end
	if (f%640)==1 then
		CheckZombieOrders()
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if zombies[unitID] then
		zombies[unitID] = nil
	end
end

function gadget:UnitTaken(unitID, unitDefID, teamID, newTeamID)
	if zombies[unitID] and newTeamID~=GaiaTeamID then
		zombies[unitID] = nil
	elseif newTeamID==GaiaTeamID then
		spGiveOrderToUnit(unitID,CMD_REPEAT,{1},{})
		spGiveOrderToUnit(unitID,CMD_MOVE_STATE,{2},{})
		BringingDownTheHeavens(unitID)
		zombies[unitID] = true
	end
end

function gadget:FeatureCreated(featureID, allyTeam)
	local resName, face = spGetFeatureResurrect(featureID)
	if resName and face then
		if UnitDefNames[resName] then
			local rez_time = UnitDefNames[resName].metalCost / ZOMBIES_REZ_SPEED
			if (rez_time < ZOMBIES_REZ_MIN) then
				  rez_time = ZOMBIES_REZ_MIN
			end
			zombies_to_spawn[featureID] = spGetGameFrame()+(rez_time*32)
		end
	end
end

function gadget:FeatureDestroyed(featureID, allyTeam)
	if (zombies_to_spawn[featureID]) then
		zombies_to_spawn[featureID]=nil
	end
end

local function ReInit(reinit)
	mapWidth = Game.mapSizeX
	mapHeight = Game.mapSizeZ
	if (reinit) then
		local units = spGetAllUnits()
		for i=1,#units do
			local unitID = units[i]
			local unitTeam = spGetUnitTeam(unitID)
			if (unitTeam == GaiaTeamID) then
				spGiveOrderToUnit(unitID,CMD_REPEAT,{1},{})
				spGiveOrderToUnit(unitID,CMD_MOVE_STATE,{2},{})
				BringingDownTheHeavens(unitID)
				zombies[unitID] = true
			end
		end
		local features = spGetAllFeatures()
		for i=1,#features do
			gadget:FeatureCreated(features[i], 1) -- doesnt matter who is owner of feature
		end
	end
end
		
function gadget:Initialize()
	Spring.Echo("Initializing gadget");
	if not (tonumber(modOptions.zombies) == 1) then
		gadgetHandler:RemoveGadget()
		return
	end
	if (spGetGameFrame() > 1) then
		ReInit(true)
	end
end

function gadget:GameStart()
	if (tonumber(modOptions.zombies) == 1) then
		ReInit(false)
	end
end

else -- UNSYNCED
	Spring.Echo("zombies: unsynced mode");
	local spGetLocalAllyTeamID = Spring.GetLocalAllyTeamID
	local spGetSpectatingState = Spring.GetSpectatingState
	local spIsPosInLos         = Spring.IsPosInLos
	local spPlaySoundFile      = Spring.PlaySoundFile
	local ZOMBIE_SOUNDS = {
		"sounds/misc/zombie_1.wav",
		"sounds/misc/zombie_2.wav",
		"sounds/misc/zombie_3.wav",
	}

	local function zombie_sound(_, x, y, z)
		local spec = select(2, spGetSpectatingState())
		local myAllyTeam = spGetLocalAllyTeamID()
		if (spec or spIsPosInLos(x, y, z, myAllyTeam)) then
			local sound = ZOMBIE_SOUNDS[math.random(#ZOMBIE_SOUNDS)]
			spPlaySoundFile(sound, 10, x, y, z);
		end
	end

	function gadget:Initialize()
		gadgetHandler:AddSyncAction("zombie_sound", zombie_sound)
	end

end
