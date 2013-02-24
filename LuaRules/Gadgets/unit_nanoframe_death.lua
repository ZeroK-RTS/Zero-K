-- $Id: unit_terraform.lua 3299 2008-11-25 07:25:57Z google frog $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Nano Frame Death Handeling",
    desc      = "Makes nanoframes explode if above X% completetion and makes dying nanoframes leave wrecks.",
    author    = "Google Frog",
    date      = "Mar 29, 2009",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = true --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  no unsynced code
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Speedups

local spSetUnitHealth = Spring.SetUnitHealth
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitPosition	= Spring.GetUnitPosition
local spGetUnitBuildFacing  = Spring.GetUnitBuildFacing
local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit
local spGetUnitSelfDTime = Spring.GetUnitSelfDTime


local spSetFeatureResurrect = Spring.SetFeatureResurrect
local spSetFeatureHealth = Spring.SetFeatureHealth
local spSetFeatureReclaim = Spring.SetFeatureReclaim
local spGetGroundHeight = Spring.GetGroundHeight
local spCreateFeature = Spring.CreateFeature

local spValidUnitID = Spring.ValidUnitID

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local units = {}
local unitsCount = 0

local exclude = {
  "armmex",
  "cormex"
}

local excludeDefID = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ScrapUnit(unitID, unitDefID, team, progress, face)
  if (unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].wreckName and FeatureDefNames[UnitDefs[unitDefID].wreckName]) then
    local wreck = FeatureDefNames[UnitDefs[unitDefID].wreckName].id
    if (wreck and FeatureDefs[wreck]) then     
      local nextWreck = FeatureDefs[wreck].deathFeatureID
	  if nextWreck and FeatureDefs[nextWreck] then
        wreck = FeatureDefs[wreck].deathFeatureID
        if progress < 0.5 then
          nextWreck = FeatureDefs[wreck].deathFeatureID
          if nextWreck and FeatureDefs[nextWreck] then
            wreck = FeatureDefs[wreck].deathFeatureID
            progress = progress * 2
          end
        end
      end
      local x, _, z = spGetUnitPosition(unitID)
      local y = spGetGroundHeight(x, z)
      if (progress == 0) then
        progress = 0.001
      end
      local featureID = spCreateFeature(wreck, x, y, z) --  _, team
      local maxHealth = FeatureDefs[wreck].maxHealth
      spSetFeatureReclaim(featureID, progress)
      --spSetFeatureResurrect(featureID, UnitDefs[unitDefID].name, face)
      spSetFeatureHealth(featureID, progress*maxHealth)
    end
  end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)

  local health, _,_,_,progress = spGetUnitHealth(unitID)
  local selfd = spGetUnitSelfDTime(unitID)
  
  if (progress == 1) or ((health > 0) and (selfd == 0)) then
    return
  end

  local face = (spGetUnitBuildFacing(unitID) or 1)

  -- exclude mexes to break recursion with overdrive gadget 
  if (progress > 0.8) then
    if (not excludeDefID[unitDefID]) then
      local x,y,z = spGetUnitPosition(unitID)
      local id = spCreateUnit(unitDefID,x,y,z,face,unitTeam)
      unitsCount = unitsCount+1
      units[unitsCount] = id
    end
    return
  end
  
  if (progress > 0.05) then
    ScrapUnit(unitID, unitDefID, unitTeam, progress, face)
  end
  
end

function gadget:GameFrame(n)
 
  if (unitsCount ~= 0) then
	for i=1, unitsCount do
    if spValidUnitID(units[i]) then
  	  spDestroyUnit(units[i],true,false)
    end
	  units[i] = nil
	end
	unitsCount = 0
	
  end

end

function gadget:Initialize()
  for i,v in ipairs(exclude) do 
    local def = UnitDefNames[v]
    if def then
      excludeDefID[def.id] = true
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
