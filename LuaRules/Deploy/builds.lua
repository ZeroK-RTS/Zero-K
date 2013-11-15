-- $Id: builds.lua 4534 2009-05-04 23:35:06Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    LuaRules/Deploy/builds.lua
--  brief:   deployment game mode build selection
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local options
if (Spring.GetModOption("zkmode")=="tactics") then
  options = VFS.Include("LuaRules/Configs/tactics.lua")
else
  options = VFS.Include("LuaRules/Configs/deployment.lua")
end

local maxLevel = options.maxAutoBuildLevels

local customTable = options.customBuilds


local maxMetal  = options.maxMetal
local maxEnergy = options.maxEnergy

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UnitDefNames = {}
for id,ud in pairs(UnitDefs) do
  UnitDefNames[ud.name] = ud
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Compare(uda, udb, func)
  local a, b = func(uda), func(udb)
  if (type(a) == "boolean") then
    if (a and not b) then return  1; end
    if (not a and b) then return -1; end
  elseif (type(a) == "number") then
    if (a > b) then return  1; end
    if (a < b) then return -1; end
  elseif (type(a) == "string") then
    if (a > b) then return  1; end
    if (a < b) then return -1; end
  end
  return 0
end


local function CompareBuilds(udid1, udid2)
  local a = UnitDefs[udid1]
  local b = UnitDefs[udid2]
  local test

  test = Compare(a, b, function(x) return (x.speed <= 0)    end)
  if (test ~= 0) then return (test > 0) end

  test = Compare(a, b, function(x) return  x.builder        end)
  if (test ~= 0) then return (test > 0) end

  test = Compare(a, b, function(x) return  x.extractsMetal  end)
  if (test ~= 0) then return (test > 0) end

  test = Compare(a, b, function(x) return  x.makesMetal     end)
  if (test ~= 0) then return (test > 0) end

  test = Compare(a, b, function(x) return  x.totalEnergyOut end)
  if (test ~= 0) then return (test > 0) end

  test = Compare(a, b, function(x) return  x.metalStorage   end)
  if (test ~= 0) then return (test > 0) end

  test = Compare(a, b, function(x) return  x.energyStorage  end)
  if (test ~= 0) then return (test > 0) end

  test = Compare(a, b, function(x) return  x.isFeature      end)
  if (test ~= 0) then return (test > 0) end

  test = Compare(a, b, function(x) return -#x.weapons      end)
  if (test ~= 0) then return (test > 0) end

  return (udid1 < udid2)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local buildSet   = {}
local builderSet = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function InsertBuilder(udid, level, baseMetal)
  if (level > maxLevel) then
    return
  end
  local ud = UnitDefs[udid]
  if ((ud == nil) or (not ud.builder)) then
    return
  end
  if (builderSet[udid]) then
    return
  end
  builderSet[udid] = true

  -- insert the builds
  for _, budid in ipairs(ud.buildOptions) do
    local uu = UnitDefs[budid]
    if (uu.metalCost + baseMetal < maxMetal and uu.energyCost < maxEnergy) then 
      buildSet[budid] = true
    end
  end

  -- insert the next level
  local nextLevel = level + 1
  if (nextLevel > maxLevel) then
    return
  end
  for _, budid in ipairs(ud.buildOptions) do
    InsertBuilder(budid, nextLevel, baseMetal + UnitDefs[budid].metalCost)
  end
end


local function SetupBuilds(unitID)

  local udid = Spring.GetUnitDefID(unitID)
  local ud = UnitDefs[udid]

  buildSet   = {}
  builderSet = {}
  InsertBuilder(udid, 1, 0)

  local custom = customTable[ud.name]
  if (custom ~= nil) then
    if (custom.allow ~= nil) then
      for _,name in ipairs(custom.allow) do
        local udbuild = UnitDefNames[name]
        if (udbuild) then
          buildSet[udbuild.id] = true
        end
      end
    end
    if (custom.forbid ~= nil) then
      for _,name in ipairs(custom.forbid) do
        local udbuild = UnitDefNames[name]
        if (udbuild) then
          buildSet[udbuild.id] = nil
        end
      end
    end
  end

  local builds = {}
  for budid in pairs(buildSet) do
    table.insert(builds, budid)
  end

  table.sort(builds, CompareBuilds)

  local buildsMap = {}
  for _,bid in ipairs(builds) do
    buildsMap[bid] = true
  end

  return builds, buildsMap
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return SetupBuilds

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

