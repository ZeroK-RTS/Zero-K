local function lowerkeys(t)
  local tn = {}
  for i,v in pairs(t) do
    local typ = type(i)
    if type(v)=="table" then
      v = lowerkeys(v)
    end
    if typ=="string" then
      tn[i:lower()] = v
    else
      tn[i] = v
    end
  end
  return tn
end

local function noFunc()
end

--[[
commTypes = {
	recon = {
		[1] = CopyTable(UnitDefs.commrecon),
		[2] = CopyTable(UnitDefs.commadvrecon),
	},
	strike = {
		[1] = CopyTable(UnitDefs.armcom),
		[2] = CopyTable(UnitDefs.armadvcom),
	},
	battle = {
		[1] = CopyTable(UnitDefs.corcom),
		[2] = CopyTable(UnitDefs.coradvcom),
	},
	support = {
		[1] = CopyTable(UnitDefs.commsupport),
		[2] = CopyTable(UnitDefs.commadvsupport),
	},
}
]]--

weapons = {}

local weaponsList = VFS.DirList("gamedata/modularcomms/weapons", "*.lua") or {}
for i=1,#weaponsList do
	local name, array = VFS.Include(weaponsList[i])
	weapons[name] = lowerkeys(array)
end

-- name and description don't actually matter ATM, only the keyname and function do
upgrades = {
	-- weapons
	-- it is important that they are prefixed with "commweapon_" in order to get the special handling!
	commweapon_beamlaser = {
		name = "Beam Laser",
		description = "An effective short-range cutting tool",
		func = noFunc,	
	},
	commweapon_disruptor = {
		name = "Disruptor Beam",
		description = "Damages and slows a target",
		func = noFunc,	
	},
	commweapon_heavymachinegun = {
		name = "Heavy Machine Gun",
		description = "Close-in weapon with AoE",
		func = noFunc,	
	},
	commweapon_heatray = {
		name = "Heat Ray",
		description = "Rapidly melts anything at short range; loses damage over distance",
		func = noFunc,	
	},
	commweapon_gaussrifle = {
		name = "Gauss Rifle",
		description = "Precise armor-piercing weapon",
		func = noFunc,	
	},
	commweapon_riotcannon = {
		name = "Riot Cannon",
		description = "The weapon of choice for crowd control",
		func = noFunc,	
	},
	commweapon_rocketlauncher = {
		name = "Rocket Launcher",
		description = "Medium-range hitter",
		func = noFunc,	
	},
	commweapon_shockrifle = {
		name = "Shock Rifle",
		description = "A sniper weapon that inflicts heavy damage to a single target",
		func = noFunc,	
	},
	commweapon_shotgun = {
		name = "Shotgun",
		description = "Can hammer a single large target or shred many small ones",
		func = noFunc,
	},
	commweapon_slowbeam = {
		name = "Slowing Beam",
		description = "Slows an enemy's movement and firing rate; non-lethal",
		func = noFunc,	
	},
	
	-- modules
	module_ablative_armor = {
		name = "Ablative Armor Plates",
		description = "Adds 600 HP",
		func = function(unitDef)
				unitDef.maxdamage = unitDef.maxdamage + 600
			end,
	},	
	module_high_power_servos = {
		name = "High Power Servos",
		description = "More powerful leg servos increase speed by 15% (cumulative)",
		func = function(unitDef)
				unitDef.customparams = unitDef.customparams or {}
				unitDef.customparams.basespeed = unitDef.customparams.basespeed or tostring(unitDef.maxvelocity)
				unitDef.maxvelocity = (unitDef.maxvelocity or 0) + unitDef.customparams.basespeed*0.15
			end,
	},	
	module_fieldradar = {
		name = "Field Radar Module",
		description = "Basic radar system with 1800 range",
		func = function(unitDef)
				unitDef.radardistance = (unitDef.radardistance or 0)
				if unitDef.radardistance < 1800 then unitDef.radardistance = 1800 end
			end,
	},
	module_autorepair = {
		name = "Autorepair System",
		description = "Self-repairs 10 HP/s",
		func = function(unitDef)
				unitDef.autoheal = (unitDef.autoheal or 0) + 10
			end,
	},
	module_adv_nano = {
		name = "CarRepairer's Nanolathe",
		description = "Used by a mythical mechanic/coder, this improved nanolathe adds +3 metal/s build speed",
		func = function(unitDef)
				if unitDef.workertime then unitDef.workertime = unitDef.workertime + 3 end
			end,
	},
	module_jammer = {
		name = "Radar Jammer",
		description = "Masks radar signals of all units within 600 elmos",
		func = function(unitDef)
				unitDef.radardistancejam = 600
				unitDef.activatewhenbuilt = true
				unitDef.onoffable = true
			end,
	},
	module_energy_cell = {
		name = "Energy Cell",
		description = "Compact fuel cells that produce +4 energy",
		func = function(unitDef)
				unitDef.energymake = (unitDef.energymake or 0) + 4
			end,
	},		
	
	--add current comm aura abilities as modules later
	
	-- some old stuff
	adv_composite_armor = {
		name = "Advanced Composite Armor",
		description = "Improved armor increases commander health by 20%",
		func = function(unitDef)
				unitDef.maxdamage = unitDef.maxdamage * 1.2
			end,
	},
	focusing_prism = {
		name = "Focusing Prism",
		description = "Reduces laser attenuation - increases primary weapon range by 20%",
		func = function(unitDef)
				if not (unitDef.weapons and unitDef.weapondefs) then return end
				local wepName = (unitDef.weapons[4] and unitDef.weapons[4].def) or (unitDef.weapons[1] and unitDef.weapons[1].def)
				wepName = string.lower(wepName)
				unitDef.weapondefs[wepName].range = unitDef.weapondefs[wepName].range * 1.2
			end,
	},
}

