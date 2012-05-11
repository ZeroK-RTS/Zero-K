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
local spSetFeatureReclaim      = Spring.SetFeatureReclaim
local spDestroyFeature         = Spring.DestroyFeature
local spCreateUnit             = Spring.CreateUnit
local spGiveOrderToUnit        = Spring.GiveOrderToUnit
local spSetUnitRulesParam      = Spring.SetUnitRulesParam

local CMD_FIRE_STATE = CMD.FIRE_STATE
local CMD_MOVE_STATE = CMD.MOVE_STATE
local CMD_GUARD      = CMD.GUARD

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UPDATE_FREQUNECY, gooDefs = include("LuaRules/Configs/grey_goo_defs.lua")

local units = {}
local unitIndex = {count = 0, info = {}}

local killedFeature = {}

Spring.SetGameRulesParam("gooState",1)

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
		local fx, _, fz = spGetFeaturePosition(features[i])
		local dis = disSQ(x,z,fx,fz)
		if dis <= rsq and ((not minDis) or dis < minDis) and (not killedFeature[features[i]]) then
			local _, maxMetal = spGetFeatureResources(features[i])
			if maxMetal ~= 0 then
				minDis = dis
				minID = features[i]
			end
		end
	end

	return minID
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:GameFrame(f)

	if f%UPDATE_FREQUNECY == 3 then
		
		killedFeature = {} -- list of features that will be killed
		local featureMetal = {} -- list of updated feature metal
		
		-- loop through units and gain resources
		for i = 1, unitIndex.count do
		
			local unitID = unitIndex[i]
			local unit = units[unitID]
			local quota = unit.defs.drain
			local x,_,z = spGetUnitPosition(unitID)
			local stunned_or_inbuild = spGetUnitIsStunned(unitID)
			-- drain metal while quote not fulfilled
			while quota > 0 and not stunned_or_inbuild do
				
				local feature = getClosestWreck(x, z, unit.defs.range)
				
				if feature then
					metal = featureMetal[feature] or spGetFeatureResources(feature)
					if metal >= quota then
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
			local _, maxMetal = spGetFeatureResources(id)
			spSetFeatureReclaim(id, metal/maxMetal)
		end
		
		for id, _ in pairs(killedFeature) do
			spDestroyFeature(id)
		end
		
		-- check for enough resources to spawn a new unit
		-- this is done outside above loop as spawned units should not instantly eat goo
		for i = 1, unitIndex.count do
			local unit = units[unitIndex[i]]
			if unit.progress >= unit.defs.cost then
				unit.progress = unit.progress - unit.defs.cost
				local x,y,z = spGetUnitPosition(unitIndex[i])
				local newId = spCreateUnit(unit.defs.spawns,x+random(-50,50),y,z+random(-50,50),random(2*math.pi),spGetUnitTeam(unitIndex[i]))
				local states = spGetUnitStates(unitIndex[i])
				spGiveOrderToUnit(newId, CMD_FIRE_STATE, {states.firestate}, 0)
				spGiveOrderToUnit(newId, CMD_MOVE_STATE, {states.movestate}, 0)
				spGiveOrderToUnit(newId, CMD_GUARD     , {unitIndex[i]}    , 0)
			end
			if unit.oldProgress ~= unit.progress then
				unit.oldProgress = unit.progress
				spSetUnitRulesParam(unitIndex[i],"gooState",unit.progress/unit.defs.cost, {inlos = true})
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
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = spGetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end
