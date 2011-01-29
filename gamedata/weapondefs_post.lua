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
    local fullName = udName .. '_' .. ud.explodeas
    if (WeaponDefs[fullName]) then
      ud.explodeas = fullName
    end
  end
  if (isstring(ud.selfdestructas)) then
    local fullName = udName .. '_' .. ud.selfdestructas
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
-- because the way lua access to unitdefs and weapondefs is setup is insane
--
 for _, weaponDef in pairs(WeaponDefs) do
    if weaponDef.mygravity then
		if not weaponDef.customparams then
			weaponDef.customparams = {}
		end
		weaponDef.customparams.mygravity = weaponDef.mygravity -- For attack AOE widget
    end
 end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Fix the canAttack tag
--

do
  local processed = {}

  local RawCanAttack
  local FacCanAttack
  local CanAttack

  RawCanAttack = function(ud)
    if (ud.weapons) then
      for i, weapon in pairs(ud.weapons) do
        local wd = WeaponDefs[weapon.name:lower()]
        if ((not wd.isshield) and 
            (not wd.interceptor)) then
          return true
        end
      end
    end
    if (ud.kamikaze) then
      return not ud.yardmap
    end
    return false
  end

  FacCanAttack = function(ud)
    for _, name in pairs(ud.buildoptions) do
      if (CanAttack(UnitDefs[name:lower()])) then
        return true
      end
    end
    return false
  end

  CanAttack = function(ud)
    if (processed[ud] ~= nil) then
      return processed[ud]
    end
    local canAttack = false
    if (RawCanAttack(ud)) then
      canAttack = true
    elseif (ud.tedclass == 'PLANT') then
      if (FacCanAttack(ud)) then
        canAttack = true
      end
    end
    processed[ud] = canAttack
    return canAttack
  end

  -- loop through the unit defs
  for name, ud in pairs(UnitDefs) do
    ud.canattack = CanAttack(ud)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
