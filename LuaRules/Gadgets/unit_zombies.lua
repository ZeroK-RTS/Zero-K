local version = "0.1.2"

function gadget:GetInfo()
	return {
		name		= "Zombies!",
		desc		= "Features are dangerous, reclaim them, as fast, as possible! Version "..version,
		author		= "Tom Fyuri",		-- original gadget was mapmod for trololo by banana_Ai, this is revamped version as a zk anymap gamemode. Thanks Anarchid!
		date		= "Mar 2014",
		license		= "GPL v2 or later",
		layer		= -3,
		enabled	 	= true
	}
end

--SYNCED-------------------------------------------------------------------

-- changelog
-- 7 april 2014 - 0.1.2. Added permaslow option. Default on. 50% is max slow for now.
-- 5 april 2014 - 0.1.1. Sfx, gfx, factory orders added. Slow down upon reclaim added. Thanks Anarchid.
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
local spSetTeamResource			= Spring.SetTeamResource
local spGetUnitHealth			= Spring.GetUnitHealth

local waterLevel = modOptions.waterlevel and tonumber(modOptions.waterlevel) or 0
local GaiaAllyTeamID					= select(6,spGetTeamInfo(GaiaTeamID))

local gameframe = 0

local random = math.random
local floor = math.floor

local mapWidth
local mapHeight

local reclaimed_data = {} -- holds initial gameframe, initial time in seconds, % of feature reclaimed
local zombies_to_spawn = {}
local zombies = {}

local defined = false -- wordaround, because i meet some kind of racing condition, if any gadget spawns gaia BEFORE this gadget can process all the stuff...

local MexDefs = {
	[UnitDefNames["cormex"].id] = true,
}

local WARNING_TIME = 5; -- seconds to start being scary before actual reanimation event
local ZOMBIES_REZ_MIN = tonumber(modOptions.zombies_delay)
if (tonumber(ZOMBIES_REZ_MIN)==nil) then ZOMBIES_REZ_MIN = 10 end -- minimum of 10 seconds, max is determined by rez speed
local ZOMBIES_REZ_SPEED = tonumber(modOptions.zombies_rezspeed)
if (tonumber(ZOMBIES_REZ_SPEED)==nil) then ZOMBIES_REZ_SPEED = 12 end -- 12m/s, big units have a really long time to respawn
local ZOMBIES_PERMA_SLOW = tonumber(modOptions.zombies_permaslow)
if (tonumber(ZOMBIES_PERMA_SLOW)==nil) then ZOMBIES_PERMA_SLOW = 1 end -- from 0 to 1, symbolises from 0% to 50% slow which is always on
local OREMEX = (tonumber(modOptions.oremex) == 1) -- if its oremex, do not slow down ore extractors, no point

local permaSlowDamage = GG.permaSlowDamage
local addSlowDamage = GG.addSlowDamage

local CMD_REPEAT = CMD.REPEAT
local CMD_MOVE_STATE = CMD.MOVE_STATE
local CMD_INSERT = CMD.INSERT
local CMD_FIGHT = CMD.FIGHT
local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local CMD_GUARD = CMD.GUARD

local CEG_SPAWN = [[zombie]];

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

