
local skinDefs = VFS.Include("LuaRules/Configs/dynamic_comm_skins.lua")

------------------------------------------------------------------------
-- Module Definitions
------------------------------------------------------------------------

local moduleDefs = {
	-- Empty Module Slots
	{
		name = "nullmodule",
		humanName = "No Module",
		description = "No Module",
		image = "LuaUI/Images/dynamic_comm_menu/cross.png",
		limit = false,
		cost = 0,
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "nullweapon",
		humanName = "No Weapon",
		description = "No Weapon",
		image = "LuaUI/Images/dynamic_comm_menu/cross.png",
		limit = false,
		cost = 0,
		requireLevel = 0,
		slotType = "weapon",
	},
	
	-- Weapons
	{
		name = "commweapon_beamlaser",
		humanName = "Beam Laser",
		description = "Beam Laser",
		image = "unitpics/commweapon_beamlaser.png",
		limit = 1,
		cost = 100,
		requireChassis = {"recon", "support"},
		requireLevel = 1,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_beamlaser"
			else
				sharedData.weapon2 = "commweapon_beamlaser"
			end
		end
	},
	{
		name = "commweapon_clusterbomb",
		humanName = "Cluster Bomb",
		description = "Cluster Bomb",
		image = "unitpics/commweapon_clusterbomb.png",
		limit = 1,
		cost = 100,
		requireChassis = {"recon", "assault"},
		requireLevel = 3,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
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
		cost = 100,
		requireChassis = {"support"},
		requireLevel = 3,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
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
		cost = 100,
		requireChassis = {"assault"},
		requireLevel = 3,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
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
		cost = 100,
		requireChassis = {"recon", "support"},
		requireLevel = 3,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_disruptorbomb"
			else
				sharedData.weapon2 = "commweapon_disruptorbomb"
			end
		end
	},
	{
		name = "commweapon_flamethrower",
		humanName = "Flamethrower",
		description = "Flamethrower",
		image = "unitpics/commweapon_flamethrower.png",
		limit = 1,
		cost = 100,
		requireChassis = {"recon", "assault"},
		requireLevel = 1,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
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
		limit = 1,
		cost = 100,
		requireChassis = {"recon", "assault"},
		requireLevel = 1,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
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
		limit = 1,
		cost = 50,
		requireChassis = {"recon", "assault"},
		requireLevel = 1,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_heavymachinegun"
			else
				sharedData.weapon2 = "commweapon_heavymachinegun"
			end
		end
	},
	{
		name = "commweapon_hparticlebeam",
		humanName = "Heavy Particle Beam",
		description = "Heavy Particle Beam",
		image = "unitpics/conversion_hparticlebeam.png",
		limit = 1,
		cost = 100,
		requireChassis = {"support"},
		requireLevel = 1,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_hparticlebeam"
			else
				sharedData.weapon2 = "commweapon_hparticlebeam"
			end
		end
	},
	{
		name = "commweapon_hpartillery",
		humanName = "Plasma Artillery",
		description = "Plasma Artillery",
		image = "unitpics/commweapon_assaultcannon.png",
		limit = 1,
		cost = 100,
		requireChassis = {"assault", "support"},
		requireLevel = 1,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_hpartillery"
			else
				sharedData.weapon2 = "commweapon_hpartillery"
			end
			--if not sharedData.weapon1 then
			--	sharedData.weapon1 = "commweapon_hpartillery_napalm"
			--else
			--	sharedData.weapon2 = "commweapon_hpartillery_napalm"
			--end
		end
	},
	{
		name = "commweapon_lightninggun",
		humanName = "Lightning Rifle",
		description = "Lightning Rifle",
		image = "unitpics/commweapon_lightninggun.png",
		limit = 1,
		cost = 100,
		requireChassis = {"recon", "support"},
		requireLevel = 1,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_lightninggun"
			else
				sharedData.weapon2 = "commweapon_lightninggun"
			end
		end
	},
	{
		name = "commweapon_lparticlebeam",
		humanName = "Light Particle Beam",
		description = "Light Particle Beam",
		image = "unitpics/commweapon_lparticlebeam.png",
		limit = 1,
		cost = 100,
		requireChassis = {"support", "recon"},
		requireLevel = 1,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_lparticlebeam"
			else
				sharedData.weapon2 = "commweapon_lparticlebeam"
			end
			--if not sharedData.weapon1 then
			--	sharedData.weapon1 = "commweapon_disruptor"
			--else
			--	sharedData.weapon2 = "commweapon_disruptor"
			--end
		end
	},
	{
		name = "commweapon_missilelauncher",
		humanName = "Missile Launcher",
		description = "Missile Launcher",
		image = "unitpics/commweapon_missilelauncher.png",
		limit = 1,
		cost = 50,
		requireChassis = {"support"},
		requireLevel = 1,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_missilelauncher"
			else
				sharedData.weapon2 = "commweapon_missilelauncher"
			end
		end
	},
	{
		name = "commweapon_multistunner",
		humanName = "Multistunner",
		description = "Multistunner",
		image = "unitpics/commweapon_multistunner.png",
		limit = 1,
		cost = 50,
		requireChassis = {"support", "recon"},
		requireLevel = 3,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_multistunner"
			else
				sharedData.weapon2 = "commweapon_multistunner"
			end
		end
	},
	{
		name = "commweapon_napalmgrenade",
		humanName = "Napalm Grenade",
		description = "Napalm Grenade",
		image = "unitpics/commweapon_napalmgrenade.png",
		limit = 1,
		cost = 50,
		requireChassis = {"assault", "recon"},
		requireLevel = 3,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_napalmgrenade"
			else
				sharedData.weapon2 = "commweapon_napalmgrenade"
			end
		end
	},
	{
		name = "commweapon_riotcannon",
		humanName = "Riot Cannon",
		description = "Riot Cannon",
		image = "unitpics/commweapon_riotcannon.png",
		limit = 1,
		cost = 50,
		requireChassis = {"assault"},
		requireLevel = 1,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_riotcannon"
			else
				sharedData.weapon2 = "commweapon_riotcannon"
			end
		end
	},
	{
		name = "commweapon_rocketlauncher",
		humanName = "Rocket Launcher",
		description = "Rocket Launcher",
		image = "unitpics/commweapon_rocketlauncher.png",
		limit = 1,
		cost = 50,
		requireChassis = {"assault", "support"},
		requireLevel = 1,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_rocketlauncher"
			else
				sharedData.weapon2 = "commweapon_rocketlauncher"
			end
		end
	},
	{
		name = "commweapon_shockrifle",
		humanName = "Shock Rifle",
		description = "Shock Rifle",
		image = "unitpics/conversion_shockrifle.png",
		limit = 1,
		cost = 50,
		requireChassis = {"support"},
		requireLevel = 1,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_shockrifle"
			else
				sharedData.weapon2 = "commweapon_shockrifle"
			end
		end
	},
	{
		name = "commweapon_shotgun",
		humanName = "Shotgun",
		description = "Shotgun",
		image = "unitpics/commweapon_shotgun.png",
		limit = 1,
		cost = 50,
		requireChassis = {"assault", "recon"},
		requireLevel = 1,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_shotgun"
			else
				sharedData.weapon2 = "commweapon_shotgun"
			end
		end
	},
	{
		name = "commweapon_slamrocket",
		humanName = "S.L.A.M. Rocket",
		description = "S.L.A.M. Rocket",
		image = "unitpics/commweapon_slamrocket.png",
		limit = 1,
		cost = 50,
		requireChassis = {"assault"},
		requireLevel = 3,
		slotType = "weapon",
		applicationFunction = function (modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_slamrocket"
			else
				sharedData.weapon2 = "commweapon_slamrocket"
			end
		end
	},
	
	-- Unique Modules
	{
		name = "commweapon_personal_shield",
		humanName = "Personal Shield",
		description = "A small, protective bubble shield.",
		image = "unitpics/module_personal_shield.png",
		limit = 1,
		cost = 100,
		prohibitingModules = {"personalcloak"},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.shield = "commweapon_personal_shield"
		end
	},
	{
		name = "commweapon_areashield",
		humanName = "Area Shield",
		description = "The Emperor protects",
		image = "unitpics/module_areashield.png",
		limit = 1,
		cost = 100,
		requireChassis = {"assault", "support"},
		requireModules = {"commweapon_personal_shield"},
		prohibitingModules = {"personalcloak"},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.shield = "commweapon_areashield"
		end
	},
	{
		name = "econ",
		humanName = "Vanguard Economy Pack",
		description = "Vanguard Economy Pack, produces 4 Metal and 6 Energy.",
		image = "unitpics/module_energy_cell.png",
		limit = 1,
		unequipable = true,
		cost = 0,
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.metalIncome = (sharedData.metalIncome or 0) + 3.7
			sharedData.energyIncome = (sharedData.energyIncome or 0) + 5.7
		end
	},
	{
		name = "radarjammer",
		humanName = "Radar Jammer",
		description = "Makes the Commander and nearby units invisible to radar.",
		image = "unitpics/module_jammer.png",
		limit = 1,
		cost = 100,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			if not sharedData.cloakFieldRange then
				sharedData.radarJammingRange = 500
			end
		end
	},
	{
		name = "radar",
		humanName = "Field Radar",
		description = "Attaches a basic radar system to the Commander.",
		image = "unitpics/module_fieldradar.png",
		limit = 1,
		cost = 100,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.radarRange = 1800
		end
	},
	{
		name = "personalcloak",
		humanName = "Personal Cloak",
		description = "A personal cloaking device for the Commander.",
		image = "unitpics/module_personal_cloak.png",
		limit = 1,
		cost = 100,
		requireModules = {},
		prohibitingModules = {"commweapon_personal_shield", "commweapon_area)shield"},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.decloakDistance = 150
			sharedData.personalCloak = true
		end
	},
	{
		name = "areacloak",
		humanName = "Cloaking Field",
		description = "Cloaks all nearby units.",
		image = "unitpics/module_cloak_field.png",
		limit = 1,
		cost = 100,
		requireModules = {"radarjammer"},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.areaCloak = true
			sharedData.cloakFieldRange = 350
			sharedData.cloakFieldUpkeep = 15
			sharedData.radarJammingRange = 350
		end
	},
	
	-- Repeat Modules
	{
		name = "health",
		humanName = "Ablative Armour Plates",
		description = "Ablative Armour Plates, provides 600 health. Limit 8.",
		image = "unitpics/module_ablative_armor.png",
		limit = 3,
		cost = 60,
		requireChassis = {"recon", "support"},
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.healthBonus = (sharedData.healthBonus or 0) + 600
		end
	},
	{
		name = "bigHealth",
		humanName = "High Density Plating",
		description = "High Density Plating, provides 1600 health but reduces movement by 10%. Limit 7, requires Ablative Armour Plates.",
		image = "unitpics/module_heavy_armor.png",
		limit = 3,
		cost = 50,
		requireModules = {"health"},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.healthBonus = (sharedData.healthBonus or 0) + 1600
			sharedData.speedMult = (sharedData.speedMult or 1) - 0.1
		end
	},
	{
		name = "damageBooster",
		humanName = "Damage Booster",
		description = "Damage Booster, increases damage by 10%. Limit 8.",
		image = "unitpics/module_dmg_booster.png",
		limit = 8,
		cost = 40,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "speed",
		humanName = "High Power Servos",
		description = "High Power Servos, increases speed by 10%. Limit 8",
		image = "unitpics/module_high_power_servos.png",
		limit = 8,
		cost = 40,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.speedMult = (sharedData.speedMult or 1) + 0.1
		end
	},
	{
		name = "range",
		humanName = "Advanced Targeting System",
		description = "Advanced Targeting System, increases range by 10%. Limit 8",
		image = "unitpics/module_adv_targeting.png",
		limit = 8,
		cost = 40,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.rangeMult = (sharedData.rangeMult or 1) + 0.1
		end
	},
	{
		name = "buildpower",
		humanName = "CarRepairer's Nanolathe",
		description = "CarRepairer's Nanolathe, increases build power by 5. Limit 8",
		image = "unitpics/module_adv_nano.png",
		limit = 8,
		cost = 40,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			-- All comms have 10 BP in their unitDef (even support)
			sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 5
			sharedData.metalIncome = (sharedData.metalIncome or 0) + 0.15
			sharedData.energyIncome = (sharedData.energyIncome or 0) + 0.15
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
		requireModules = {},
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
		requireModules = {},
		requireLevel = 0,
		slotType = "decoration",
		applicationFunction = function (modules, sharedData)
			sharedData.skinOverride = name
		end
	}
end

local moduleDefNames = {}
for i = 1, #moduleDefs do
	moduleDefNames[moduleDefs[i].name] = i
end

------------------------------------------------------------------------
-- Chassis Definitions
------------------------------------------------------------------------

-- it'd help if there was a name -> chassisDef map you know

local chassisDefs = {
	{
		name = "recon",
		humanName = "Recon",
		baseUnitDef = UnitDefNames and UnitDefNames["dynrecon0"].id,
		levelDefs = {
			{
				morphBuildPower = 10,
				morphBaseCost = 20,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynrecon1_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotType = "weapon",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 15,
				morphBaseCost = 30,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynrecon2_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 20,
				morphBaseCost = 30,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynrecon3_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotType = "weapon",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 20,
				morphBaseCost = 30,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynrecon4_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 20,
				morphBaseCost = 30,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynrecon5_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
		}
	},
	{
		name = "support",
		humanName = "Engineer",
		baseUnitDef = UnitDefNames and UnitDefNames["dynsupport0"].id,
		levelDefs = {
			
			{
				morphBuildPower = 10,
				morphBaseCost = 20,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynsupport1_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotType = "weapon",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 15,
				morphBaseCost = 30,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynsupport2_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 20,
				morphBaseCost = 30,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynsupport3_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotType = "weapon",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 20,
				morphBaseCost = 30,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynsupport4_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 20,
				morphBaseCost = 30,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynsupport5_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
		}
	},
	{
		name = "assault",
		humanName = "Guardian",
		baseUnitDef = UnitDefNames and UnitDefNames["dynassault0"].id,
		levelDefs = {
			{
				morphBuildPower = 10,
				morphBaseCost = 20,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynassault1_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotType = "weapon",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 15,
				morphBaseCost = 30,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynassault2_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 20,
				morphBaseCost = 30,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynassault3_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.commweapon_beamlaser,
						slotType = "weapon",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 20,
				morphBaseCost = 30,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynassault4_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 20,
				morphBaseCost = 30,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["dynassault5_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.nullmodule,
						slotType = "module",
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

-- Find the empty modules
-- This table is both by slotType and by moduleDefID
local emptyModules = {}
for i = 1, #moduleDefs do
	if moduleDefs[i].name == "nullmodule" then
		emptyModules.module = i
		emptyModules[i] = true
	elseif moduleDefs[i].name == "nullweapon" then
		emptyModules.weapon = i
		emptyModules[i] = true
	end
end

-- Transform from human readable format into number indexed format
for i = 1, #moduleDefs do
	local data = moduleDefs[i]
	
	-- Required modules are a list of moduleDefIDs
	if data.requireModules then
		local newRequire = {}
		for j = 1, #data.requireModules do
			local reqModuleID = moduleDefNames[data.requireModules[j]]
			if reqModuleID then
				newRequire[#newRequire + 1] = reqModuleID
			end
		end
		data.requireModules = newRequire
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

if UnitDefNames then
	-- Create WeaponDefNames for each chassis
	for i = 1, #chassisDefs do
		local data = chassisDefs[i]
		local weapons = UnitDefs[data.baseUnitDef].weapons
		local chassisDefWeaponNames = {}
		for num = 1, #weapons do
			local wd = WeaponDefs[weapons[num].weaponDef]
			local weaponName = string.sub(wd.name, (string.find(wd.name,"_") or 0) + 1, 100)
			if weaponName then
				chassisDefWeaponNames[weaponName] = {
					num = num,
					weaponDefID = weapons[num].weaponDef,
					manualFire = (wd.customParams and wd.customParams.manualfire and true) or false
				}
			end
		end
		data.weaponDefNames = chassisDefWeaponNames
	end

	-- Add baseWreckID and baseHeapID
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

local function ModuleIsValid(level, chassis, slotType, moduleDefID, alreadyOwned, alreadyOwned2)
	local data = moduleDefs[moduleDefID]
	if data.slotType ~= slotType or (data.requireLevel or 0) > level or 
			(data.requireChassis and (not data.requireChassis[chassis])) or data.unequipable then
		return false
	end
	
	-- Check that requirements are met
	if data.requireModules then
		for j = 1, #data.requireModules do
			-- Modules should not depend on themselves so this check is simplier than the
			-- corresponding chcek in the replacement set generator.
			local reqDefID = data.requireModules[j]
			if not (alreadyOwned[reqDefID] or (alreadyOwned2 and alreadyOwned2[reqDefID])) then
				return false
			end
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

local utilities = {
	ModuleIsValid = ModuleIsValid,
	ModuleSetsAreIdentical = ModuleSetsAreIdentical,
	ModuleListToByDefID = ModuleListToByDefID,
}

------------------------------------------------------------------------
-- Return Values
------------------------------------------------------------------------

return moduleDefs, emptyModules, chassisDefs, utilities, chassisDefByBaseDef, moduleDefNames, chassisDefNames