-- $Id: weapondefs_post.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    weapondefs_post.lua
--  brief:   weaponDef post processing
--  author:  Dave Rodgers
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Spring.Echo("Loading WeaponDefs_posts")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Dynamic Comms
--

VFS.Include('gamedata/modularcomms/weapondefgen.lua')

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Per-unitDef weaponDefs
--

local function isbool(x)   return (type(x) == 'boolean') end
local function istable(x)  return (type(x) == 'table')   end
local function isnumber(x) return (type(x) == 'number')  end
local function isstring(x) return (type(x) == 'string')  end


--------------------------------------------------------------------------------

local function ProcessUnitDef(udName, ud)

  local wds = ud.weapondefs
  if (not istable(wds)) then
    return
  end

  -- add this unitDef's weaponDefs
  for wdName, wd in pairs(wds) do
    if (isstring(wdName) and istable(wd)) then
      local fullName = udName .. '_' .. wdName
      WeaponDefs[fullName] = wd
      wd.filename = ud.filename
    end
  end

  -- convert the weapon names
  local weapons = ud.weapons
  if (istable(weapons)) then
    for i = 1, 16 do
      local w = weapons[i]
      if (istable(w)) then
        if (isstring(w.def)) then
          local ldef = string.lower(w.def)
          local fullName = udName .. '_' .. ldef
          local wd = WeaponDefs[fullName]
          if (istable(wd)) then
            w.name = fullName
          end
        end
        w.def = nil
      end
    end
  end
  
  -- convert the death explosions
  if (isstring(ud.explodeas)) then
    local fullName = udName .. '_' .. string.lower(ud.explodeas)
    if (WeaponDefs[fullName]) then
      ud.explodeas = fullName
    end
  end
  if (isstring(ud.selfdestructas)) then
    local fullName = udName .. '_' .. string.lower(ud.selfdestructas)
    if (WeaponDefs[fullName]) then
      ud.selfdestructas = fullName
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
--
-- customParams is never nil

for _, weaponDef in pairs(WeaponDefs) do
	weaponDef.customparams = weaponDef.customparams or {}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Apply remaim_time

for name, weaponDef in pairs(WeaponDefs) do
	if not (weaponDef.customparams.reaim_time or string.find(name, "chicken")) then
		weaponDef.customparams.reaim_time = 5
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Set shield starting power to 100%

for name, weaponDef in pairs(WeaponDefs) do
	if weaponDef.shieldpower and (weaponDef.shieldpower < 2000) then
		weaponDef.shieldstartingpower = weaponDef.shieldpower
		weaponDef.customparams.shieldstartingpower = weaponDef.shieldstartingpower
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Set lenient fire tolerance

for _, weaponDef in pairs(WeaponDefs) do
	if not weaponDef.firetolerance then
		weaponDef.firetolerance = 32768 -- Full 180 degrees on either side.
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Preserve crater sizes for new engine
-- https://github.com/spring/spring/commit/77c8378b04907417a62c25218d69ff323ba74c8d

for _, weaponDef in pairs(WeaponDefs) do
	if (not weaponDef.craterareaofeffect) then
		weaponDef.craterareaofeffect = tonumber(weaponDef.areaofeffect or 0) * 1.5
	end
end

-- New engine seems to have covertly increased the effect of cratermult
for _, weaponDef in pairs(WeaponDefs) do
	weaponDef.cratermult = (weaponDef.cratermult or 1) * 0.3
end

-- https://github.com/spring/spring/commit/dd7d1f79c3a9b579f874c210eb4c2a8ae7b72a16
for _, weaponDef in pairs(WeaponDefs) do
	if ((weaponDef.weapontype == "LightningCannon") and (not weaponDef.beamttl)) then
		weaponDef.beamttl = 10
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Disable sweepfire until we know how to use it

for _, weaponDef in pairs(WeaponDefs) do
	weaponDef.sweepfire = false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Disable burnblow for LaserCannons because overshoot is not a problem for any
-- of them and is important for some.

for _, weaponDef in pairs(WeaponDefs) do
	if weaponDef.weapontype == "LaserCannon" then
		weaponDef.burnblow = false
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modOptions
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end

if (modOptions and modOptions.damagemult and modOptions.damagemult ~= 1) then
  local damagemult = modOptions.damagemult
  for _, weaponDef in pairs(WeaponDefs) do
    if (weaponDef.damage and weaponDef.name and not string.find(weaponDef.name, "Disintegrator")) then
      for damagetype, amount in pairs(weaponDef.damage) do
        weaponDef.damage[damagetype] = amount * damagemult
      end
    end
  end
end