local function OpenAllClownSlots(unitID, unitDefID) -- give factory something to do
	local buildopts = UnitDefs[unitDefID].buildOptions
	local orders = {}
	--local x,y,z = spGetUnitPosition(unitID)
	for i=1,random(10,30) do
		orders[#orders+1] = { -buildopts[random(1,#buildopts)], {}, {} }
	end
	if (#orders > 0) then
		if (spGetUnitIsDead(unitID) == false) then
			spGiveOrderArrayToUnitArray({unitID},orders)
		end
	end
end

-- reclaiming zombies 'causes delay in rez, basically you have to have about ZOMBIES_REZ_SPEED/2 or bigger BP to reclaim faster than it resurrects...
-- TODO do more math to figure out how to perform it better?
function gadget:AllowFeatureBuildStep(builderID, builderTeam, featureID, featureDefID, part)
	if (zombies_to_spawn[featureID]) then
		local base_time = reclaimed_data[featureID]
		base_time[3] = base_time[3]-part
		zombies_to_spawn[featureID] = base_time[1] + base_time[2] * (1+base_time[3]) * 32
	end
	return true
end

-- in halloween gadget, sometimes giving order to unit would result in crash because unit happened to be dead at the time order was given
-- TODO probably same units in groups could get same orders...
local function BringingDownTheHeavens(unitID)
	if (spGetUnitIsDead(unitID) == false) then
		local unitDefID = spGetUnitDefID(unitID)
-- 		if (getMovetype(UnitDefs[unitDefID]) ~= false) then
		local rx,rz,ry
		local orders = {}
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
			end
		end
		if (UnitDefs[unitDefID].isFactory) then
			OpenAllClownSlots(unitID, unitDefID) -- give factory something to do
			zombies[unitID] = nil -- no need to update factory orders anymore
		end
	end
end

local function CheckZombieOrders(unitID)	-- i can't rely on Idle because if for example unit is unloaded it doesnt count as idle... weird
	for unitID, _ in pairs(zombies) do
		local cQueue = spGetCommandQueue(unitID, 1)
		if not(cQueue) or not(#cQueue > 0) then -- oh
			BringingDownTheHeavens(unitID)
		end
	end
end

function gadget:GameFrame(f)
	gameframe = f
	if (f%32)==0 then
		local spSpawnCEG = Spring.SpawnCEG -- putting the localization here because cannot localize in global scope since spring 97
		for id, time_to_spawn in pairs(zombies_to_spawn) do
			local x,y,z=spGetFeaturePosition(id)
			
			if time_to_spawn <= f then
				zombies_to_spawn[id] = nil
				local resName,face=spGetFeatureResurrect(id)
				spDestroyFeature(id)
				local unitID = spCreateUnit(resName,x,y,z,face,GaiaTeamID)
				if (unitID) then
					local size = UnitDefNames[resName].xsize
					spSpawnCEG("resurrect", x, y, z, 0, 0, 0, size)
					SendToUnsynced("rez_sound", x, y, z);
				end
			else
				local steps_to_spawn = floor((time_to_spawn-f) / 32)
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
	if (f==1) then
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
	if zombies[unitID] and newTeamID~=GaiaTeamID then
		zombies[unitID] = nil
		-- taking away zombie from zombie team unpermaslows it
		if (ZOMBIES_PERMA_SLOW > 0) then
			permaSlowDamage(unitID, false)
		end
	elseif newTeamID==GaiaTeamID then
		gadget:UnitFinished(unitID, unitDefID, newTeamID)
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	gadget:UnitFinished(unitID, unitDefID, teamID)
end

local UnitFinished = function(_,_,_) end
  
function gadget:UnitFinished(unitID, unitDefID, teamID)
	UnitFinished(unitID, unitDefID, teamID)
end

function gadget:FeatureCreated(featureID, allyTeam)
	local resName, face = spGetFeatureResurrect(featureID)
	if resName and face and not(zombies_to_spawn[featureID]) then
		if UnitDefNames[resName] then
			local rez_time = UnitDefNames[resName].metalCost / ZOMBIES_REZ_SPEED
			if (rez_time < ZOMBIES_REZ_MIN) then
				  rez_time = ZOMBIES_REZ_MIN
			end
			reclaimed_data[featureID] = {gameframe,rez_time,0}
			zombies_to_spawn[featureID] = gameframe+(rez_time*32)
		end
	end
end

function gadget:FeatureDestroyed(featureID, allyTeam)
	if (zombies_to_spawn[featureID]) then
		zombies_to_spawn[featureID]=nil
		reclaimed_data[featureID]=nil
	end
end

local function ReInit(reinit)
	mapWidth = Game.mapSizeX
	mapHeight = Game.mapSizeZ
	if not(defined) then
		UnitFinished = function(unitID, unitDefID, teamID, builderID)
			if (teamID == GaiaTeamID) and not(zombies[unitID]) then
				spGiveOrderToUnit(unitID,CMD_REPEAT,{1},{})
				spGiveOrderToUnit(unitID,CMD_MOVE_STATE,{2},{})
				BringingDownTheHeavens(unitID)
				zombies[unitID] = true
				if (ZOMBIES_PERMA_SLOW > 0) then
					if not(OREMEX and MexDefs[unitDefID]) then
						local maxHealth = select(2, spGetUnitHealth(unitID))
						if maxHealth then
							local mult = ZOMBIES_PERMA_SLOW
							if (mult < 0) then mult = 0 end
							addSlowDamage(unitID,(maxHealth/2)*mult)
							permaSlowDamage(unitID, true)
						end
					end
				end
			end
		end
		defined = true
	end
	if (reinit) then
		gameframe = spGetGameFrame()
		local units = spGetAllUnits()
		for i=1,#units do
			local unitID = units[i]
			local unitTeam = spGetUnitTeam(unitID)
			if (unitTeam == GaiaTeamID) then
				gadget:UnitFinished(unitID, spGetUnitDefID(unitID), unitTeam)
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
-- 	if (tonumber(modOptions.zombies) == 1) then
		ReInit(true) -- anything it does doesnt mess with existing zombies
-- 	end
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
