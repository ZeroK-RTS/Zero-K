
Spring.Echo("Loading ArmorDefs_posts")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local armorDefs = {
  
  SUBS = {
    "subraider",
    "subscout",
    "subtacmissile",
  },

  CHICKEN = {
    "nest",
	"chicken_drone",
    "chicken_digger",
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
  SHIELD = {},
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
    else
      table.insert(armorDefs.ELSE, name)
    end
  end
end

-- damage to shields modifiers
local EMP_DAMAGE_MOD = 1/3
local SLOW_DAMAGE_MOD = 1/3
local DISARM_DAMAGE_MOD = 1/3
local FLAMER_DAMAGE_MOD = 3
local GAUSS_DAMAGE_MOD = 1.5

-- Set shields to use their own armor type
for name, wd in pairs(DEFS.weaponDefs) do
	if wd.weapontype == "Shield" then
		wd.shieldarmortype = "SHIELD"
	end
end

-- use categories to set shield and feature damage. Feature damage uses the default armor class
for name, wd in pairs(DEFS.weaponDefs) do
	local weaponNameLower = wd.name:lower()
	local maxDamage = -0.000001
	for _, dAmount in pairs(wd.damage) do
		maxDamage = math.max(maxDamage, dAmount)
	end
	for categoryName, _ in pairs(armorDefs) do
		wd.damage[categoryName] = wd.damage[categoryName] or wd.damage.default
	end
	wd.damage.default = maxDamage
	wd.damage.shield = maxDamage

	-- Stats
	wd.customparams.stats_damage = wd.customparams.stats_damage or maxDamage
	
	-- raw_damage is damage per frame. shot_damage is full damage per reload.
	wd.customparams.raw_damage = maxDamage/((wd.customparams.effective_beam_time or wd.beamtime or 1/30) * 30)
	wd.customparams.shot_damage = maxDamage*(wd.projectiles or 1)*(wd.burst or 1)

	-- damage vs shields
	if wd.customparams and wd.customparams.damage_vs_shield then
		wd.damage.shield = tonumber(wd.customparams.damage_vs_shield)
	else
		local cp = wd.customparams or {}

		if wd.paralyzer then
			wd.damage.shield = maxDamage * EMP_DAMAGE_MOD
		end

		-- add extra damage vs shields for mixed EMP damage units
		if cp.extra_damage then
			wd.damage.shield = wd.damage.shield + tonumber(cp.extra_damage) * EMP_DAMAGE_MOD
		end

		if (cp.timeslow_damagefactor) then
			if (tobool(cp.timeslow_onlyslow)) then
				wd.damage.shield = 0
			end
			wd.damage.shield = wd.damage.shield + (tonumber(wd.customparams.timeslow_damagefactor) * maxDamage * SLOW_DAMAGE_MOD)
		end

		if (cp.disarmdamagemult) then
			if (tobool(cp.disarmdamageonly)) then
				wd.damage.shield = 0
			end
			wd.damage.shield = wd.damage.shield + (tonumber(wd.customparams.disarmdamagemult) * maxDamage * DISARM_DAMAGE_MOD)
		end

		-- weapon type bonuses
		if weaponNameLower:find("flamethrower") or weaponNameLower:find("flame thrower") then
			wd.damage.shield = wd.damage.shield * FLAMER_DAMAGE_MOD
		elseif weaponNameLower:find("gauss") then
			wd.damage.shield = wd.damage.shield * GAUSS_DAMAGE_MOD
		end
	end
	wd.customparams.shield_damage = wd.damage.shield/((wd.customparams.effective_beam_time or wd.beamtime or 1/30) * 30)
	wd.customparams.stats_shield_damage = wd.damage.shield
	if wd.beamtime and wd.beamtime >= 0.1 then
		-- Settings damage default to 0 removes cratering and impulse so is not universally applied.
		-- It fixes long beams vs shield cases.
		wd.damage.shield = 0
	end
	
	-- damage vs features
	if wd.customparams and wd.customparams.damage_vs_feature then
		wd.damage.default = tonumber(wd.customparams.damage_vs_feature)
	else
		local cp = wd.customparams or {}

		if wd.paralyzer then
			-- paralyzer is hardcoded in Spring to deal no wreck damage so this handling does nothing.
			wd.damage.default = 0.001 -- Settings damage default to 0 removes cratering and impulse
		end

		if (cp.timeslow_damagefactor) and (tobool(cp.timeslow_onlyslow)) then
			wd.damage.default = 0.001 -- Settings damage default to 0 removes cratering and impulse
		end

		if (cp.disarmdamagemult) and (tobool(cp.disarmdamageonly)) then
			wd.damage.default = 0.001 -- Settings damage default to 0 removes cratering and impulse
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ProcessSoundDefaults(wd)
	local forceSetVolume = (not wd.soundstartvolume) or (not wd.soundhitvolume)

	if not forceSetVolume then
		return
	end

	local defaultDamage = wd.damage and wd.damage.default
	if (not defaultDamage) or (defaultDamage <= 50) then
		wd.soundstartvolume = 5
		wd.soundhitvolume = 5
		return
	end

	local soundVolume = math.sqrt(defaultDamage * 0.5)
	if wd.weapontype == "LaserCannon" then
		soundVolume = soundVolume*0.5
	end

	if (not wd.soundstartvolume) then
		wd.soundstartvolume = soundVolume
	end
	if (not wd.soundhitvolume) then
		wd.soundhitvolume = soundVolume
	end
end

for name, wd in pairs(DEFS.weaponDefs) do
	ProcessSoundDefaults(wd)
end

local system = VFS.Include('gamedata/system.lua')

return system.lowerkeys(armorDefs)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
