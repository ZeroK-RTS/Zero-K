local base = {
	--[[
	{
		name = "rocket",
		modules = {
			"commweapon_rocketlauncher",
			"commweapon_slamrocket",
			"weaponmod_standoff_rocket",
			"weaponmod_napalm_warhead",
			"module_adv_targeting",
			"module_adv_targeting",
			"module_adv_targeting",
			"module_adv_targeting",
			"module_adv_targeting",
			"module_adv_targeting"
		}
	},
	{
		name = "aa",
		modules = {
			"commweapon_missilelauncher",
			"commweapon_beamlaser",
			"weaponmod_antiair",
			"module_resurrect",
		}
	},
	{
		name = "gauss",
		modules = {
			"commweapon_gaussrifle",
			"commweapon_concussion",
			"conversion_shockrifle",
			"module_personal_shield",
			"module_personal_cloak",
			"module_areashield",
			"module_adv_targeting",
			"weaponmod_disruptor_ammo",
		},
	},
	{
		name = "arty",
		modules = {
			"commweapon_assaultcannon",
			"commweapon_assaultcannon",
			"conversion_partillery",
			"weaponmod_napalm_warhead",
			"weaponmod_high_caliber_barrel"
		}
	},
	{
		name = "hmg",
		modules = {
			"commweapon_heavymachinegun_lime",
			"commweapon_disruptorbomb",
			"weaponmod_disruptor_ammo",
		},
	},
	{
		name = "shotty",
		modules = {
			"commweapon_shotgun_green", 
			"weaponmod_autoflechette",
			"commweapon_napalmgrenade",
			"module_companion_drone",
			"weaponmod_disruptor_ammo",
		},
	},
	{
		name = "beam",
		modules = {
			"commweapon_beamlaser_green",
			"commweapon_beamlaser_red",
			"conversion_lazor",
			"module_guardian_armor",
			"module_superspeed",
			"module_super_nano",
			"module_ablative_armor",
			"module_dmg_booster",
		}
	},
	{
		name = "lightning",
		modules = {
			"commweapon_lightninggun",
			"module_high_power_servos",
			"weaponmod_stun_booster",
			"commweapon_multistunner",
			"module_high_power_servos",
			"module_high_power_servos",
			"module_high_power_servos",
			"module_high_power_servos",
			"module_high_power_servos",
			"module_high_power_servos",
		}
	},
	{
		name = "flame",
		modules = {
			"commweapon_partillery",
			"commweapon_flamethrower",
			"weaponmod_high_caliber_barrel",
			"weaponmod_napalm_warhead",
			"weaponmod_flame_enhancer",
			"module_dmg_booster",
			"module_dmg_booster",
		}
	},
	{
		name = "drone",
		modules = {
			"commweapon_beamlaser_green",
			"commweapon_beamlaser_red",
			"conversion_lazor",
			"module_guardian_armor",
			"module_superspeed",
			"module_super_nano",
			"module_dmg_booster",
			"module_companion_drone",
			"module_companion_drone",
			"module_companion_drone",
			"module_companion_drone",
		}
	},
	{
		name = "doubleshield",
		modules = {
			"commweapon_riotcannon",
			"commweapon_riotcannon",
			"module_energy_cell",
			"module_energy_cell",
			"module_energy_cell",
 			"module_personal_shield",
			"module_areashield",
		},
	},
	]]
}

local ret = {count = 0}

local chassis = {
	{
		name = "c4_",
		value = "corcom4",
	},
	{
		name = "a4_",
		value = "armcom4",
	},
	{
		name = "s4_",
		value = "commsupport4",
	},
	{
		name = "r4_",
		value = "commrecon4",
	},
	{
		name = "c1_",
		value = "corcom1",
	},
	{
		name = "a1_",
		value = "armcom1",
	},
	{
		name = "s1_",
		value = "commsupport1",
	},
	{
		name = "r1_",
		value = "commrecon1",
	},
	{
		name = "cr1_",
		value = "cremcom1",
	},
	{
		name = "cr4_",
		value = "cremcom4",
	},
	{
		name = "b1_",
		value = "benzcom1",
	},
	{
		name = "b4_",
		value = "benzcom4",
	},
	
}

for i = 1, #chassis do
	for j = 1, #base do
		ret.count = ret.count + 1
		ret[ret.count] = {}
		ret[ret.count].modules = base[j].modules
		ret[ret.count].decorations = base[j].decorations
		ret[ret.count].chassis = chassis[i].value
		ret[ret.count].name = "test_" .. chassis[i].name .. base[j].name
	end
end

return ret

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- example of modoption data
--[[
Y29tbWFuZGVycyA9IHsNCiAgYzU4MDZfMjQzID0gew0KICAgIG5hbWUgPSAiUHJpbmNlc3MgTHVuYSINCiAgICBjaGFzc2lzID0gImFybWNvbSIsDQogICAgbW9kdWxlcyA9IHsNCiAgICAgIHsiY29tbXdlYXBvbl9saWdodG5pbmdndW4iLCJtb2R1bGVfZmllbGRyYWRhciJ9LA0KICAgICAgeyJtb2R1bGVfYWJsYXRpdmVfYXJtb3IiLCJtb2R1bGVfcGVyc29uYWxfY2xvYWsifSwNCiAgICAgIHsibW9kdWxlX2FibGF0aXZlX2FybW9yIiwid2VhcG9ubW9kX3N0dW5fYm9vc3RlciJ9LA0KICAgICAgeyJtb2R1bGVfaGlnaF9wb3dlcl9zZXJ2b3MiLCJtb2R1bGVfaGVhdnlfYXJtb3IifSwNCiAgICAgIHt9DQogICAgfSwNCiAgICBkZWNvcmF0aW9ucyA9IHsic2hpZWxkX2JsdWUifSwNCiAgfSwNCn0=

{
  c5806_243 = {
    name = "Princess Luna",
    chassis = "cremcom",
    modules = {
      {"commweapon_lightninggun","module_fieldradar"},
      {"module_ablative_armor","module_personal_cloak"},
      {"commweapon_disintegrator", "module_ablative_armor", "weaponmod_stun_booster"},
      {"module_high_power_servos","module_heavy_armor"},
      {}
    },
    decorations = {"shield_blue"},
  },
}

-- player data
eyJjNTgwNl8yNDMifQ==

{"c5806_243"}
]]--
