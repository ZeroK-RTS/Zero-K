-- $Id: unitdefs_post.lua 4656 2009-05-23 23:41:24Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modOptions
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utility
--

local function tobool(val)
  local t = type(val)
  if (t == 'nil') then
    return false
  elseif (t == 'boolean') then
    return val
  elseif (t == 'number') then
    return (val ~= 0)
  elseif (t == 'string') then
    return ((val ~= '0') and (val ~= 'false'))
  end
  return false
end


local function disableunits(unitlist)
  for name, ud in pairs(UnitDefs) do
    if (ud.buildoptions) then
      for _, toremovename in ipairs(unitlist) do
        for index, unitname in pairs(ud.buildoptions) do
          if (unitname == toremovename) then
            table.remove(ud.buildoptions, index)
          end
        end
      end
    end
  end
end

--deep not safe with circular tables! defaults To false
function CopyTable(tableToCopy, deep)
  local copy = {}
  for key, value in pairs(tableToCopy) do
    if (deep and type(value) == "table") then
      copy[key] = CopyTable(value, true)
    else
      copy[key] = value
    end
  end
  return copy
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Convert all CustomParams to strings
--

for name, ud in pairs(UnitDefs) do
  if (ud.customparams) then
    for tag,v in pairs(ud.customparams) do
      if (type(v) ~= "string") then
        ud.customparams[tag] = tostring(v)
      end
    end
  end
end 


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Set unit faction and build options
--

local function TagTree(unit, faction, newbuildoptions)
  local morphDefs = VFS.Include"LuaRules/Configs/morph_defs.lua"
  
  local function Tag(unit)
    if (not UnitDefs[unit] or UnitDefs[unit].faction) then
      return
    end
	local ud = UnitDefs[unit]
    ud.faction = faction
    if (UnitDefs[unit].buildoptions) then
	  for _, buildoption in ipairs(ud.buildoptions) do
        Tag(buildoption)
      end
	  if (ud.maxvelocity > 0) and unit ~= "armcsa" and unit ~= "corcsa" then
	    ud.buildoptions = newbuildoptions
	  end
    end
    if (morphDefs[unit]) then
      if (morphDefs[unit].into) then
        Tag(morphDefs[unit].into)
      else
        for _, t in ipairs(morphDefs[unit]) do
          Tag(t.into)
        end
      end        
    end
  end
  
  Tag(unit)
end

local commanders = {
	"armcom",
	"armadvcom",
	"corcom",
	"coradvcom",
	"commrecon",
	"commadvrecon",
	"commsupport",
	"commadvsupport",
}

TagTree("armcom", "arm", UnitDefs["armcom"].buildoptions)
--TagTree("corcom", "core", UnitDefs["corcom"].buildoptions)

for name, ud in pairs(UnitDefs) do
    if ud.faction ~= "thunderbirds" then ud.faction = "arm" end
