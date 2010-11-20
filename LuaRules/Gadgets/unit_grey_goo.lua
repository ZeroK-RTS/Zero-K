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

local CMD_GUARD = CMD.GUARD


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UPDATE_FREQUNECY, gooDefs = include("LuaRules/Configs/grey_goo_defs.lua")

local units = {}
local unitIndex = {count = 0, info = {}}

local killedFeature = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function disSQ(x1,y1,x2,y2)
	return (x1-x2)^2 + (y1-y2)^2
end

local function getClosestWreck(x, z, r) -- hopefully to be replaced

	local features = Spring.GetFeaturesInRectangle(x-r, z-r, x+r, z+r)
	local rsq = r^2
	
	local minDis = false
	local minID = false
	
	for i = 1, #features do
		local fx, _, fz = Spring.GetFeaturePosition(features[i])
		local dis = disSQ(x,z,fx,fz)
		if dis <= rsq and ((not minDis) or dis < minDis) and (not killedFeature[features[i]]) then
			local _, maxMetal = Spring.GetFeatureResources(features[i])
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
		
		killedFeature = {}
		local featureMetal = {}
		
		for i = 1, unitIndex.count do
		
			local unit = units[unitIndex[i]]
			local quota = unit.defs.drain
			
			local x,_,z = Spring.GetUnitPosition(unitIndex[i])
			
			while quota > 0 do
				
				local feature = getClosestWreck(x, z, unit.defs.range)
				
				if feature then
					local metal, maxMetal = Spring.GetFeatureResources(feature)
					metal = featureMetal[feature] or metal
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
					quota = 0
				end
				
			end
			
		end
		
		for id, metal in pairs(featureMetal) do
			local _, maxMetal = Spring.GetFeatureResources(id)
			Spring.SetFeatureReclaim(id, metal/maxMetal)
		end
		
		for id, _ in pairs(killedFeature) do
			Spring.DestroyFeature(id)
		end
		
		for i = 1, unitIndex.count do
			local unit = units[unitIndex[i]]
			if unit.progress >= unit.defs.cost then
				unit.progress = unit.progress - unit.defs.cost
				local x,y,z = Spring.GetUnitPosition(unitIndex[i])
				local newId = Spring.CreateUnit(unit.defs.spawns,x+math.random(-50,50),y,z+math.random(-50,50),math.random(2*math.pi),Spring.GetUnitTeam(unitIndex[i]))
				Spring.GiveOrderToUnit(newId, CMD_GUARD, {unitIndex[i]}, {})
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
			index = unitIndex.count,
			defs = gooDefs[unitDefID],
		}
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)

	if gooDefs[unitDefID] then
		unitIndex[units[unitID].index] = unitIndex[unitIndex.count]
		units[unitIndex[units[unitID].index]].index = unitIndex[units[unitID].index]
		
		unitIndex.count = unitIndex.count - 1
		unitIndex[unitIndex.count] = nil
		units[unitID] = nil
	end

end

function gadget:Initialize()
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end
