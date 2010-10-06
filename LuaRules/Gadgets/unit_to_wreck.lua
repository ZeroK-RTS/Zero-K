-- $Id: unit_to_wreck.lua 4238 2009-03-30 06:55:00Z google frog $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false
end

function gadget:GetInfo()
  return {
    name      = "Unit To Wreck",
    desc      = "Adds a button to scrap units to wrecks, and makes dying nanoframes leave wrecks.",
    author    = "quantum",
    date      = "June 28, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--  Proposed Command ID Ranges:
--
--    all negative:  Engine (build commands)
--       0 -   999:  Engine
--    1000 -  9999:  Group AI
--   10000 - 19999:  LuaUI
--   20000 - 29999:  LuaCob
--   30000 - 39999:  LuaRules
--

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local CMDTYPE_ICON          = CMDTYPE.ICON
local spCreateFeature       = Spring.CreateFeature
local spDestroyUnit         = Spring.DestroyUnit
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spGetAllUnits         = Spring.GetAllUnits
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetUnitCmdDescs     = Spring.GetUnitCmdDescs
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitPosition     = Spring.GetUnitPosition
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spRemoveUnitCmdDesc   = Spring.RemoveUnitCmdDesc
local spSetFeatureReclaim   = Spring.SetFeatureReclaim
local spGetUnitHealth       = Spring.GetUnitHealth
local spGetGameFrame        = Spring.GetGameFrame
local spSetFeatureResurrect = Spring.SetFeatureResurrect
local spSetFeatureHealth    = Spring.SetFeatureHealth
local format                = string.format

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local rc = '\255\255\001\001'
local cc = '\255\001\255\255'
local gc = '\255\001\255\001'
local wc = '\255\255\255\255'
local yc = '\255\255\255\001'
        

local cancelStr = 'CANCEL'
local scrapStr  = 'Scrap'
        
local CMD_WRECK = 36734
local position  = 500

local cancelQueue = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetScrapDesc(unitDefID)
  local wreck = UnitDefs[unitDefID].wreckName
  local wreckMetal = FeatureDefNames[wreck].metal
  local metalRatio = wreckMetal/UnitDefs[unitDefID].metalCost*100
  local tooltip = format("Reduce to a %d (%d%%) wreck.", wreckMetal, metalRatio)
  return {
    id = CMD_WRECK,
    name = scrapStr,
    action = scrapStr,
    type = CMDTYPE_ICON,
    tooltip = tooltip,
  }
end


local function IsParalyzed(unitID)
  local health, _, paralyzeDamage = spGetUnitHealth(unitID)
  if (health ~= nil and paralyzeDamage~= nil and health < paralyzeDamage) then
    return true
  end
end


local function IsNanoFrame(unitID)
  local _, _, _, _, buildProgess = spGetUnitHealth(unitID)
  if (buildProgess ~= 1) then
    return true
  end
end


local function ScrapUnit(unitID, todebris)
  local unitDefID = Spring.GetUnitDefID(unitID)
  if (unitDefID) then
    local wreck = UnitDefs[unitDefID].wreckName
    if (wreck and FeatureDefNames[wreck]) then
      local progress = select(5, spGetUnitHealth(unitID))
	  local team = Spring.GetUnitTeam(unitID)
      
      if todebris then
        local nextWreck = FeatureDefNames[wreck].deathFeature
        if nextWreck and FeatureDefNames[nextWreck] then
          wreck = FeatureDefNames[wreck].deathFeature
          if progress < .5 then
            nextWreck = FeatureDefNames[wreck].deathFeature
            if nextWreck and FeatureDefNames[nextWreck] then
              wreck = FeatureDefNames[wreck].deathFeature
              progress = progress * 2
            end
          end
        end
      end
      local x, _, z = spGetUnitPosition(unitID)
      local y = spGetGroundHeight(x, z)
      if (progress == 0) then
        progress = 0.001
      end
      local featureID = spCreateFeature(wreck, x, y, z, _, team)
      local maxHealth = FeatureDefNames[wreck].maxHealth
      spSetFeatureReclaim(featureID, progress)
      spSetFeatureResurrect(featureID, UnitDefs[unitDefID].name) -- FIXME: heading
      spSetFeatureHealth(featureID, progress*maxHealth)
      spDestroyUnit(unitID, false, true)
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
  gadgetHandler:RegisterCMDID(CMD_WRECK)
  for _, unitID in ipairs(spGetAllUnits()) do
    gadget:UnitCreated(unitID, spGetUnitDefID(unitID))
  end
end


function gadget:UnitCreated(unitID, unitDefID)
  local wreck = UnitDefs[unitDefID].wreckName
  if (wreck and FeatureDefNames[wreck]) then
    spInsertUnitCmdDesc(unitID, position, GetScrapDesc(unitDefID))
  end
end


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID)
  local wreck = UnitDefs[unitDefID].wreckName
  if (attackerID and wreck and FeatureDefNames[wreck]) then
    local progress = select(5, spGetUnitHealth(unitID))
    if progress < 1 and progress > .05 then
      ScrapUnit(unitID, true)
    end
  end
end


function gadget:Shutdown()
  for _, unitID in ipairs(spGetAllUnits()) do
    local cmdDescID = spFindUnitCmdDesc(unitID, CMD_WRECK)
    if (cmdDescID) then
      spRemoveUnitCmdDesc(unitID, cmdDescID)
    end
  end
end


function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  if (cancelQueue[unitID]) then
    cancelQueue[unitID] = nil
    spEditUnitCmdDesc(unitID, cmdDescID, GetScrapDesc(unitDefID)) -- FIXME
  end
end


function gadget:GameFrame(frame)
  for unitID, endFrame in pairs(cancelQueue) do
    if IsParalyzed(unitID) then
      cancelQueue[unitID] = endFrame + 1
    end
    local framesLeft = (endFrame - frame)
    if (framesLeft <= 0) then
      ScrapUnit(unitID)
      cancelQueue[unitID] = nil
    else
      local cmdDescID = spFindUnitCmdDesc(unitID, CMD_WRECK)
      if (cmdDescID and ((framesLeft % 15) < 0.5)) then
        local countdownDesc = {}
        if (framesLeft % 30 < 0.5) then
          countdownDesc.name = format(" -%.1f ", framesLeft / 30)
        else
          countdownDesc.name = rc.."CANCEL"
        end
        spEditUnitCmdDesc(unitID, cmdDescID, countdownDesc)
      end
    end
  end
end


function gadget:AllowCommand(unitID, unitDefID, teamID,
                             cmdID, cmdParams, cmdOpts)
  if (cmdID == CMD_WRECK and not IsNanoFrame(unitID)) then
    local cmdDescID = spFindUnitCmdDesc(unitID, CMD_WRECK)
    if (cmdDescID) then
      if (spGetUnitCmdDescs(unitID, cmdDescID)[1].name ~= scrapStr) then
        -- reset the button
        spEditUnitCmdDesc(unitID, cmdDescID, GetScrapDesc(unitDefID))
        cancelQueue[unitID] = nil
      else
        spEditUnitCmdDesc(unitID, cmdDescID, {
          name = cancelStr,
          tooltip = yc..'Left click '..wc..'to '..gc..'cancel '..cc..'Scrap\n'
        })
        local endFrame = spGetGameFrame()+UnitDefs[unitDefID].selfDCountdown*30
        cancelQueue[unitID] = endFrame
      end
      return false -- command was used
    end
  end
  return true  -- command was not used
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------