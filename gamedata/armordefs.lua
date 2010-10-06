-- $Id: armordefs.lua 4523 2009-05-02 05:11:19Z saktoth $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    armorDefs.lua
--  brief:   armor definitions
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local armorDefs = {
  
  SUBS = {
    "armsub",
    "corsub",
    "armsubk",
    "corshark",
    "tawf009",
    "corssub",
    "armacsub",
    "coracsub",
    "armrecl",
    "correcl",
	"cornukesub",
  },

  EMPRESISTANT99 = {
    "armtick",
  },
  
  EMPRESISTANT75 = {
    "corcomlite",
    "armcomlite",
    "arm_venom",
    "armartic",
  },

  --automatically populated
  COMMANDERS = {	
    "cordecom",
    "armdecom",
    "chickenflyerqueen",
	"chickenqueenlite",
  },

  BURROWED = {	
    "chicken_digger_b",
	"chicken_listener_b",
	--[[
	"armmine1",
	"armmine2",
	"armmine3",
	"cormine1",
	"cormine2",
	"cormine3",
	--]]
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
  PLANES = {}, 
  ELSE   = {},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


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
	elseif (tobool(ud.commander)) then
	  table.insert(armorDefs.COMMANDERS, name)
    else
      table.insert(armorDefs.ELSE, name)
    end
  end
end

-- use categories to set default weapon damages
for name, wd in pairs(DEFS.weaponDefs) do
  local max = -0.000001
  for _, dAmount in pairs(wd.damage) do
    max = math.max(max, dAmount)
  end
  for categoryName, _ in pairs(armorDefs) do
    wd.damage[categoryName] = wd.damage[categoryName] or wd.damage.default
  end
  wd.damage.default = wd.paralyzer and max/3 or max
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- convert to named maps  (does anyone know what 99 is for?  :)

for categoryName, categoryTable in pairs(armorDefs) do
  local t = {}
  for _, unitName in pairs(categoryTable) do
    t[unitName] = 99
  end
  armorDefs[categoryName] = t
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local system = VFS.Include('gamedata/system.lua')

return system.lowerkeys(armorDefs)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
