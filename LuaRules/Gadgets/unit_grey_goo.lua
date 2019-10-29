function gadget:GetInfo()
  return {
    name      = "Grey Goo",
    desc      = "",
    author    = "Google Frog",
    date      = "Nov 21, 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
   return false
end

local REVERSE_COMPAT = not Spring.Utilities.IsCurrentVersionNewerThan(104, 1120)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local random = math.random

local spGetUnitsInCylinder     = Spring.GetUnitsInCylinder
local spGetFeaturesInRectangle = Spring.GetFeaturesInRectangle
local spGetFeaturePosition     = Spring.GetFeaturePosition
local spGetFeatureResources    = Spring.GetFeatureResources
local spGetUnitPosition        = Spring.GetUnitPosition
local spGetUnitIsStunned       = Spring.GetUnitIsStunned
local spGetUnitTeam            = Spring.GetUnitTeam
local spGetUnitStates          = Spring.GetUnitStates
local spGetUnitDefID           = Spring.GetUnitDefID
local spSetFeatureResources    = Spring.SetFeatureResources
local spDestroyFeature         = Spring.DestroyFeature
local spCreateUnit             = Spring.CreateUnit
local spGiveOrderToUnit        = Spring.GiveOrderToUnit
local spSetUnitRulesParam      = Spring.SetUnitRulesParam
local spGetUnitRulesParam      = Spring.GetUnitRulesParam
local spGetFeatureDefID        = Spring.GetFeatureDefID

local CMD_FIRE_STATE = CMD.FIRE_STATE
local CMD_MOVE_STATE = CMD.MOVE_STATE
local CMD_GUARD      = CMD.GUARD

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UPDATE_FREQUNECY, gooDefs = include("LuaRules/Configs/grey_goo_defs.lua")
local CEG_SPAWN = [[dirt2]];


local units = {}
local unitIndex = {count = 0, info = {}}

local killedFeature = {}

local LOS_ACCESS = {inlos = true}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local validFeatureDefID = {}
for i = 1, #FeatureDefs do
	local fdef = FeatureDefs[i]
	if fdef.customParams and fdef.customParams.fromunit then
		validFeatureDefID[i] = true
	end
	--Spring.Echo(validFeatureDefID[i])
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function disSQ(x1,y1,x2,y2)
	return (x1-x2)^2 + (y1-y2)^2
end

local function getStealableAlly(x, z, r, unitID, progress, team)

	local nearby = spGetUnitsInCylinder(x, z, r, team)

	for i = 1, #nearby do
		local id = nearby[i]
		if units[id] and id ~= unitID and units[id].progress ~= 0 and (units[id].progress < progress or (units[id].progress == progress and unitID < id)) then
			return id
		end
	end

	return false
	
end

local function getClosestWreck(x, z, r) -- hopefully to be replaced
	local features = spGetFeaturesInRectangle(x-r, z-r, x+r, z+r)
	local rsq = r^2
	
	local minDis = false
	local minID = false
	
	for i = 1, #features do
		local fid = features[i]
		local fdefid = spGetFeatureDefID(fid) or 0
		if validFeatureDefID[fdefid] then
			local fx, _, fz = spGetFeaturePosition(fid)
			local dis = disSQ(x,z,fx,fz)
			if dis <= rsq and ((not minDis) or dis < minDis) and (not killedFeature[fid]) then
				local _, maxMetal = spGetFeatureResources(fid)
				if maxMetal ~= 0 then
					minDis = dis
					minID = fid
				end
			end
		end
	end

	return minID
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:GameFrame(f)
	-- putting the localization here because cannot localize in global scope since spring 97
	local spSpawnCEG = Spring.SpawnCEG;

	if f%UPDATE_FREQUNECY == 3 then
		
		local featureMetal = {} -- list of updated feature metal
		
		-- loop through units and gain resources
		for i = 1, unitIndex.count do
		
			local unitID = unitIndex[i]
			local unit = units[unitID]
			local quota = unit.defs.drain * (spGetUnitRulesParam(unitID, "totalBuildPowerChange") or 1)
			local x,y,z = spGetUnitPosition(unitID)
			local stunned_or_inbuild = spGetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID, "disarmed") == 1)
			-- drain metal while quote not fulfilled
			while quota > 0 and (not stunned_or_inbuild) and x and z do
				
				local feature = getClosestWreck(x, z, unit.defs.range)
				
				if feature then
					
					spSpawnCEG( CEG_SPAWN,
					   x,y,z,
					   0,0,0,
					   30, 30
					);
					local metal = featureMetal[feature] or spGetFeatureResources(feature)
					-- The 0.0001 is to safeguard against rounding errors possibly introduced by
					-- the fact that reclaim has a fractional value.
					if metal - 0.0001 > quota then
						unit.progress = unit.progress + quota
						featureMetal[feature] = metal-quota
						quota = 0
					else
						unit.progress = unit.progress + metal
						killedFeature[feature] = true
						featureMetal[feature] = nil
						quota = quota - metal
					end
				else
					if unit.progress ~= 0 then
						local ally = getStealableAlly(x, z, unit.defs.range, unitID, unit.progress, spGetUnitTeam(unitID))
						if ally then
							if units[ally].progress >= quota then
								unit.progress = unit.progress + quota
								units[ally].progress = units[ally].progress-quota
								
							else
								unit.progress = unit.progress + units[ally].progress
								units[ally].progress = 0
							end
						end
					end
					quota = 0
				end
			end
			
		end
		
		-- update feature status
		for id, metal in pairs(featureMetal) do
			local fx, fy, fz = Spring.GetFeaturePosition(id);
			
			fx = fx+math.random(-20,20);
			fz = fz+math.random(-20,20);
			
			spSpawnCEG( CEG_SPAWN,
			   fx,fy,fz,
			   0,0,0,
			   30, 30
			);

			-- NB: if somebody finishes the reclaim of a partially goo'd feature
			-- they will receive the "missing" energy as a chunk (for example if you
			-- drain 80% using goo and then reclaim the remaining 20% manually, you'll
			-- get 20% during the course of that reclaim and then the 80% as a single chunk).
			-- If goo finishes all the metal, the remaining energy is lost.
			-- Currently all gooables have 0 energy worth so this is not a problem,
			-- but a mapper could in theory add that.
			local _, maxMetal, energy = spGetFeatureResources(id)
			spSetFeatureResources(id, metal, energy, nil, metal / maxMetal)
		end
		
		for id, _ in pairs(killedFeature) do
			local fx, fy, fz = Spring.GetFeaturePosition(id);
			
			spSpawnCEG( CEG_SPAWN,
			   fx,fy,fz,
			   0,0,0,
			   30, 30
			);

			spDestroyFeature(id)

			killedFeature[id] = nil
		end
		
		-- check for enough resources to spawn a new unit
		-- this is done outside above loop as spawned units should not instantly eat goo
		for i = 1, unitIndex.count do
			local unit = units[unitIndex[i]]
			if unit.progress >= unit.defs.cost then
				unit.progress = unit.progress - unit.defs.cost
				local x,y,z = spGetUnitPosition(unitIndex[i])
				local newId = spCreateUnit(unit.defs.spawns,x+random(-50,50),y,z+random(-50,50),random(0,3),spGetUnitTeam(unitIndex[i]))
				if newId then
					local firestate, movestate
					if REVERSE_COMPAT then
						local states = spGetUnitStates(unitIndex[i])
						firestate, movestate = states.firestate, states.movestate
					else
						firestate, movestate = spGetUnitStates(unitIndex[i], false)
					end
					
					spGiveOrderToUnit(newId, CMD_FIRE_STATE, {firestate}, 0)
					spGiveOrderToUnit(newId, CMD_MOVE_STATE, {movestate}, 0)
					spGiveOrderToUnit(newId, CMD_GUARD     , {unitIndex[i]}    , 0)

					spSpawnCEG( CEG_SPAWN,
					   x,y,z,
					   0,0,0,
					   30, 30
					);
				end
			end
			if unit.oldProgress ~= unit.progress then
				unit.oldProgress = unit.progress
				spSetUnitRulesParam(unitIndex[i],"gooState",unit.progress/unit.defs.cost, LOS_ACCESS)
			end
		end
	
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	
	if gooDefs[unitDefID] then
		unitIndex.count = unitIndex.count + 1
		unitIndex[unitIndex.count] = unitID
	
		units[unitID] = {
			progress = 0,
			oldProgress = 0,
			index = unitIndex.count,
			defs = gooDefs[unitDefID],
		}
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)

	if gooDefs[unitDefID] then
		unitIndex[units[unitID].index] = unitIndex[unitIndex.count] -- move index from end to index to be deleted
		units[unitIndex[unitIndex.count]].index = units[unitID].index -- update index of unit at end
		unitIndex[unitIndex.count] = nil -- remove index at end
		unitIndex.count = unitIndex.count - 1 -- remove index at end too
		units[unitID] = nil -- remove unit to be deleted
	end

end

function gadget:Initialize()
	Spring.SetGameRulesParam("gooState",1)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = spGetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end
