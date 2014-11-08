-- $Id: unitdefs_post.lua 4656 2009-05-23 23:41:24Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modOptions = {}
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end

local reverseCompat = not((Game and true) or false) -- Game is nil in 91.0


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
Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/tablefunctions.lua")
CopyTable = Spring.Utilities.CopyTable
MergeTable = Spring.Utilities.MergeTable


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- ud.customparams IS NEVER NIL

for _, ud in pairs(UnitDefs) do
    if not ud.customparams then
        ud.customparams = {}
    end
 end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- because the way lua access to unitdefs and weapondefs is setup is insane
--

--for _, ud in pairs(UnitDefs) do
--    if ud.collisionVolumeOffsets then
--		ud.customparams.collisionVolumeOffsets = ud.collisionVolumeOffsets  -- For ghost site
--    end
--end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Modular commander/PlanetWars handling
--

VFS.Include('gamedata/modularcomms/unitdefgen.lua')

VFS.Include('gamedata/planetwars/pw_unitdefgen.lua')

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Convert all CustomParams to strings
--

-- FIXME: breaks with table keys
-- but why would you be using those anyway?
local function TableToString(tbl)
    local str = "{"
	for i,v in pairs(tbl) do
	    if type(i) == "number" then
		str = str .. "[" .. i .. "] = "
	    else
		str = str .. [[["]]..i..[["] = ]]
	    end
	    
	    if type(v) == "table" then
		str = str .. TableToString(v)
	    elseif type(v) == "boolean" then
		str = str .. tostring(v) .. ";"
	    elseif type(v) == "string" then
		str = str .. "[[" .. v .. "]];"
	    else
		str = str .. v .. ";"
	    end
	end
    str = str .. "};"
    return str
end

for name, ud in pairs(UnitDefs) do
    if (ud.customparams) then
	for tag,v in pairs(ud.customparams) do
	    if (type(v) == "table") then
		local str = TableToString(v)
		ud.customparams[tag] = str
	    elseif (type(v) ~= "string") then
		ud.customparams[tag] = tostring(v)
	    end
	end
    end
end 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Set units that ignore map-side gadgetted placement resitrctions
-- see http://springrts.com/phpbb/viewtopic.php?f=13&t=27550

for name, ud in pairs(UnitDefs) do
	if (ud.maxvelocity and ud.maxvelocity > 0) or ud.customparams.mobilebuilding then
		ud.customparams.ignoreplacementrestriction = "true"
	end
end

 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Set unit faction and build options
--

local function TagTree(unit, faction, newbuildoptions)
 -- local morphDefs = VFS.Include"LuaRules/Configs/morph_defs.lua"
  
  local function Tag(unit)
    if (not UnitDefs[unit] or UnitDefs[unit].faction) then
      return
    end
	local ud = UnitDefs[unit]
    ud.faction = faction
    if (UnitDefs[unit].buildoptions) and (ud.workertime and ud.workertime > 0) then
	  if ud.maxvelocity and (ud.maxvelocity > 0) and unit ~= "armcsa" then
	    ud.buildoptions = newbuildoptions
	  end	
	  for _, buildoption in ipairs(ud.buildoptions) do
        Tag(buildoption)
      end
    end	
    --if (morphDefs[unit]) then
    --  if (morphDefs[unit].into) then
    --    Tag(morphDefs[unit].into)
    --  else
    --    for _, t in ipairs(morphDefs[unit]) do
    --      Tag(t.into)
    --    end
    --  end        
    --end
  
  end

  Tag(unit)
end