end 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 3dbuildrange for all none plane builders
--
--[[
for name, ud in pairs(UnitDefs) do
  if (tobool(ud.builder) and not tobool(ud.canfly)) then
    ud.buildrange3d = true
  end
end
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Calculate mincloakdistance based on unit footprint size
--

local sqrt = math.sqrt

for name, ud in pairs(UnitDefs) do
  if (not ud.mincloakdistance) then
    local fx = ud.footprintx and tonumber(ud.footprintx) or 1
    local fz = ud.footprintz and tonumber(ud.footprintz) or 1
    local radius = 8 * sqrt((fx * fx) + (fz * fz))
    ud.mincloakdistance = (radius + 48)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Set reverse velocities
--
for name, ud in pairs(UnitDefs) do
  if ((not ud.tedclass) or ud.tedclass:find("SHIP",1,true) or ud.tedclass:find("TANK",1,true)) then
    if (ud.maxvelocity) then ud.maxreversevelocity = ud.maxvelocity * 0.33 end
  end
end 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Disable smoothmesh
-- 

for name, ud in pairs(UnitDefs) do
    if (ud.canfly) then ud.usesmoothmesh = false end
end 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Special Air
--
--[[
if (modOptions and tobool(modOptions.specialair)) then
  local replacements = VFS.Include("LuaRules/Configs/specialair.lua")
  if (replacements[modOptions.specialair]) then
    replacements = replacements[modOptions.specialair]
    for name, ud in pairs(UnitDefs) do
      if (ud.buildoptions) then
        for buildKey, buildOption in pairs(ud.buildoptions) do
          if (replacements[buildOption]) then
            ud.buildoptions[buildKey] = replacements[buildOption];
          end
        end
      end
    end
  end
end
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Tactics GameMode
--

if (modOptions and (modOptions.camode == "tactics")) then
  -- remove all build options
  Game = { gameSpeed = 30 };  --  required by tactics.lua
  local options = VFS.Include("LuaRules/Configs/tactics.lua")
  local customBuilds = options.customBuilds
  for name, ud in pairs(UnitDefs) do
    if tobool(ud.commander) then
      ud.buildoptions = (customBuilds[name] or {}).allow or {}
    else
      ud.buildoptions = {}
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Metal Bonus
--

if (modOptions and modOptions.metalmult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].extractsmetal
    if (em) then
      UnitDefs[name].extractsmetal = em * modOptions.metalmult
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- OD mex divide by 20
--

for _,ud in pairs(UnitDefs) do
    local em = tonumber(ud.extractsmetal)
    if (em) then
		ud.extractsmetal = em * 0.05
    end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- unitspeedmult
--

if (modOptions and modOptions.unitspeedmult and modOptions.unitspeedmult ~= 1) then
  local unitspeedmult = modOptions.unitspeedmult
  for unitDefID, unitDef in pairs(UnitDefs) do
    if (unitDef.maxvelocity) then unitDef.maxvelocity = unitDef.maxvelocity * unitspeedmult end
    if (unitDef.acceleration) then unitDef.acceleration = unitDef.acceleration * unitspeedmult end
    if (unitDef.brakerate) then unitDef.brakerate = unitDef.brakerate * unitspeedmult end
    if (unitDef.turnrate) then unitDef.turnrate = unitDef.turnrate * unitspeedmult end
  end
end

if (modOptions and modOptions.damagemult and modOptions.damagemult ~= 1) then
  local damagemult = modOptions.damagemult
  for _, unitDef in pairs(UnitDefs) do
    if (unitDef.autoheal) then unitDef.autoheal = unitDef.autoheal * damagemult end
    if (unitDef.idleautoheal) then unitDef.idleautoheal = unitDef.idleautoheal * damagemult end
    
    if (unitDef.capturespeed) 
      then unitDef.capturespeed = unitDef.capturespeed * damagemult
      elseif (unitDef.workertime) then unitDef.capturespeed = unitDef.workertime * damagemult
    end
    
    if (unitDef.repairspeed) 
      then unitDef.repairspeed = unitDef.repairspeed * damagemult
      elseif (unitDef.workertime) then unitDef.repairspeed = unitDef.workertime * damagemult
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Lasercannons going through units fix
-- 

for name, ud in pairs(UnitDefs) do
  ud.collisionVolumeTest = 1
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Commander Types
-- 

if (modOptions and modOptions.commtype) then
  
  if modOptions.commtype == 'default' then
    for name, ud in pairs(UnitDefs) do

      local unitname = ud.unitname
	  
      if (unitname == "armcom" or unitname == "corcom" or unitname == "armdecom" or unitname == "cordecom") then 
		
		ud.candgun = false
		ud.weapons[3] = nil
		
      end
    end

  elseif modOptions.commtype == 'advcomm' then
    for name, ud in pairs(UnitDefs) do
		
      local unitname = ud.unitname
	
			if (unitname == "armcom" or unitname == "corcom") then 
				ud.maxdamage = 3000
				ud.explodeas = "ESTOR_BUILDINGEX"
				ud.selfdestructas = "ESTOR_BUILDINGEX"
				ud.featuredefs.dead.metal = 1000
				ud.featuredefs.dead2.metal = 1000
				ud.featuredefs.dead.reclaimtime = 4000
				ud.featuredefs.dead2.reclaimtime = 4000
				ud.energyMake = 8
				ud.buildCostMetal = 1800
				ud.buildCostEnergy = 1800
				ud.buildTime = 1800
				ud.weapondefs.disintegrator.damage.default = 180
				ud.weapondefs.disintegrator.areaOfEffect = 45
				ud.weapondefs.disintegrator.range = 200
        end
		
      end
    
  elseif modOptions.commtype == 'concomm' then
    for name, ud in pairs(UnitDefs) do

      disableunits({"armdecom", "cordecom" })

      local unitname = ud.unitname
      if (unitname == "armcom" or unitname == "corcom") then 
        ud.cloakcost = nil
        ud.maxdamage = 2000
        ud.canattack = false
        ud.explodeas = "BIG_UNIT"
        ud.weapons = {[1] = nil ,[3] = nil ,[4] = nil ,} 
        ud.candgun = false
        ud.selfdestructas = "BIG_UNIT"
        ud.featuredefs.dead.metal = 800
        ud.featuredefs.dead2.metal = 800
        ud.featuredefs.dead.reclaimtime = 4000
        ud.featuredefs.dead2.reclaimtime = 4000
		if unitname == "armcom" then
			ud.objectname = "armcom_con.3do"
		elseif unitname == "corcom" then
			ud.objectname = "corcom_con.s3o"
		end
		
      end
    end --for

  end


end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Dgun
-- 
--[[
if (modOptions and modOptions.dgun) then
  if tobool(modOptions.dgun) then
    for name, ud in pairs(UnitDefs) do
    local unitname = ud.unitname
      if (unitname == "armcom" or unitname == "corcom") then 
        ud.candgun = true
        ud.weapons[1] = {def = "FAKELASER",} 
        ud.weapons[3] = {def = "DISINTEGRATOR",} 
      end
    end
  else
    for name, ud in pairs(UnitDefs) do
      local unitname = ud.unitname
      if (unitname == "armcom" or unitname == "corcom") then 
        ud.candgun = false
        ud.weapons[3] = nil
      end
    end
  end
end
--]]
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Burrowed
-- 
for name, ud in pairs(UnitDefs) do
  if (ud.weapondefs) then
    for wName,wDef in pairs(ud.weapondefs) do      
      wDef.damage.burrowed = 0.001
    end
  end
end --for


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- SATELLITE FIX (will need script to fix this properly)
-- This adds onlytagetcategory = VTOL HOVER FLOAT SINK to any unit without onlytargetcategory.

for name, ud in pairs(UnitDefs) do
  if (ud.nochasecategory) then
    ud.nochasecategory = ud.nochasecategory .. ' SATELLITE'    
  end

  if (ud.weapons) then
    for _, weapon in ipairs(ud.weapons) do
      if (not weapon.onlytargetcategory) then
    weapon.onlytargetcategory = 'VTOL HOVER FLOAT SINK'    
      end
      if (weapon.badtargetcatory) then
        weapon.badtargetcatory = weapon.badtargetcatory .. ' SATELLITE'
      else
    weapon.badtargetcatory = 'SATELLITE'
      end
    end
  end
end --for

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Concept unit factory mod option
-- 
if modOptions and tobool(modOptions.hiddenunits) then
    for name, ud in pairs(UnitDefs) do
        if tobool(ud.builder) and (ud.buildoptions) and (ud.maxvelocity > 0) then
                table.insert(ud.buildoptions, 1, "concept_factory")
        end
    end --for
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Disable Terraform
-- 

if (modOptions and tobool(modOptions.terraform)) then
  disableunits({"armblock", "corblock", "armtrench", "cortrench", "levelterra", "rampup", "rampdown" })
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--  No leveling ground

--[[
for name, ud in pairs(UnitDefs) do
  if (ud.yardmap)  then
    ud.levelGround = false
  end
end
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- No reclaiming of live units
-- 

--for name, ud in pairs(UnitDefs) do
--  ud.reclaimable = false
--end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Arm cons can capture
-- 
--[[
for name, ud in pairs(UnitDefs) do
  if (not tobool(ud.cancapture) and tobool(ud.builder) and tobool(ud.canmove) and 
      not ud.yardmap and name ~= "armcarry")  then
    ud.cancapture = true
    ud.capturespeed = ud.workertime*2
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Core cons can rez
-- 

for name, ud in pairs(UnitDefs) do
  if (not tobool(ud.canresurrect) and tobool(ud.builder) and tobool(ud.canmove) and
      not ud.yardmap) then
    ud.canresurrect = true
    ud.resurrectspeed = ud.workertime/1.2
  end
end
--]]
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Festive units mod option (CarRepairer's WIP)
-- 

if (modOptions and tobool(modOptions.xmas)) then
  local gifts = {"present_bomb1.s3o","present_bomb2.s3o","present_bomb3.s3o"}

  local function round(num)
    return num-(num%1)
  end

  local function GetRandom(s,c)
    local n = 0
    for i=1,s:len() do
      n = n + s:byte(i)
    end
    n = (math.sin(n)+1)*0.5*(c-1)+1
    return round(n)
  end

  for name, ud in pairs(UnitDefs) do
    local unitname = ud.unitname
    if (unitname == "corclog") then
    --  ud.objectname = "core_christmas_clogger.s3o"
      ud.featuredefs.dead.object = "christmastree_dt.S3O"

    elseif (type(ud.weapondefs) == "table") then
      for wname,wd in pairs(ud.weapondefs) do
        if (wd.weapontype == "AircraftBomb") then
          wd.model = gifts[ GetRandom(wname,#gifts) ]
        end
      end
    end

  end --for
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Special Power plants
-- 
if (modOptions and not tobool(modOptions.specialpower)) then
	for name, ud in pairs(UnitDefs) do
		if name == 'cafus' or name == 'aafus' then
			ud.explodeas 		= "NUCLEAR_MISSILE"
			ud.selfdestructas 	= "NUCLEAR_MISSILE"
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Special Decloak
-- 
if (modOptions and tobool(modOptions.specialdecloak)) then
	for name, ud in pairs(UnitDefs) do
		if not ud.customparams then
			ud.customparams = {}
		end
		ud.customparams.specialdecloakrange = ud.mincloakdistance or 0
		ud.mincloakdistance = 0
		
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Remove Restore
-- 

for name, ud in pairs(UnitDefs) do
  if tobool(ud.builder) then
	ud.canRestore = false
  end
end

-------------------------------------
--- chicken mode
--------------------------------------

if (modOptions and tobool(modOptions.chickens)) then 

	newchickens = {
		chicken = 'newch_chicken',
		chickens = 'newch_spike',
		chickena = 'newch_bigchicken',
		chicken_dodo = 'newch_nugget',
		chicken_pigeon = 'newch_flickensmall',
		chicken_spidermonkey = 'newch_spider2',
		chicken_sporeshooter = 'newch_spiderspikey2',
		chickenc = 'newch_spiderspikey',
		chickenf = 'newch_flickenbig',
		chickenr = 'newch_chubby',
		chickenq = 'newch_queen',
		chicken_leaper = 'newch_leaper',
		chicken_shield = 'newch_shield',
	}
	for name, ud in pairs(UnitDefs) do
		local unitname = ud.unitname
		if newchickens[unitname] then
			ud.objectname = newchickens[ud.unitname] .. '.s3o'
		end
	end
end

-------------------------------------
--- Goliath Gun
--------------------------------------
if (modOptions and tobool(modOptions.golly)) then 
    for name, ud in pairs(UnitDefs) do
	local unitname = ud.unitname
	if (unitname == "corgol") then
	ud.buildCostEnergy = 2500
	ud.buildCostMetal = 2500
	ud.buildTime = 2500
	ud.weapons[1] = ud.weapons[3]
	ud.weapons[3] = nil
	end
    end
else
    for name, ud in pairs(UnitDefs) do
	local unitname = ud.unitname
	if (unitname == "corgol") then
	ud.weapons[3] = nil
	end
    end
end