if (modOptions and modOptions.cratermult and modOptions.cratermult ~= 1) then
  local cratermult = modOptions.cratermult
  for _, weaponDef in pairs(WeaponDefs) do
    if weaponDef.cratermult then
      weaponDef.cratermult = weaponDef.cratermult * cratermult
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Set myGravity for Cannons because maps cannot be trusted. Standard is 120,
-- gravity of 150 can cause high things (such as HLT) to be unhittable.

 for _, weaponDef in pairs(WeaponDefs) do
	if weaponDef.weapontype == "Cannon" and not weaponDef.mygravity then
		weaponDef.mygravity = 2/15 -- 120/(GAME_SPEED^2)
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- because the way lua access to unitdefs and weapondefs is setup is insane
--
 for _, weaponDef in pairs(WeaponDefs) do
    if not weaponDef.customparams then
		weaponDef.customparams = {}
	end
	if weaponDef.mygravity then
		weaponDef.customparams.mygravity = weaponDef.mygravity -- For attack AOE widget
    end
	if weaponDef.flighttime then
		weaponDef.customparams.flighttime = weaponDef.flighttime
    end
	if weaponDef.weapontimer then
		weaponDef.customparams.weapontimer = weaponDef.weapontimer
    end
	if weaponDef.weaponvelocity then
		weaponDef.customparams.weaponvelocity = weaponDef.weaponvelocity -- For attack AOE widget
	end
	if weaponDef.dyndamageexp and (weaponDef.dyndamageexp > 0) then
		weaponDef.customparams.dyndamageexp = weaponDef.dyndamageexp
	end
	if weaponDef.flighttime and (weaponDef.flighttime > 0) then
		weaponDef.customparams.flighttime = weaponDef.flighttime
	end
 end

 for _, weaponDef in pairs(WeaponDefs) do
	local name = weaponDef.name
	if name:find('fake') or name:find('Fake') or name:find('Bogus') or name:find('NoWeapon') then
		weaponDef.customparams.fake_weapon = 1
	end
 end
-- Set defaults for napalm (area damage)
local area_damage_defaults = VFS.Include("gamedata/unitdef_defaults/area_damage_defs.lua")
for name, wd in pairs (WeaponDefs) do
	local cp = wd.customparams
	if cp.area_damage then
		if not cp.area_damage_dps then cp.area_damage_dps = area_damage_defaults.dps end
		if not cp.area_damage_radius then cp.area_damage_radius = area_damage_defaults.radius end
		if not cp.area_damage_duration then cp.area_damage_duration = area_damage_defaults.duration end

		if not cp.area_damage_is_impulse then cp.area_damage_is_impulse = area_damage_defaults.is_impulse end
		if not cp.area_damage_range_falloff then cp.area_damage_range_falloff = area_damage_defaults.range_falloff end
		if not cp.area_damage_time_falloff then cp.area_damage_time_falloff = area_damage_defaults.time_falloff end
	end
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- default noSelfDamage
--
 for _, weaponDef in pairs(WeaponDefs) do
    weaponDef.noselfdamage = (weaponDef.noselfdamage ~= false)
 end
 
-- remove experience bonuses
for _, weaponDef in pairs(WeaponDefs) do
	weaponDef.ownerExpAccWeight = 0
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Workaround for http://springrts.com/mantis/view.php?id=4104
--

 for _, weaponDef in pairs(WeaponDefs) do
    if weaponDef.texture1 == "largelaserdark" then
		weaponDef.texture1 = "largelaserdark_long"
		weaponDef.tilelength = (weaponDef.tilelength and weaponDef.tilelength*4) or 800
	end
	if weaponDef.texture1 == "largelaser" then
		weaponDef.texture1 = "largelaser_long"
		weaponDef.tilelength = (weaponDef.tilelength and weaponDef.tilelength*4) or 800
	end
 end
 
 --------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Take over the handling of shield energy drain from the engine.

for _, weaponDef in pairs(WeaponDefs) do
	if weaponDef.shieldpowerregenenergy and weaponDef.shieldpowerregenenergy > 0 then
		weaponDef.customparams = weaponDef.customparams or {}
		
		weaponDef.customparams.shield_rate = weaponDef.shieldpowerregen
		weaponDef.customparams.shield_drain = weaponDef.shieldpowerregenenergy
		
		weaponDef.shieldpowerregen = 0
		weaponDef.shieldpowerregenenergy = 0
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Set hardStop for defered lighting and to reduce projectile count

 for _, weaponDef in pairs(WeaponDefs) do
	if weaponDef.weapontype == "LaserCannon" and weaponDef.hardstop == nil then
		weaponDef.hardstop = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Reduce rounding error in damage

for _, weaponDef in pairs(WeaponDefs) do
	if weaponDef.impactonly then
		weaponDef.edgeeffectiveness = 1
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- ???

for _, weaponDef in pairs(WeaponDefs) do
	if weaponDef.paralyzetime and not weaponDef.paralyzer then
		weaponDef.customparams.extra_paratime = weaponDef.paralyzetime
	end
	if not weaponDef.predictboost then
		weaponDef.predictboost = 1
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Fix the canAttack tag
--

do
	local function RawCanAttack (ud)
		if (ud.weapons) then
			for i, weapon in pairs(ud.weapons) do
				local wd = WeaponDefs[weapon.name:lower()]
				if wd.weapontype ~= "Shield" and not wd.interceptor then
					return true
				end
			end
		end
		if (ud.kamikaze) then
			return not ud.yardmap
		end
		return false
	end

	local function CanAttack (ud)
		local isFac = ud.yardmap and ud.buildoptions
		if isFac or RawCanAttack(ud) then
			return true
		end
		return false
	end

	for name, ud in pairs(UnitDefs) do
		if not ud.canattack then
			ud.canattack = CanAttack(ud)
		end
	end
end