local function ProcessCommBuildOpts()
	local chassisList = {"armcom", "corcom", "commrecon", "commsupport", "cremcom", "benzcom"}
	local commanders = {}
	local numLevels = 5
	
	local buildOpts = VFS.Include("gamedata/buildoptions.lua")
	
    if modOptions and tobool(modOptions.iwinbutton) then
        buildOpts[#buildOpts+1] = 'iwin'
    end
    
	for _, name in pairs(chassisList) do
		for i=1, numLevels do
			commanders[#commanders + 1] = name..i
		end
	end
	
	--add procedural comms
	for name in pairs(commDefs) do
		commanders[#commanders + 1] = name
	end
	
	commanders[#commanders + 1] = "neebcomm"
	commanders[#commanders + 1] = "commbasic"

	for _,name in pairs(commanders) do
		TagTree(name, "arm", buildOpts)
	end
end
ProcessCommBuildOpts()

for name, ud in pairs(UnitDefs) do
	--Spring.Echo(name, ud.faction)
	if not name:find("chicken") then
		ud.faction = "arm"
	else
		ud.faction = "chicken"
	end
end 


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 3dbuildrange for all none plane builders
--

--for name, ud in pairs(UnitDefs) do
--  if (tobool(ud.builder) and not tobool(ud.canfly)) then
--    ud.buildrange3d = true
--  end
--end


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
-- Units with shields cannot cloak
--
--Spring.Echo("Shield Weapon Def")
for name, ud in pairs(UnitDefs) do
	local hasShield = false
	if ud.weapondefs then
		for _, wd in pairs(ud.weapondefs) do      
			if wd.weapontype == "Shield" then
				hasShield = true
				break
			end
		end
	end
	if (hasShield or (((not ud.maxvelocity) or ud.maxvelocity == 0) and not ud.cloakcost)) then
		ud.customparams.cannotcloak = 1
		ud.mincloakdistance = 0
		ud.cloakcost = nil
		ud.cloakcostmoving = nil
		ud.cancloak = false
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Disable smoothmesh; allow use of airpads
-- 

for name, ud in pairs(UnitDefs) do
    if (ud.canfly) then
		ud.usesmoothmesh = false
		if not ud.maxfuel then
			ud.maxfuel = 1000000
			ud.refueltime = ud.refueltime or 1
		end
    end
end 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Use old diving bomber for 91.0

if reverseCompat then
	for i, name in pairs(UnitDefs.factoryplane.buildoptions) do
		if name == "bomberdive" then
			UnitDefs.factoryplane.buildoptions[i] = "corshad"
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Different aircraft turn radius in new engine

if not reverseCompat then
	for name, ud in pairs(UnitDefs) do
		if name == "fighter" then
			ud.turnRadius = 150
			ud.maxRudder = 0.005
		elseif name == "corvamp" then
			ud.turnRadius = 80
			ud.maxRudder = 0.004
		elseif name == "bomberdive" then
			ud.turnRadius = 40
		elseif name == "corhurc2" then
			ud.turnRadius = 20
		elseif name == "armstiletto_laser" then
			ud.turnRadius = 20
		elseif name == "armcybr" then
			ud.turnRadius = 20
		elseif "corawac" then
			ud.turnRadius = 60
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Aircraft Brake Rate is not multiplied by 0.1 in 94.1.1+
-- https://github.com/spring/spring/commit/8009eb548cc62162d9fd15f2914437f4ca63a198

if not reverseCompat then
	for name, ud in pairs(UnitDefs) do
		if (ud.canfly) and not ud.isHoveringAirUnit then
			ud.brakerate = (ud.brakerate or ud.acceleration or 0.5) * 0.8
		end
	end
else
	for name, ud in pairs(UnitDefs) do
		if (ud.canfly) and not (ud.isFighter or ud.isBomber) then
			ud.brakerate = (ud.brakerate or ud.acceleration or 0.5) * 20
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Maneuverablity Buff
-- 

local TURNRATE_MULT = 1
local ACCEL_MULT = 3
local ACCEL_MULT_HIGH = 5

for name, ud in pairs(UnitDefs) do
	if ud.turnrate and ud.acceleration and ud.brakerate and ud.movementclass then
		local class = ud.movementclass
		
		-- https://github.com/spring/spring/commit/8009eb548cc62162d9fd15f2914437f4ca63a198
		if ud.acceleration == ud.brakerate and not reverseCompat then
			ud.brakerate = ud.brakerate * 3
		end
		
		if class:find("TANK") or class:find("BOAT") or class:find("HOVER") then
			ud.turnrate = ud.turnrate * TURNRATE_MULT
			ud.acceleration = ud.acceleration * ACCEL_MULT_HIGH
			ud.brakerate = ud.brakerate * ACCEL_MULT_HIGH*2
		else
			ud.turnrate = ud.turnrate * TURNRATE_MULT
			ud.acceleration = ud.acceleration * ACCEL_MULT
			ud.brakerate = ud.brakerate * ACCEL_MULT*2
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Special Air
--

--if (modOptions and tobool(modOptions.specialair)) then
--  local replacements = VFS.Include("LuaRules/Configs/specialair.lua")
--  if (replacements[modOptions.specialair]) then
--    replacements = replacements[modOptions.specialair]
--    for name, ud in pairs(UnitDefs) do
--      if (ud.buildoptions) then
--        for buildKey, buildOption in pairs(ud.buildoptions) do
--          if (replacements[buildOption]) then
--            ud.buildoptions[buildKey] = replacements[buildOption];
--          end
--        end
--      end
--    end
--  end
--end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Tactics GameMode
--

if (modOptions and (modOptions.zkmode == "tactics")) then
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
-- Energy Bonus, fac cost mult
--


if (modOptions and modOptions.energymult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].energymake
    if (em) then
      UnitDefs[name].energymake = em * modOptions.energymult
    end
	-- for solars
	em = (UnitDefs[name].energyuse and tonumber(UnitDefs[name].energyuse) < 0) and UnitDefs[name].energyuse
	if (em) then
      UnitDefs[name].energyuse = em * modOptions.energymult
    end
  end
end

-- FIXME: doesn't change wreck cost
if (modOptions and modOptions.factorycostmult) then
  for name, def in pairs(UnitDefs) do
    if def.unitname:find("factory") or def.unitname == "armcsa" or def.unitname == "striderhub" then
		def.buildcostmetal = def.buildcostmetal * modOptions.factorycostmult
		def.buildcostenergy = def.buildcostenergy * modOptions.factorycostmult
		def.buildtime = def.buildtime * modOptions.factorycostmult
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
-- Set turnInPlace speed limits, reverse velocities (but not for ships)
--
for name, ud in pairs(UnitDefs) do
	if ud.turnrate and (ud.turnrate > 600 or ud.customparams.turnatfullspeed) then
		ud.turninplace = false
		ud.turninplacespeedlimit = (ud.maxvelocity or 0)
	else
		ud.turninplace = false	-- true
		ud.turninplacespeedlimit = (ud.maxvelocity and ud.maxvelocity*0.6 or 0)
		--ud.turninplaceanglelimit = 180
	end
 

	if ud.category and not (ud.category:find("SHIP",1,true) or ud.category:find("SUB",1,true)) then
		if (ud.maxvelocity) then 
			if not name:find("chicken",1,true) then
				ud.maxreversevelocity = ud.maxvelocity * 0.33 
			end
		end
	end
end 

-- Set to accelerate towards their destination regardless of heading
for name, ud in pairs(UnitDefs) do
	if ud.hoverattack then
		ud.turninplaceanglelimit = 180
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2x repair speed than BP
--

for name, unitDef in pairs(UnitDefs) do
	if (unitDef.repairspeed) then
		unitDef.repairspeed = unitDef.repairspeed * 2
	elseif (unitDef.workertime) then 
		unitDef.repairspeed = unitDef.workertime * 2
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
-- Burrowed
-- 

--for name, ud in pairs(UnitDefs) do
--  if (ud.weapondefs) then
--    for wName,wDef in pairs(ud.weapondefs) do      
--      wDef.damage.burrowed = 0.001
--    end
--  end
--end --for


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Avoid firing at unarmed
-- 
for name, ud in pairs(UnitDefs) do
	if (ud.weapons) then
		for wName,wDef in pairs(ud.weapons) do     
			if wDef.badtargetcategory then
				wDef.badtargetcategory = wDef.badtargetcategory .. " STUPIDTARGET"
			else
				wDef.badtargetcategory = "STUPIDTARGET"
			end
		end
	end
	ud.nochasecategory = (ud.nochasecategory or "") .. " STUPIDTARGET"
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Avoid neutral	-- breaks explicit attack orders
--

--for name, ud in pairs(UnitDefs) do
--  if (ud.weapondefs) then
--    for wName,wDef in pairs(ud.weapondefs) do      
--      wDef.avoidneutral = true
--    end
--  end
--end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Set mass
-- 
for name, ud in pairs(UnitDefs) do
	ud.mass = (((ud.buildtime/2) + (ud.maxdamage/8))^0.6)*6.5
	if ud.customparams.massmult then
		ud.mass = ud.mass*ud.customparams.massmult
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Cost Checking
-- 

--for name, ud in pairs(UnitDefs) do
--	if ud.buildcostmetal ~= ud.buildcostenergy or ud.buildtime ~= ud.buildcostenergy then
--		Spring.Echo("Inconsistent Cost for " .. ud.name)
--	end
--end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Min Build Range back to what it used to be
-- 
for name, ud in pairs(UnitDefs) do
	if ud.builddistance and ud.builddistance < 128 and name ~= "armasp" and name ~= "armcarry" then
		ud.builddistance = 128 
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--  No leveling ground


--for name, ud in pairs(UnitDefs) do
--  if (ud.yardmap)  then
--    ud.levelGround = false
--  end
--end


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
	if (type(ud.weapondefs) == "table") then
      for wname,wd in pairs(ud.weapondefs) do
        if (wd.weapontype == "AircraftBomb" or ( wd.name:lower() ):find("bomb")) and not wname:find("bogus") then
		  --Spring.Echo(wname)
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
	UnitDefs.cafus.explodeas 		= "NUCLEAR_MISSILE"
	UnitDefs.cafus.selfdestructas 	= "NUCLEAR_MISSILE"
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
-- Remove initCloaked because cloak state is no longer used
-- 

for name, ud in pairs(UnitDefs) do
	if tobool(ud.initcloaked) then
		ud.initcloaked = false
		ud.customparams.initcloaked = "1"
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Remove Restore
-- 

for name, ud in pairs(UnitDefs) do
  if tobool(ud.builder) then
	ud.canrestore = false
	--ud.shownanospray = true
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Set chicken cost
-- 

--for name, ud in pairs(UnitDefs) do
--  if (ud.unitname:sub(1,7) == "chicken") then
--	ud.buildcostmetal = ud.buildtime
--	ud.buildcostenergy = ud.buildtime
--  end
--end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Category changes
-- 
for name, ud in pairs(UnitDefs) do
  if ((ud.maxvelocity or 0) > 0) then
	ud.category = ud.category .. " MOBILE"
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Implement modelcenteroffset
--
for name, ud in pairs(UnitDefs) do
    if ud.modelcenteroffset then
		ud.customparams.aimposoffset = ud.modelcenteroffset
		ud.customparams.midposoffset = ud.modelcenteroffset
		ud.modelcenteroffset = "0 0 0"
    end   
end

-- Set default out of combat autorepair
local autoheal_defaults = VFS.Include("gamedata/unitdef_defaults/autoheal_defs.lua")
for name, ud in pairs(UnitDefs) do
	if not ud.autoheal then
		ud.autoheal = autoheal_defaults.autoheal
	end
	if not ud.idletime then
		ud.idletime = autoheal_defaults.idletime
	end
	if not ud.idleautoheal then
		ud.idleautoheal = autoheal_defaults.idleautoheal
	end
end

-- Set defaults for area cloak
local area_cloak_defaults = VFS.Include("gamedata/unitdef_defaults/area_cloak_defs.lua")
for name, ud in pairs(UnitDefs) do
	local cp = ud.customparams
	if cp.area_cloak and (cp.area_cloak ~= "0") then
		if not cp.area_cloak_upkeep then cp.area_cloak_upkeep = tostring(area_cloak_defaults.upkeep) end
		if not cp.area_cloak_radius then cp.area_cloak_radius = tostring(area_cloak_defaults.radius) end

		if not cp.area_cloak_grow_rate then cp.area_cloak_grow_rate = tostring(area_cloak_defaults.grow_rate) end
		if not cp.area_cloak_shrink_rate then cp.area_cloak_shrink_rate = tostring(area_cloak_defaults.shrink_rate) end
		if not cp.area_cloak_decloak_distance then cp.area_cloak_decloak_distance = tostring(area_cloak_defaults.decloak_distance) end

		if not cp.area_cloak_init then cp.area_cloak_init = tostring(area_cloak_defaults.init) end
		if not cp.area_cloak_draw then cp.area_cloak_draw = tostring(area_cloak_defaults.draw) end
		if not cp.area_cloak_self then cp.area_cloak_self = tostring(area_cloak_defaults.self) end
	end
end

-- Set defaults for jump
local jump_defaults = VFS.Include("gamedata/unitdef_defaults/jump_defs.lua")
for name, ud in pairs (UnitDefs) do
	local cp = ud.customparams
	if cp.canjump == "1" then
		if not cp.jump_range then cp.jump_range = tostring(jump_defaults.range) end
		if not cp.jump_height then cp.jump_height = tostring(jump_defaults.height) end
		if not cp.jump_speed then cp.jump_speed = tostring(jump_defaults.speed) end
		if not cp.jump_reload then cp.jump_reload = tostring(jump_defaults.reload) end
		if not cp.jump_delay then cp.jump_delay = tostring(jump_defaults.delay) end

		if not cp.jump_from_midair then cp.jump_from_midair = tostring(jump_defaults.from_midair) end
		if not cp.jump_rotate_midair then cp.jump_rotate_midair = tostring(jump_defaults.rotate_midair) end
		if not cp.jump_spread_exception then cp.jump_spread_exception = tostring(jump_defaults.spread_exception) end
	end
end

-- Disable porc/air/specific units modoptions (see lockunits_modoption.lua)

--[[
local disabledunitsstring = modOptions and modOptions.disabledunits or ""
local disabledunits = { }
local defenceunits = {"corrl", "corllt", "armdeva", "armartic", "armpb", "corhlt", "corrazor", "missiletower", "corflak", "armcir", "screamer", "corgrav", "turrettorp", "cordoom", "armanni", "corjamt" }

--Different lock modoptions are compatible
if modOptions and tobool(modOptions.noair) then
  disabledunits[1]="factoryplane"
  disabledunits[2]="factorygunship"
end

if modOptions and tobool(modOptions.nodef) then
  for i in pairs(defenceunits) do
    table.insert(disabledunits,defenceunits[i])
  end
end

if disabledunitsstring ~= "" then
  for i in string.gmatch(disabledunitsstring, '([^+]+)') do
    disabledunits[#disabledunits+1] = i
  end
end

disableunits(disabledunits)
]]
