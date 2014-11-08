-- $Id: armordefs.lua 4523 2009-05-02 05:11:19Z saktoth $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    armorDefs.lua
--  brief:   armor definitions
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local reverseCompat = not((Game and true) or false) -- Game is nil in 91.0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local armorDefs = {
  
  SUBS = {
    "subarty",
    "subraider",
    "subscout",
    "cornukesub",
  },

  CHICKEN = {
    "nest",
	"chicken_drone",
    "chicken_digger",
    "chicken",
    "chickens",
    "chickenr",
    "chicken_dodo",
    "chickena",
    "chickenc",
    "chicken_spidermonkey",
    "chicken_listener",
	"chickenq",
	"chickent",
	"chicken_sporeshooter",
	"chickenwurm",
	"chicken_leaper",
	"chickenblobber",
	"chicken_shield",
	"chicken_tiamat",
	"chicken_dragon",
  },

  -- populated automatically
  PLANES = {
	"empiricaldpser",
  }, 
  ELSE   = {},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local EMP_DAMAGE_MOD = 1/3
local FLAMER_DAMAGE_MOD = 3
local GAUSS_DAMAGE_MOD = 1.5

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

-- put any unit that doesn't go in any other category in ELSE
for name, ud in pairs(DEFS.unitDefs) do
  local found
  for categoryName, categoryTable in pairs(armorDefs) do
    for _, usedName in pairs(categoryTable) do
      if (usedName == name) then
        found = true
      end
    end
  end
  if (not found) then
    if (tobool(ud.canfly)) then
      table.insert(armorDefs.PLANES, name)
    else
      table.insert(armorDefs.ELSE, name)
    end
  end
end

-- use categories to set default weapon damages
for name, wd in pairs(DEFS.weaponDefs) do
	local weaponNameLower = wd.name:lower()
	local max = -0.000001
	for _, dAmount in pairs(wd.damage) do
		max = math.max(max, dAmount)
	end
	for categoryName, _ in pairs(armorDefs) do
		wd.damage[categoryName] = wd.damage[categoryName] or wd.damage.default
	end
	wd.damage.default = max
  
	-- damage vs shields
	if wd.customparams and wd.customparams.damage_vs_shield then
		wd.damage.default = tonumber(wd.customparams.damage_vs_shield)
	else
		if wd.paralyzer then
			wd.damage.default =  max*EMP_DAMAGE_MOD
			-- add extra damage vs shields for mixed damage units
			if wd.customparams and wd.customparams.extra_damage then
				wd.damage.default = wd.damage.default + tonumber(wd.customparams.extra_damage)
			end
		elseif weaponNameLower:find("flamethrower") or weaponNameLower:find("flame thrower") then
			wd.damage.default =  max*FLAMER_DAMAGE_MOD
			wd.customparams.stats_damage = max
		elseif weaponNameLower:find("gauss") then
			wd.damage.default =  max*GAUSS_DAMAGE_MOD
			wd.customparams.stats_damage = max
		end
	end
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- convert to named maps  (does anyone know what 99 is for?  :)

if reverseCompat then
	for categoryName, categoryTable in pairs(armorDefs) do
		local t = categoryTable
		for _, unitName in pairs(categoryTable) do
			t[unitName] = 99
		end
		armorDefs[categoryName] = t
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local system = VFS.Include('gamedata/system.lua')

return system.lowerkeys(armorDefs)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
