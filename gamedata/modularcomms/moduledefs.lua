--------------------------------------------------------------------------------
-- system functions
--------------------------------------------------------------------------------

VFS.Include("gamedata/modularcomms/functions.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

weapons = {}

local weaponsList = VFS.DirList("gamedata/modularcomms/weapons", "*.lua") or {}
for i=1,#weaponsList do
	local name, array = VFS.Include(weaponsList[i])
	weapons[name] = lowerkeys(array)
end

-- name is needed for widget; description is currently unused
upgrades = {
	-- weapons
	-- note that context menu CRASHES if you don't put them here!
	
	commweapon_peashooter = {
		name = "Peashooter",
		description = "Basic self-defense weapon",
	},

	commweapon_assaultcannon = {
		name = "Assault Cannon",
		description = "Conventional plasma cannon with decent range",
	},	
	commweapon_beamlaser = {
		name = "Beam Laser",
		description = "An effective short-range cutting tool",
	},
	commweapon_flamethrower = {
		name = "Flamethrower",
		description = "Perfect for well-done barbecues",
	},
	commweapon_gaussrifle = {
		name = "Gauss Rifle",
		description = "Precise armor-piercing weapon",
	},
	commweapon_heavymachinegun = {
		name = "Heavy Machine Gun",
		description = "Close-in automatic weapon with AoE",
	},
	commweapon_heatray = {
		name = "Heat Ray",
		description = "Rapidly melts anything at short range; loses damage over distance",
	},
	commweapon_lightninggun = {
		name = "Lightning Gun",
		description = "Paralyzes and damages annoying bugs",
	},
	commweapon_lparticlebeam = {
		name = "Light Particle Beam",
		description = "Fires rapid medium-range pulses",
	},	
	commweapon_missilelauncher = {
		name = "Missile Launcher",
		description = "Fires light seeker missiles",
		func = function(unitDef)
				unitDef.customparams.nofps = "1"
			end,		
	},
	commweapon_partillery = {
		name = "Plasma Artillery",
		description = "Long-range artillery gun",
	},
	commweapon_riotcannon = {
		name = "Riot Cannon",
		description = "The weapon of choice for crowd control",
	},
	commweapon_rocketlauncher = {
		name = "Rocket Launcher",
		description = "Medium-range low-velocity hitter",
		func = function(unitDef)
				unitDef.customparams.nofps = "1"
			end,	
	},
	commweapon_shotgun = {
		name = "Shotgun",
		description = "Can hammer a single large target or shred many small ones",
	},
	commweapon_slowbeam = {
		name = "Slowing Beam",
		description = "Slows an enemy's movement and firing rate; non-lethal",
	},
	
	-- dguns
	commweapon_concussion = {
		name = "Concussion Shot",
		description = "Extended range weapon with AoE and impulse",
	},
	commweapon_clusterbomb = {
		name = "Cluster Bomb",
		description = "Hammers multiple units in a wide line",
	},
	commweapon_disintegrator = {
		name = "Disintegrator Gun",
		description = "Short-range weapon that vaporizes anything in its path",
	},
	commweapon_disruptorbomb = {
		name = "Disruptor Bomb",
		description = "Damages and slows units in a large area",
	},
	commweapon_napalmgrenade = {
		name = "Hellfire Grenade",
		description = "Sets a moderate area ablaze",
	},		
	commweapon_sunburst = {
		name = "Sunburst Cannon",
		description = "Ruins a single target's day with a medium-range high-energy burst",
	},
	
	-- conversion kits
	conversion_disruptor = {
		name = "Disruptor Beam",
		description = "Slow Beam: +33% reload time, +250 real damage",
		func = function(unitDef)
				ReplaceWeapon(unitDef, "commweapon_slowbeam", "commweapon_disruptor")
			end,	
	},
	conversion_shockrifle = {
		name = "Shock Rifle",
		description = "Gauss Rifle: Convert to a long-range sniper rifle",
		func = function(unitDef)
				ReplaceWeapon(unitDef, "commweapon_gaussrifle", "commweapon_shockrifle")
			end,	
	},
	conversion_partillery = {
		name = "Plasma Artillery",
		description = "Assault Cannon: Convert to a light artillery gun",
		func = function(unitDef)
				ReplaceWeapon(unitDef, "commweapon_assaultcannon", "commweapon_partillery")
				--unitDef.hightrajectory = 1
			end,	
	},		
	
	-- weapon mods
	weaponmod_autoflechette = {
		name = "Autoflechette",
		description = "Shotgun: -25% projectiles, -40% reload time",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				for i,v in pairs(weapons) do
					if i == "commweapon_shotgun" then
						v.customparams.misceffect = nil
						v.projectiles = v.projectiles * 0.75
						v.reloadtime = v.reloadtime * 0.6
						v.customparams.basereload = v.reloadtime
						--break
					end
				end
			end,	
	},
	weaponmod_disruptor_ammo = {
		name = "Disruptor Ammo",
		description = "Shotgun/Gauss Rifle/Heavy Machine Gun/Shock Rifle: +40% slow damage",
		func = function(unitDef)
				local permitted = {
					commweapon_shotgun = true,
					commweapon_gaussrifle = true,
					commweapon_heavymachinegun = true,
					commweapon_shockrifle = true,
				}
				local weapons = unitDef.weapondefs or {}
				for i,v in pairs(weapons) do
					local wcp = v.customparams
					if permitted[i] then
						wcp.timeslow_damagefactor = "0.4"
						v.rgbcolor = [[0.9 0.1 0.9]]
						if i == "commweapon_shotgun" or i == "commweapon_heavymachinegun" then
							v.explosiongenerator = [[custom:BEAMWEAPON_HIT_PURPLE]]
						elseif i == "commweapon_gaussrifle" then
							v.explosiongenerator = [[custom:GAUSS_HIT_M_PURPLE]]
						elseif i == "commweapon_shockrifle" then
							--v.rgbcolor = [[0.1 0.65 0.9]]
							--v.explosiongenerator = [[custom:BURNTEAL]]
						end
					end
				end
			end,	
	},
	weaponmod_high_frequency_beam = {
		name = "High Frequency Beam",
		description = "Beam Laser/Slow Beam/Disruptor Beam: +15% damage and range",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				local permitted = {
					commweapon_beamlaser = true,
					commweapon_slowbeam = true,
					commweapon_disruptor = true,
				}
				for i,v in pairs(weapons) do
					if permitted[i] then
						v.range = v.range * 1.15
						v.customparams.baserange = v.range
						for armorname, dmg in pairs(v.damage) do
							v.damage[armorname] = dmg * 1.15
							v.customparams["basedamage_"..armorname] = tostring(v.damage[armorname])
						end
					end
				end
			end,		
	},
	weaponmod_high_caliber_barrel = {
		name = "High Caliber Barrel",
		description = "Shotgun/Riot Cannon/Gauss Rifle/Assault Cannon/Plasma Artillery: +150% damage, +100% reload time",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				local permitted = {
					commweapon_assaultcannon = true,
					commweapon_shotgun = true,
					commweapon_gaussrifle = true,
					commweapon_partillery = true,
					commweapon_riotcannon = true,
				}
				for i,v in pairs(weapons) do
					if permitted[i] then
						if not (i == "commweapon_partillery" or i == "commweapon_partillery_napalm") then
							v.reloadtime = v.reloadtime * 2
							v.customparams.basereload = v.reloadtime
							v.customparams.highcaliber = true
							for armorname, dmg in pairs(v.damage) do
								v.damage[armorname] = dmg * 2.5
								v.customparams["basedamage_"..armorname] = tostring(v.damage[armorname])
							end
						else
							ReplaceWeapon(unitDef, "commweapon_partillery", "commweapon_hpartillery")
							ReplaceWeapon(unitDef, "commweapon_partillery", "commweapon_hpartillery")
							ReplaceWeapon(unitDef, "commweapon_partillery_napalm", "commweapon_hpartillery_napalm")
							ReplaceWeapon(unitDef, "commweapon_partillery_napalm", "commweapon_hpartillery_napalm")						
						end
					end
				end
			end,		
	},
	weaponmod_standoff_rocket = {
		name = "Standoff Rocket",
		description = "Rocket/Missile Launcher: +50% range, +25% damage, +50% reload time",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				for i,v in pairs(weapons) do
					if i == "commweapon_rocketlauncher" then
						v.range = v.range * 1.5
						v.customparams.baserange = v.range
						v.reloadtime = v.reloadtime * 1.5
						v.customparams.basereload = v.reloadtime
						for armorname, dmg in pairs(v.damage) do
							v.damage[armorname] = dmg * 1.25
							v.customparams["basedamage_"..armorname] = tostring(v.damage[armorname])
						end						
						v.model = [[wep_m_dragonsfang.s3o]]
						v.soundhitvolume = 8
						v.soundstart = [[weapon/missile/missile2_fire_bass]]
						v.soundstartvolume = 7					
						--break
					elseif i == "commweapon_missilelauncher" then
						v.range = v.range * 1.5
						v.customparams.baserange = v.range
						v.reloadtime = v.reloadtime * 1.5
						v.customparams.basereload = v.reloadtime
						for armorname, dmg in pairs(v.damage) do
							v.damage[armorname] = dmg * 1.25
							v.customparams["basedamage_"..armorname] = tostring(v.damage[armorname])
						end						
						v.model = [[wep_m_phoenix.s3o]]
						v.soundhitvolume = 5
						v.soundstart = [[weapon/missile/missile_fire7]]
						v.soundstartvolume = 3							
					end
				end
			end,	
	},
	weaponmod_stun_booster = {
		name = "Flux Amplifier",
		description = "Lightning Gun: +25% paralyze damage, +2s paralyzetime",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				for i,v in pairs(weapons) do
					if i == "commweapon_lightninggun" then
						for armorname, dmg in pairs(v.damage) do
							v.damage[armorname] = dmg * 1.25
							v.customparams["basedamage_"..armorname] = tostring(v.damage[armorname])
						end
						v.customparams["extra_damage_mult"] = 0.32	-- same real damage
						v.paralyzetime = 3
					end
				end
			end,	
	},
	weaponmod_napalm_warhead = {
		name = "Napalm Warhead",
		description = "Riot Cannon/Plasma Artillery/Rocket Launcher: Reduced direct damage, sets target on fire",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				local permitted = {
					commweapon_partillery = true,
					commweapon_hpartillery = true,
					commweapon_rocketlauncher = true,
					commweapon_riotcannon = true,
				}
				for i,v in pairs(weapons) do
					if permitted[i] then
						if (i == "commweapon_riotcannon") then	-- -20% damage
							for armorname, dmg in pairs(v.damage) do
								v.damage[armorname] = dmg * 0.8
								v.customparams["basedamage_"..armorname] = tostring(v.damage[armorname])
							end
							v.customparams.burntime = "420"
							v.rgbcolor = [[1 0.3 0.1]]
						elseif (i == "commweapon_hpartillery") then	-- -90% damage, 256 AoE, firewalker effect
							ReplaceWeapon(unitDef, "commweapon_hpartillery", "commweapon_hpartillery_napalm")
							ReplaceWeapon(unitDef, "commweapon_hpartillery", "commweapon_hpartillery_napalm")
						elseif (i == "commweapon_partillery") then	-- -25% damage, 128 AoE
							ReplaceWeapon(unitDef, "commweapon_partillery", "commweapon_partillery_napalm")
							ReplaceWeapon(unitDef, "commweapon_partillery", "commweapon_partillery_napalm")
						else	-- -25% damage, 128 AoE
							for armorname, dmg in pairs(v.damage) do
								v.damage[armorname] = dmg * 0.75
								v.customparams["basedamage_"..armorname] = tostring(v.damage[armorname])
							end
							v.customparams.burntime = "450"
							v.areaofeffect = 128
						end
						
						if (i == "commweapon_riotcannon") or (i == "commweapon_rocketlauncher") then
							v.explosiongenerator = [[custom:NAPALM_Expl]]
							v.customparams.burnchance = "1"
							v.soundhit = [[weapon/burn_mixed]]
						end
						v.customparams.setunitsonfire = "1"
					end
				end
			end,		
	},
	weaponmod_plasma_containment = {
		name = "Plasma Containment Field",
		description = "Heat Ray/Riot Cannon: +30% range",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				for i,v in pairs(weapons) do
					if i == "commweapon_heatray" then
						v.range = v.range * 1.3
						v.customparams.baserange = tostring(v.range)
					elseif i == "commweapon_riotcannon" then
						v.range = v.range * 1.3
						v.customparams.baserange = tostring(v.range)
					end
				end
			end,	
	},	
	
	-- modules
	module_ablative_armor = {
		name = "Ablative Armor Plates",
		description = "Adds 600 HP",
		func = function(unitDef)
				unitDef.maxdamage = unitDef.maxdamage + 600
			end,
	},
	module_adv_targeting = {
		name = "Advanced Targeting System",
		description = "Extends range of all weapons by 10%",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				for i,v in pairs(weapons) do
					if v.range then v.range = v.range + (v.customparams.baserange or v.range) * 0.1 end
				end
			end,	
	},
	module_adv_nano = {
		name = "CarRepairer's Nanolathe",
		description = "Adds +6 metal/s build speed",
		func = function(unitDef)
				if unitDef.workertime then unitDef.workertime = unitDef.workertime + 6 end
				--if unitDef.builddistance then unitDef.builddistance = unitDef.builddistance + 60 end
			end,
	},
	module_autorepair = {
		name = "Autorepair System",
		description = "Self-repairs 20 HP/s",
		func = function(unitDef)
				unitDef.autoheal = (unitDef.autoheal or 0) + 20
			end,
	},
	module_companion_drone = {
		name = "Companion Drone",
		description = "Spawns a pair of attack drones",
		func = function(unitDef)
				unitDef.customparams.drone_preset = "module_companion_drone"
			end,
	},	
	module_dmg_booster = {
		name = "Damage Booster",
		description = "Increases damage of all weapons by 10%",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				for i,v in pairs(weapons) do
					for armorname, dmg in pairs(v.damage) do
						v.damage[armorname] = dmg + (v.customparams["basedamage_"..armorname] or dmg) * 0.1
					end
				end
			end,	
	},
	module_energy_cell = {
		name = "Energy Cell",
		description = "Compact fuel cells that produce +6 energy",
		func = function(unitDef)
				unitDef.energymake = (unitDef.energymake or 0) + 6
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
	module_heavy_armor = {
		name = "High Density Plating",
		description = "Adds 1600 HP, slows comm by +10%",
		func = function(unitDef, attributeMods)
				unitDef.maxdamage = unitDef.maxdamage + 1600
				attributeMods.speed = attributeMods.speed - 0.1
			end,
	},
	module_high_power_servos = {
		name = "High Power Servos",
		description = "More powerful leg actuators increase speed by 10% of base",
		func = function(unitDef, attributeMods)
				attributeMods.speed = attributeMods.speed + 0.1
			end,
	},
	module_personal_cloak = {
		name = "Personal Cloak",
		description = "Cloaks the commander",
		func = function(unitDef) 
				unitDef.cloakcost = unitDef.cloakcost or 5
				unitDef.mincloakdistance = math.max(150, unitDef.mincloakdistance or 0)
				if unitDef.cloakcost > 5 then 
					unitDef.cloakcost = 5 
				end
				unitDef.cloakcostmoving = unitDef.cloakcostmoving or 10
				if unitDef.cloakcostmoving > 10 then 
					unitDef.cloakcostmoving = 10 
				end
			end
		,
	},
	module_personal_shield = {
		name = "Personal Shield",
		description = "Generates a small bubble shield",
		func = function(unitDef)
				ApplyWeapon(unitDef, "commweapon_personal_shield", 4)
				unitDef.activatewhenbuilt = true
			end,
	},
	module_resurrect = {
		name = "Lazarus Device",
		description = "Enables resurrection of wrecks",
		func = function(unitDef)
				unitDef.canresurrect = true
			end,
	},
	
	module_areashield = {
		name = "Area Shield",
		description = "Bubble shield that protects surrounding units within 300 m",
		func = function(unitDef)
				ApplyWeapon(unitDef, "commweapon_areashield", 2)
				unitDef.activatewhenbuilt = true
				unitDef.customparams.lups_unit_fxs = unitDef.customparams.lups_unit_fxs or {}
				table.insert(unitDef.customparams.lups_unit_fxs, "commShield")
			end,
	},	
	module_cloak_field = {
		name = "Cloaking Field",
		description = "Cloaks all friendly units within 350 m",
		func = function(unitDef)
				unitDef.mincloakdistance = math.max(150, unitDef.mincloakdistance or 0)
				unitDef.onoffable = true
				unitDef.radarDistanceJam = (unitDef.radarDistanceJam and unitDef.radarDistanceJam > 350 and unitDef.radarDistanceJam) or 350
				unitDef.customparams.cloakshield_preset = "module_cloakfield"
			end,
	},
	module_jammer = {
		name = "Radar Jammer",
		description = "Masks radar signals of all units within 500 m",
		func = function(unitDef)
				unitDef.radardistancejam = 500
				unitDef.activatewhenbuilt = true
				unitDef.onoffable = true
			end,
	},
	module_jump_booster = {
		name = "Dragonfly Booster",
		description = "Increases jump range and height",
		func = function(unitDef)
				unitDef.customparams.jumpclass = "commrecon2"
			end,	
	},
	module_radarnet = {
		name = "Integrated Radar Network",
		description = "Reduces radar wobble for all units",
		func = function(unitDef)
				unitDef.isTargetingUpgrade = true
				unitDef.activatewhenbuilt = true
		end,
	}, 
	
	-- deprecated
	module_improved_optics = {
		name = "Improved Optics",
		description = "Increases sight distance by 100 m",
		func = function(unitDef)
				unitDef.sightdistance = unitDef.sightdistance + 100
			end,
	},
	module_repair_field = {
		name = "Repair Field",
		description = "Passively repairs all friendly units within 450 m",
		func = function(unitDef)
				unitDef.customparams.repairaura_preset = "module_repairfield"
			end,
	},
}

