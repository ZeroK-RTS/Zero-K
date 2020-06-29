-- $Id: featuredefs_post.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    featuredefs_post.lua
--  brief:   featureDef post processing
--  author:  Dave Rodgers
--  author:  lurker & jK
--
--  Copyright (C) 2008,2009.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Spring.Echo("Loading FeatureDefs_posts")

local function isbool(x)   return (type(x) == 'boolean') end
local function istable(x)  return (type(x) == 'table')   end
local function isnumber(x) return (type(x) == 'number')  end
local function isstring(x) return (type(x) == 'string')  end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local mapMetalMult           = 1
local EMPTY_TABLE            = {}

local mapEnergyMult          = 0.1
local mapEnergyMultThreshold = 60
local energyDefaultBound     = 5
local energyDefault          = 25

-- scale energy/reclaimtime of map's features
for name, fd in pairs(FeatureDefs) do
	if not (fd.customparams or EMPTY_TABLE).mod then
		local metal = (tonumber(fd.metal) or 0)*mapMetalMult
		
		local energy = tonumber(fd.energy) or 0
		if energy > mapEnergyMultThreshold then
			energy = energy * mapEnergyMult
		elseif energy > 0 and energy < energyDefaultBound then
			energy = energyDefault
		end
		
		if metal > 0 or energy > 0 then
			if fd.reclaimable == false then
				-- Geocrack
				energy = 0
				metal = 0
			end
			
			fd.metal = metal
			fd.energy = energy
			
			fd.reclaimtime = math.max(1, energy + metal) -- Income equal to BP split between metal and energy.
		end
		
		fd.customparams = fd.customparams or {}
		fd.customparams.is_tracked_map_feature = 1
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local baseModuleWreck = {
	description		= [[Module Wreck]],
	blocking		= false,
	damage			= 100,
	energy			= 0,
	footprintX		= 2,
	footprintZ		= 2,
	metal			= 40,
	object			= [[wreck1x1.s3o]],
	reclaimable		= true,
	reclaimTime		= 40,
	customparams    = {
		fromunit = 1,
	},
}

local baseModuleHeap = {
	description		= [[Module Debris]],
	blocking		= false,
	damage			= 50,
	energy			= 0,
	footprintX		= 1,
	footprintZ		= 1,
	metal			= 20,
	object			= [[debris1x1b.s3o]],
	reclaimable		= true,
	reclaimTime		= 20,
	customparams    = {
		fromunit = 1,
	},
}

local function GenerateModuleWrecks()
	local moduleDefs = VFS.Include("LuaRules/Configs/dynamic_comm_defs.lua")
	for i = 1, #moduleDefs do
		local moduleDef = moduleDefs[i]
		local wreck = CopyTable(baseModuleWreck, true)
		local heap = CopyTable(baseModuleHeap, true)
		wreck.description = moduleDef.humanName .. " Shards"
		wreck.metal = moduleDef.cost * 0.4
		wreck.reclaimtime = moduleDef.cost * 0.4
		wreck.damage = moduleDef.cost * 2
		wreck.name = "module_wreck_" .. i
		wreck.featuredead = "module_heap_" .. i
		
		FeatureDefs["module_wreck_" .. i] = wreck
		
		heap.description = moduleDef.humanName .. " Fragments"
		heap.metal = moduleDef.cost * 0.2
		heap.reclaimtime = moduleDef.cost * 0.2
		heap.damage = moduleDef.cost * 2
		heap.name = "module_heap_" .. i
		
		FeatureDefs["module_heap_" .. i] = heap
	end
end

GenerateModuleWrecks()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Per-unitDef featureDefs
--

local DEAD_MULT = 0.4
local HEAP_MULT = 0.2

local function ProcessUnitDef(udName, ud)

  local fds = ud.featuredefs
  if (not istable(fds)) then
    return
  end

  -- add this unitDef's featureDefs
  for fdName, fd in pairs(fds) do
    if (isstring(fdName) and istable(fd)) then
      local fullName = udName .. '_' .. fdName
      FeatureDefs[fullName] = fd

      if fd.featuredead then -- it's a DEAD feature
        if not fd.metal then fd.metal = ud.buildcostmetal * DEAD_MULT end
        if not fd.description then fd.description = "Wreckage - "..ud.name end
      else --it's a HEAP feature
        if not fd.metal then fd.metal = ud.buildcostmetal * HEAP_MULT end
        if not fd.description then fd.description = "Debris - "..ud.name end
      end
      
      fd.footprintx = fd.footprintx or ud.footprintx
      fd.footprintz = fd.footprintz or ud.footprintz

      fd.customparams = fd.customparams or {}
      fd.customparams.fromunit = "1"
      fd.damage = fd.customparams.health_override or ud.maxdamage
      fd.energy = 0
      fd.reclaimable = true
      fd.reclaimtime = fd.metal
      fd.filename = ud.filename
    end
  end

  -- FeatureDead name changes
  for fdName, fd in pairs(fds) do
    if (isstring(fdName) and istable(fd)) then
      if (isstring(fd.featuredead)) then
        local fullName = udName .. '_' .. fd.featuredead:lower()
        if (FeatureDefs[fullName]) then
          fd.featuredead = fullName
        end
      end
    end
  end

  -- convert the unit corpse name
  if (isstring(ud.corpse)) then
    local fullName = udName .. '_' .. ud.corpse:lower()
    local fd = FeatureDefs[fullName]
    if (fd) then
      if fd.resurrectable ~= 0 then
        fd.resurrectable = 1
      end
      ud.corpse = fullName
	  --if fd.metal ~= ud.buildcostmetal*0.4 or fd.damage ~= ud.maxdamage then
	  --  Spring.Echo(ud.name)
	  --end
    end
  end

end


--------------------------------------------------------------------------------

-- Process the unitDefs

local UnitDefs = DEFS.unitDefs

for udName, ud in pairs(UnitDefs) do
  if (isstring(udName) and istable(ud)) then
    ProcessUnitDef(udName, ud)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- resurrectable = -1 seems to be broken, set it to 0 for all values which are not 1

for name, def in pairs(FeatureDefs) do
	if def.resurrectable ~= 1 then
		def.resurrectable = 0
	end
	if not def.metal or def.metal == 0 then
		def.metal = 0.001 -- engine deprioritises things with 0m in force-reclaim mode
		def.autoreclaimable = false
	end
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
