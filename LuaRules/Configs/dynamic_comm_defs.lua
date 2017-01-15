local skinDefs = VFS.Include("LuaRules/Configs/dynamic_comm_skins.lua")

local UNBOUNDED_LEVEL = true
local COST_MULT = 1
local HP_MULT = 1

if (Spring.GetModOptions) then
	local modOptions = Spring.GetModOptions()
    if modOptions then
        if modOptions.hpmult and modOptions.hpmult ~= 1 then
            HP_MULT = modOptions.hpmult
        end
    end
end

------------------------------------------------------------------------
-- Module Definitions
------------------------------------------------------------------------

local moduleDefNames = {}

local moduleDefs = {
	-- Empty Module Slots
	{
		name = "nullmodule",
		humanName = "No Module",
		description = "No Module",
		image = "LuaUI/Images/dynamic_comm_menu/cross.png",
		limit = false,
		emptyModule = true,
		cost = 0,
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "nullbasicweapon",
		humanName = "No Weapon",
		description = "No Weapon",
		image = "LuaUI/Images/dynamic_comm_menu/cross.png",
		limit = false,
		emptyModule = true,
		cost = 0,
		requireLevel = 0,
		slotType = "basic_weapon",
	},
	{
		name = "nulladvweapon",
		humanName = "No Weapon",
		description = "No Weapon",
		image = "LuaUI/Images/dynamic_comm_menu/cross.png",
		limit = false,
		emptyModule = true,
		cost = 0 * COST_MULT,
		requireLevel = 0,
		slotType = "adv_weapon",
	},
	
	-- Weapons
	{
		name = "commweapon_beamlaser",
		humanName = "Beam Laser",
		description = "Beam Laser",
		image = "unitpics/commweapon_beamlaser.png",
		limit = 2,
		cost = 50 * COST_MULT,
		requireChassis = {"recon", "assault", "support", "strike"},
		requireLevel = 1,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_beamlaser"
			else
				sharedData.weapon2 = "commweapon_beamlaser"
			end
		end
	},
	{
		name = "commweapon_flamethrower",
		humanName = "Flamethrower",
		description = "Flamethrower",
		image = "unitpics/commweapon_flamethrower.png",
		limit = 2,
		cost = 50 * COST_MULT,
		requireChassis = {"recon", "assault"},
		requireLevel = 1,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_flamethrower"
			else
				sharedData.weapon2 = "commweapon_flamethrower"
			end
		end
	},
	{
		name = "commweapon_heatray",
		humanName = "Heatray",
		description = "Heatray",
		image = "unitpics/commweapon_heatray.png",
		limit = 2,
		cost = 50 * COST_MULT,
		requireChassis = {"assault"},
		requireLevel = 1,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_heatray"
			else
				sharedData.weapon2 = "commweapon_heatray"
			end
		end
	},
	{
		name = "commweapon_heavymachinegun",
		humanName = "Machine Gun",
		description = "Machine Gun",
		image = "unitpics/commweapon_heavymachinegun.png",
		limit = 2,
		cost = 50 * COST_MULT,
		requireChassis = {"recon", "assault", "strike"},
		requireLevel = 1,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.conversion_disruptor] and "commweapon_heavymachinegun_disrupt") or "commweapon_heavymachinegun"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	--{
	--	name = "commweapon_hpartillery",
	--	humanName = "Plasma Artillery",
	--	description = "Plasma Artillery",
	--	image = "unitpics/commweapon_assaultcannon.png",
	--	limit = 2,
	--	cost = 300 * COST_MULT,
	--	requireChassis = {"assault"},
	--	requireLevel = 3,
	--	slotType = "adv_weapon",
	--	applicationFunction = function (modules, sharedData)
	--		if sharedData.noMoreWeapons then
	--			return
	--		end
	--		local weaponName = (modules[moduleDefNames.weaponmod_napalm_warhead] and "commweapon_hpartillery_napalm") or "commweapon_hpartillery"
	--		if not sharedData.weapon1 then
	--			sharedData.weapon1 = weaponName
	--		else
	--			sharedData.weapon2 = weaponName
	--		end
	--	end
	--},
	{
		name = "commweapon_lightninggun",
		humanName = "Lightning Rifle",
		description = "Lightning Rifle",
		image = "unitpics/commweapon_lightninggun.png",
		limit = 2,
		cost = 50 * COST_MULT,
		requireChassis = {"recon", "support", "strike"},
		requireLevel = 1,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.weaponmod_stun_booster] and "commweapon_lightninggun_improved") or "commweapon_lightninggun"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	{
		name = "commweapon_lparticlebeam",
		humanName = "Light Particle Beam",
		description = "Light Particle Beam",
		image = "unitpics/commweapon_lparticlebeam.png",
		limit = 2,
		cost = 50 * COST_MULT,
		requireChassis = {"support", "recon", "strike"},
		requireLevel = 1,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.conversion_disruptor] and "commweapon_disruptor") or "commweapon_lparticlebeam"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	{
		name = "commweapon_missilelauncher",
		humanName = "Missile Launcher",
		description = "Missile Launcher",
		image = "unitpics/commweapon_missilelauncher.png",
		limit = 2,
		cost = 50 * COST_MULT,
		requireChassis = {"support", "strike"},
		requireLevel = 1,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_missilelauncher"
			else
				sharedData.weapon2 = "commweapon_missilelauncher"
			end
		end
	},
	{
		name = "commweapon_riotcannon",
		humanName = "Riot Cannon",
		description = "Riot Cannon",
		image = "unitpics/commweapon_riotcannon.png",
		limit = 2,
		cost = 50 * COST_MULT,
		requireChassis = {"assault"},
		requireLevel = 1,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.weaponmod_napalm_warhead] and "commweapon_riotcannon_napalm") or "commweapon_riotcannon"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	{
		name = "commweapon_rocketlauncher",
		humanName = "Rocket Launcher",
		description = "Rocket Launcher",
		image = "unitpics/commweapon_rocketlauncher.png",
		limit = 2,
		cost = 50 * COST_MULT,
		requireChassis = {"assault"},
		requireLevel = 1,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.weaponmod_napalm_warhead] and "commweapon_rocketlauncher_napalm") or "commweapon_rocketlauncher"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	{
		name = "commweapon_shotgun",
		humanName = "Shotgun",
		description = "Shotgun",
		image = "unitpics/commweapon_shotgun.png",
		limit = 2,
		cost = 50 * COST_MULT,
		requireChassis = {"recon", "support", "strike"},
		requireLevel = 1,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.conversion_disruptor] and "commweapon_shotgun_disrupt") or "commweapon_shotgun"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	{
		name = "commweapon_hparticlebeam",
		humanName = "Heavy Particle Beam",
		description = "Heavy Particle Beam - Replaces other weapons.",
		image = "unitpics/conversion_hparticlebeam.png",
		limit = 1,
		cost = 150 * COST_MULT,
		requireChassis = {"support"},
		requireLevel = 1,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.conversion_disruptor] and "commweapon_heavy_disruptor") or "commweapon_hparticlebeam"
			sharedData.weapon1 = weaponName
			sharedData.weapon2 = nil
			sharedData.noMoreWeapons = true
		end
	},
	{
		name = "commweapon_shockrifle",
		humanName = "Shock Rifle",
		description = "Shock Rifle - Replaces other weapons.",
		image = "unitpics/conversion_shockrifle.png",
		limit = 1,
		cost = 150 * COST_MULT,
		requireChassis = {"support"},
		requireLevel = 1,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			sharedData.weapon1 = "commweapon_shockrifle"
			sharedData.weapon2 = nil
			sharedData.noMoreWeapons = true
		end
	},
	{
		name = "commweapon_clusterbomb",
		humanName = "Cluster Bomb",
		description = "Cluster Bomb",
		image = "unitpics/commweapon_clusterbomb.png",
		limit = 1,
		cost = 150 * COST_MULT,
		requireChassis = {"recon", "assault"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_clusterbomb"
			else
				sharedData.weapon2 = "commweapon_clusterbomb"
			end
		end
	},
	{
		name = "commweapon_concussion",
		humanName = "Concussion Shell",
		description = "Concussion Shell",
		image = "unitpics/commweapon_concussion.png",
		limit = 1,
		cost = 150 * COST_MULT,
		requireChassis = {"recon"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_concussion"
			else
				sharedData.weapon2 = "commweapon_concussion"
			end
		end
	},
	{
		name = "commweapon_disintegrator",
		humanName = "Disintegrator",
		description = "Disintegrator",
		image = "unitpics/commweapon_disintegrator.png",
		limit = 1,
		cost = 150 * COST_MULT,
		requireChassis = {"assault", "strike"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_disintegrator"
			else
				sharedData.weapon2 = "commweapon_disintegrator"
			end
		end
	},
	{
		name = "commweapon_disruptorbomb",
		humanName = "Disruptor Bomb",
		description = "Disruptor Bomb",
		image = "unitpics/commweapon_disruptorbomb.png",
		limit = 1,
		cost = 150 * COST_MULT,
		requireChassis = {"recon", "support", "strike"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_disruptorbomb"
			else
				sharedData.weapon2 = "commweapon_disruptorbomb"
			end
		end
	},
	{
		name = "commweapon_multistunner",
		humanName = "Multistunner",
		description = "Multistunner",
		image = "unitpics/commweapon_multistunner.png",
		limit = 1,
		cost = 150 * COST_MULT,
		requireChassis = {"support", "recon", "strike"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.weaponmod_stun_booster] and "commweapon_multistunner_improved") or "commweapon_multistunner"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	{
		name = "commweapon_napalmgrenade",
		humanName = "Hellfire Grenade",
		description = "Hellfire Grenade",
		image = "unitpics/commweapon_napalmgrenade.png",
		limit = 1,
		cost = 150 * COST_MULT,
		requireChassis = {"assault", "recon"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_napalmgrenade"
			else
				sharedData.weapon2 = "commweapon_napalmgrenade"
			end
		end
	},
	{
		name = "commweapon_slamrocket",
		humanName = "S.L.A.M. Rocket",
		description = "S.L.A.M. Rocket - Minature tactical nuke.",
		image = "unitpics/commweapon_slamrocket.png",
		limit = 1,
		cost = 200 * COST_MULT,
		requireChassis = {"assault"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_slamrocket"
			else
				sharedData.weapon2 = "commweapon_slamrocket"
			end
		end
	},
	
	-- Unique Modules
	{
		name = "econ",
		humanName = "Vanguard Economy Pack",
		description = "Vanguard Economy Pack - A vital part of establishing a beachhead, this module is equiped by all new commanders to kickstart their economy. Provides 3.7 metal income and 5.7 energy income.",
		image = "unitpics/module_energy_cell.png",
		limit = 1,
		unequipable = true,
		cost = 200 * COST_MULT,
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.metalIncome = (sharedData.metalIncome or 0) + 3.7
			sharedData.energyIncome = (sharedData.energyIncome or 0) + 5.7
		end
	},
	{
		name = "commweapon_personal_shield",
		humanName = "Personal Shield",
		description = "Personal Shield - A small, protective bubble shield.",
		image = "unitpics/module_personal_shield.png",
		limit = 1,
		cost = 300 * COST_MULT,
		prohibitingModules = {"module_personal_cloak"},
		requireLevel = 2,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			-- Do not override area shield
			sharedData.shield = sharedData.shield or "commweapon_personal_shield"
		end
	},
	{
		name = "commweapon_areashield",
		humanName = "Area Shield",
		description = "Area Shield - Projects a large shield. Replaces Personal Shield.",
		image = "unitpics/module_areashield.png",
		limit = 1,
		cost = 250 * COST_MULT,
		requireChassis = {"assault", "support"},
		requireOneOf = {"commweapon_personal_shield"},
		prohibitingModules = {"module_personal_cloak"},
		requireLevel = 3,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.shield = "commweapon_areashield"
		end
	},
	{
		name = "weaponmod_napalm_warhead",
		humanName = "Napalm Warhead",
		description = "Napalm Warhead - Riot Cannon, Rocket Launcher and Plasma Artillery set targets on fire. Reduced direct damage.",
		image = "unitpics/weaponmod_napalm_warhead.png",
		limit = 1,
		cost = 350 * COST_MULT,
		requireChassis = {"assault"},
		requireOneOf = {"commweapon_rocketlauncher", "commweapon_hpartillery", "commweapon_riotcannon"},
		requireLevel = 2,
		slotType = "module",
	},
	{
		name = "conversion_disruptor",
		humanName = "Disruptor Ammo",
		description = "Disruptor Ammo - Heavy Machine Gun, Shotgun and Particle Beams deal slow damage. Reduced direct damage.",
		image = "unitpics/weaponmod_disruptor_ammo.png",
		limit = 1,
		cost = 450 * COST_MULT,
		requireChassis = {"strike", "recon", "support"},
		requireOneOf = {"commweapon_heavymachinegun", "commweapon_shotgun", "commweapon_hparticlebeam", "commweapon_lparticlebeam"},
		requireLevel = 2,
		slotType = "module",
	},
	{
		name = "weaponmod_stun_booster",
		humanName = "Flux Amplifier",
		description = "Flux Amplifier - Improves EMP duration and strength of Lightning Rifle and Multistunner.",
		image = "unitpics/weaponmod_stun_booster.png",
		limit = 1,
		cost = 300 * COST_MULT,
		requireChassis = {"support", "strike", "recon"},
		requireOneOf = {"commweapon_lightninggun", "commweapon_multistunner"},
		requireLevel = 2,
		slotType = "module",
	},
	{
		name = "module_jammer",
		humanName = "Radar Jammer",
		description = "Radar Jammer - Hide the radar signals of nearby units.",
		image = "unitpics/module_jammer.png",
		limit = 1,
		cost = 200 * COST_MULT,
		requireLevel = 2,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			if not sharedData.cloakFieldRange then
				sharedData.radarJammingRange = 500
			end
		end
	},
	{
		name = "module_radarnet",
		humanName = "Field Radar",
		description = "Field Radar - Attaches a basic radar system to the Commander.",
		image = "unitpics/module_fieldradar.png",
		limit = 1,
		cost = 75 * COST_MULT,
		requireLevel = 1,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.radarRange = 1800
		end
	},
	{
		name = "module_personal_cloak",
		humanName = "Personal Cloak",
		description = "Personal Cloak - A personal cloaking device for the Commander.",
		image = "unitpics/module_personal_cloak.png",
		limit = 1,
		cost = 400 * COST_MULT,
		prohibitingModules = {"commweapon_personal_shield", "commweapon_areashield"},
		requireLevel = 2,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.decloakDistance = math.max(sharedData.decloakDistance or 0, 150)
			sharedData.personalCloak = true
		end
	},
	{
		name = "module_cloak_field",
		humanName = "Cloaking Field",
		description = "Cloaking Field - Cloaks all nearby units.",
		image = "unitpics/module_cloak_field.png",
		limit = 1,
		cost = 600 * COST_MULT,
		requireChassis = {"support", "strike"},
		requireOneOf = {"module_jammer"},
		requireLevel = 3,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.areaCloak = true
			sharedData.decloakDistance = 180
			sharedData.cloakFieldRange = 350
			sharedData.cloakFieldUpkeep = 15
			sharedData.radarJammingRange = 350
		end
	},
	{
		name = "module_resurrect",
		humanName = "Lazarus Device",
		description = "Lazarus Device - Upgrade nanolathe to allow resurrection.",
		image = "unitpics/module_resurrect.png",
		limit = 1,
		cost = 400 * COST_MULT,
		requireChassis = {"support"},
		requireLevel = 2,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.canResurrect = true
		end
	},
	
	-- Repeat Modules
	{
		name = "module_companion_drone",
		humanName = "Companion Drone",
		description = "Companion Drone - Commander spawns protective drones. Limit: 8",
		image = "unitpics/module_companion_drone.png",
		limit = 8,
		cost = 300 * COST_MULT,
		requireLevel = 2,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.drones = (sharedData.drones or 0) + 1
		end
	},
	{
		name = "module_battle_drone",
		humanName = "Battle Drone",
		description = "Battle Drone - Commander spawns heavy drones. Limit: 8, Requires Companion Drone",
		image = "unitpics/module_battle_drone.png",
		limit = 8,
		cost = 500 * COST_MULT,
		requireChassis = {"support"},
		requireOneOf = {"module_companion_drone"},
		requireLevel = 3,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.battleDrones = (sharedData.battleDrones or 0) + 1
		end
	},
	{
		name = "module_autorepair",
		humanName = "Autorepair",
		description = "Autorepair - Commander self-repairs at +10 hp/s. Reduces Health by " .. 100*HP_MULT .. ". Limit: 8",
		image = "unitpics/module_autorepair.png",
		limit = 8,
		cost = 150 * COST_MULT,
		requireLevel = 1,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 10
			sharedData.healthBonus = (sharedData.healthBonus or 0) - 100*HP_MULT
		end
	},
	{
		name = "module_ablative_armor",
		humanName = "Ablative Armour Plates",
		description = "Ablative Armour Plates - Provides " .. 600*HP_MULT .. " health. Limit: 8",
		image = "unitpics/module_ablative_armor.png",
		limit = 8,
		cost = 150 * COST_MULT,
		requireLevel = 1,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.healthBonus = (sharedData.healthBonus or 0) + 600*HP_MULT
		end
	},
	{
		name = "module_heavy_armor",
		humanName = "High Density Plating",
		description = "High Density Plating - Provides " .. 1600*HP_MULT .. " health but reduces movement by 10%. " .. 
		"Limit: 8, Requires Ablative Armour Plates",
		image = "unitpics/module_heavy_armor.png",
		limit = 8,
		cost = 400 * COST_MULT,
		requireOneOf = {"module_ablative_armor"},
		requireLevel = 2,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.healthBonus = (sharedData.healthBonus or 0) + 1600*HP_MULT
			sharedData.speedMult = (sharedData.speedMult or 1) - 0.1
		end
	},
	{
		name = "module_dmg_booster",
		humanName = "Damage Booster",
		description = "Damage Booster - Increases damage by 10%, increased weapon weight reduces speed by 2.5%.  Limit: 8",
		image = "unitpics/module_dmg_booster.png",
		limit = 8,
		cost = 150 * COST_MULT,
		requireLevel = 1,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			-- Damage boost is applied via clone swapping
			sharedData.damageMult = (sharedData.damageMult or 1) + 0.1
			sharedData.speedMult = (sharedData.speedMult or 1) - 0.025
		end
	},
	{
		name = "module_high_power_servos",
		humanName = "High Power Servos",
		description = "High Power Servos - Increases speed by 10%. Limit: 8",
		image = "unitpics/module_high_power_servos.png",
		limit = 8,
		cost = 150 * COST_MULT,
		requireLevel = 1,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.speedMult = (sharedData.speedMult or 1) + 0.1
		end
	},
	{
		name = "module_adv_targeting",
		humanName = "Adv. Targeting System",
		description = "Advanced Targeting System - Increases range by 7.5%, increased weapon weight reduces speed by 2.5%. Limit: 8",
		image = "unitpics/module_adv_targeting.png",
		limit = 8,
		cost = 150 * COST_MULT,
		requireLevel = 1,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.rangeMult = (sharedData.rangeMult or 1) + 0.075
			sharedData.speedMult = (sharedData.speedMult or 1) - 0.025
		end
	},
	{
		name = "module_adv_nano",
		humanName = "CarRepairer's Nanolathe",
		description = "CarRepairer's Nanolathe - Increases build power by 5. Limit: 8",
		image = "unitpics/module_adv_nano.png",
		limit = 8,
		cost = 150 * COST_MULT,
		requireLevel = 1,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			-- All comms have 10 BP in their unitDef (even support)
			sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 5
		end
	},
	
	-- Decorative Modules
	{
		name = "banner_overhead",
		humanName = "Banner",
		description = "Banner",
		image = "unitpics/module_ablative_armor.png",
		limit = 1,
		cost = 0,
		requireChassis = {},
		requireLevel = 0,
		slotType = "decoration",
		applicationFunction = function (modules, sharedData)
			sharedData.bannerOverhead = true
		end
	}
}

for name, data in pairs(skinDefs) do
	moduleDefs[#moduleDefs + 1] = {
		name = "skin_" .. name,
		humanName = data.humanName,
		description = data.humanName,
		image = "unitpics/module_ablative_armor.png",
		limit = 1,
		cost = 0,
		requireChassis = {data.chassis},
		requireLevel = 0,
		slotType = "decoration",
		applicationFunction = function (modules, sharedData)
			sharedData.skinOverride = name
		end
	}
end

for i = 1, #moduleDefs do
	moduleDefNames[moduleDefs[i].name] = i
end

------------------------------------------------------------------------
-- Chassis Definitions
------------------------------------------------------------------------

-- it'd help if there was a name -> chassisDef map you know

--------------------------------------------------------------------------------------
-- Must match staticomms.lua around line 250 (MakeCommanderChassisClones)
--------------------------------------------------------------------------------------
-- A note on personal shield and area shield:
-- The personal shield weapon is replaced by the area shield weapon in moduledefs.lua.
-- Therefore the clonedef with an area shield and no personal shield does not actually
-- have an area shield. This means that the below functions return the correct values,
-- if a commander has a an area shield and a personal shield it should return the
-- clone which was given those modules.

local function GetReconCloneModulesString(modulesByDefID)
	return (modulesByDefID[moduleDefNames.commweapon_personal_shield] or 0)
end

local function GetSupportCloneModulesString(modulesByDefID)
	return (modulesByDefID[moduleDefNames.commweapon_personal_shield] or 0) ..
		(modulesByDefID[moduleDefNames.commweapon_areashield] or 0) ..
		(modulesByDefID[moduleDefNames.module_resurrect] or 0)
end

local function GetAssaultCloneModulesString(modulesByDefID)
	return (modulesByDefID[moduleDefNames.commweapon_personal_shield] or 0) ..
		(modulesByDefID[moduleDefNames.commweapon_areashield] or 0)
end

local function GetStrikeCloneModulesString(modulesByDefID)
	return (modulesByDefID[moduleDefNames.commweapon_personal_shield] or 0) ..
		(modulesByDefID[moduleDefNames.commweapon_areashield] or 0)
end

local morphCosts = {
	25,
	100,
	400,
	200,
	300,
}

local function extraLevelCostFunction(level)
	return (level - 2) * 100 * COST_MULT 
end

local chassisDefs = {
	{
		name = "strike",
		humanName = "Strike",
		baseUnitDef = UnitDefNames and UnitDefNames["dynstrike0"].id,
		extraLevelCostFunction = extraLevelCostFunction,
		maxNormalLevel = 5,
		secondPeashooter = true,
		levelDefs = {
			[0] = {
				morphBuildPower = 10,
				morphBaseCost = 0,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynstrike0"].id
				end,
				upgradeSlots = {},
			},
			[1] = {
				morphBuildPower = 10,
				morphBaseCost = morphCosts[1],
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynstrike1_" .. GetStrikeCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotAllows = "basic_weapon",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[2] = {
				morphBuildPower = 15,
				morphBaseCost = morphCosts[2] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 12.5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynstrike2_" .. GetStrikeCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[3] = {
				morphBuildPower = 20,
				morphBaseCost = morphCosts[3] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 20
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynstrike3_" .. GetStrikeCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotAllows = {"adv_weapon", "basic_weapon"},
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[4] = {
				morphBuildPower = 25,
				morphBaseCost = morphCosts[4] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 27.5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynstrike4_" .. GetStrikeCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[5] = {
				morphBuildPower = 30,
				morphBaseCost = morphCosts[5] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 35
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynstrike5_" .. GetStrikeCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
		}
	},
	{
		name = "recon",
		humanName = "Recon",
		baseUnitDef = UnitDefNames and UnitDefNames["dynrecon0"].id,
		extraLevelCostFunction = extraLevelCostFunction,
		maxNormalLevel = 5,
		levelDefs = {
			[0] = {
				morphBuildPower = 10,
				morphBaseCost = 0,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynrecon0"].id
				end,
				upgradeSlots = {},
			},
			[1] = {
				morphBuildPower = 10,
				morphBaseCost = morphCosts[1],
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynrecon1_" .. GetReconCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotAllows = "basic_weapon",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[2] = {
				morphBuildPower = 15,
				morphBaseCost = morphCosts[2] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynrecon2_" .. GetReconCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[3] = {
				morphBuildPower = 20,
				morphBaseCost = morphCosts[3] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynrecon3_" .. GetReconCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotAllows = "adv_weapon",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[4] = {
				morphBuildPower = 25,
				morphBaseCost = morphCosts[4] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynrecon4_" .. GetReconCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[5] = {
				morphBuildPower = 30,
				morphBaseCost = morphCosts[5] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynrecon5_" .. GetReconCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
		}
	},
	{
		name = "support",
		humanName = "Engineer",
		baseUnitDef = UnitDefNames and UnitDefNames["dynsupport0"].id,
		extraLevelCostFunction = extraLevelCostFunction,
		maxNormalLevel = 5,
		levelDefs = {
			[0] = {
				morphBuildPower = 10,
				morphBaseCost = 0,
				chassisApplicationFunction = function (modules, sharedData)
					-- All comms have 10 BP in their unitDef (even support)
					sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 2
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5 
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynsupport0"].id
				end,
				upgradeSlots = {},
			},
			[1] = {
				morphBuildPower = 10,
				morphBaseCost = morphCosts[1],
				chassisApplicationFunction = function (modules, sharedData)
					-- All comms have 10 BP in their unitDef (even support)
					sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 2
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynsupport1_" .. GetSupportCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotAllows = "basic_weapon",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[2] = {
				morphBuildPower = 15,
				morphBaseCost = morphCosts[2] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					-- All comms have 10 BP in their unitDef (even support)
					sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 4
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynsupport2_" .. GetSupportCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[3] = {
				morphBuildPower = 20,
				morphBaseCost = morphCosts[3] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					-- All comms have 10 BP in their unitDef (even support)
					sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 6
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynsupport3_" .. GetSupportCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotAllows = "adv_weapon",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[4] = {
				morphBuildPower = 25,
				morphBaseCost = morphCosts[4],
				chassisApplicationFunction = function (modules, sharedData)
					-- All comms have 10 BP in their unitDef (even support)
					sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 8
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynsupport4_" .. GetSupportCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[5] = {
				morphBuildPower = 30,
				morphBaseCost = morphCosts[5],
				chassisApplicationFunction = function (modules, sharedData)
					-- All comms have 10 BP in their unitDef (even support)
					sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 10
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynsupport5_" .. GetSupportCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
		}
	},
	{
		name = "assault",
		humanName = "Guardian",
		baseUnitDef = UnitDefNames and UnitDefNames["dynassault0"].id,
		extraLevelCostFunction = extraLevelCostFunction,
		maxNormalLevel = 5,
		secondPeashooter = true,
		levelDefs = {
			[0] = {
				morphBuildPower = 10,
				morphBaseCost = 0,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynassault0"].id
				end,
				upgradeSlots = {},
			},
			[1] = {
				morphBuildPower = 10,
				morphBaseCost = morphCosts[1],
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynassault1_" .. GetAssaultCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotAllows = "basic_weapon",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[2] = {
				morphBuildPower = 15,
				morphBaseCost = morphCosts[2] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynassault2_" .. GetAssaultCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[3] = {
				morphBuildPower = 20,
				morphBaseCost = morphCosts[3] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynassault3_" .. GetAssaultCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotAllows = {"adv_weapon", "basic_weapon"},
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[4] = {
				morphBuildPower = 25,
				morphBaseCost = morphCosts[4] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynassault4_" .. GetAssaultCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
			[5] = {
				morphBuildPower = 30,
				morphBaseCost = morphCosts[5] * COST_MULT,
				chassisApplicationFunction = function (modules, sharedData)
					sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
				end,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynassault5_" .. GetAssaultCloneModulesString(modulesByDefID)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotAllows = "module",
					},
				},
			},
		}
	}
}

local chassisDefByBaseDef = {}
if UnitDefNames then
	for i = 1, #chassisDefs do
		chassisDefByBaseDef[chassisDefs[i].baseUnitDef] = i
	end
end

local chassisDefNames = {}
for i = 1, #chassisDefs do
	chassisDefNames[chassisDefs[i].name] = i
end

------------------------------------------------------------------------
-- Processing
------------------------------------------------------------------------

-- Set cost in module tooltip
for i = 1, #moduleDefs do
	local data = moduleDefs[i]
	if data.cost > 0 then
		data.description = data.description .. "\nCost: " .. data.cost
	end
end

-- Transform from human readable format into number indexed format
for i = 1, #moduleDefs do
	local data = moduleDefs[i]
	
	-- Required modules are a list of moduleDefIDs
	if data.requireOneOf then
		local newRequire = {}
		for j = 1, #data.requireOneOf do
			local reqModuleID = moduleDefNames[data.requireOneOf[j]]
			if reqModuleID then
				newRequire[#newRequire + 1] = reqModuleID
			end
		end
		data.requireOneOf = newRequire
	end
	
	-- Prohibiting modules are a list of moduleDefIDs too
	if data.prohibitingModules then
		local newProhibit = {}
		for j = 1, #data.prohibitingModules do
			local reqModuleID = moduleDefNames[data.prohibitingModules[j]]
			if reqModuleID then
				newProhibit[#newProhibit + 1] = reqModuleID
			end
		end
		data.prohibitingModules = newProhibit
	end
	
	
	-- Required chassis is a map indexed by chassisDefID
	if data.requireChassis then
		local newRequire = {}
		for j = 1, #data.requireChassis do
			for k = 1, #chassisDefs do
				if chassisDefs[k].name == data.requireChassis[j] then
					newRequire[k] = true
					break
				end
			end
		end
		data.requireChassis = newRequire
	end
end

-- Find empty modules so slots can find their appropriate empty module
local emptyModules = {}
for i = 1, #moduleDefs do
	if moduleDefs[i].emptyModule then
		emptyModules[moduleDefs[i].slotType] = i
	end
end

-- Process slotAllows into a table of keys
for i = 1, #chassisDefs do
	for j = 0, #chassisDefs[i].levelDefs do
		local levelData = chassisDefs[i].levelDefs[j]
		for k = 1, #levelData.upgradeSlots do
			local slotData = levelData.upgradeSlots[k]
			if type(slotData.slotAllows) == "string" then
				slotData.empty = emptyModules[slotData.slotAllows]
				slotData.slotAllows = {[slotData.slotAllows] = true}
			else
				local newSlotAllows = {}
				slotData.empty = emptyModules[slotData.slotAllows[1]]
				for m = 1, #slotData.slotAllows do
					newSlotAllows[slotData.slotAllows[m]] = true
				end
				slotData.slotAllows = newSlotAllows
			end
		end
	end
end

-- Add baseWreckID and baseHeapID
if UnitDefNames then
	for i = 1, #chassisDefs do
		local data = chassisDefs[i]
		local wreckData = FeatureDefNames[UnitDefs[data.baseUnitDef].wreckName]

		data.baseWreckID = wreckData.id
		data.baseHeapID = wreckData.deathFeatureID
	end
end

------------------------------------------------------------------------
-- Utility Functions
------------------------------------------------------------------------

local function ModuleIsValid(level, chassis, slotAllows, moduleDefID, alreadyOwned, alreadyOwned2)
	local data = moduleDefs[moduleDefID]
	if (not slotAllows[data.slotType]) or (data.requireLevel or 0) > level or 
			(data.requireChassis and (not data.requireChassis[chassis])) or data.unequipable then
		return false
	end
	
	-- Check that requirements are met
	if data.requireOneOf then
		local foundRequirement = false
		for j = 1, #data.requireOneOf do
			-- Modules should not depend on themselves so this check is simplier than the
			-- corresponding chcek in the replacement set generator.
			local reqDefID = data.requireOneOf[j]
			if (alreadyOwned[reqDefID] or (alreadyOwned2 and alreadyOwned2[reqDefID])) then
				foundRequirement = true
				break
			end
		end
		if not foundRequirement then
			return false
		end
	end
	
	-- Check that nothing prohibits this module
	if data.prohibitingModules then
		for j = 1, #data.prohibitingModules do
			-- Modules cannot prohibit themselves otherwise this check makes no sense.
			local probihitDefID = data.prohibitingModules[j]
			if (alreadyOwned[probihitDefID] or (alreadyOwned2 and alreadyOwned2[probihitDefID])) then
				return false
			end
		end
	
	end
	
	-- Check that the module limit is not reached
	if data.limit and (alreadyOwned[moduleDefID] or (alreadyOwned2 and alreadyOwned2[moduleDefID])) then
		local count = (alreadyOwned[moduleDefID] or 0) + ((alreadyOwned2 and alreadyOwned2[moduleDefID]) or 0) 
		if count > data.limit then
			return false
		end
	end
	return true
end

local function ModuleSetsAreIdentical(set1, set2)
	-- Sets should be sorted prior to this function
	if (not set1) or (not set2) or (#set1 ~= #set2) then
		return false
	end

	local validUnit = true
	for i = 1, #set1 do
		if set1[i] ~= set2[i] then
			return false
		end
	end
	return true
end

local function ModuleListToByDefID(moduleList)
	local byDefID = {}
	for i = 1, #moduleList do
		local defID = moduleList[i]
		byDefID[defID] = (byDefID[defID] or 0) + 1
	end
	return byDefID
end

local function GetUnitDefShield(unitDefNameOrID, shieldName)
	local unitDefID = (type(unitDefNameOrID) == "string" and UnitDefNames[unitDefNameOrID].id) or unitDefNameOrID
	local wepTable = UnitDefs[unitDefID].weapons
	for num = 1, #wepTable do
		local wd = WeaponDefs[wepTable[num].weaponDef]
		if wd.type == "Shield" then
			local weaponName = string.sub(wd.name, (string.find(wd.name,"commweapon") or 0), 100)
			if weaponName == shieldName then
				return wd.id, num
			end
		end
	end
end

local utilities = {
	ModuleIsValid          = ModuleIsValid,
	ModuleSetsAreIdentical = ModuleSetsAreIdentical,
	ModuleListToByDefID    = ModuleListToByDefID,
	GetUnitDefShield       = GetUnitDefShield
}

------------------------------------------------------------------------
-- Return Values
------------------------------------------------------------------------

return moduleDefs, chassisDefs, utilities, UNBOUNDED_LEVEL, chassisDefByBaseDef, moduleDefNames, chassisDefNames
