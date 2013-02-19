local base = {
	{
		name = "rocket",
		modules = {
			"commweapon_missilelauncher",
			"commweapon_clusterbomb",
			"weaponmod_standoff_rocket",
			"module_adv_targeting",
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
		}
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
			"commweapon_heavymachinegun",
			"commweapon_disruptorbomb",
			"module_autorepair",
			"module_autorepair",
			"module_autorepair",
			"module_autorepair",
			"module_autorepair",
			"module_autorepair",
			"module_autorepair",
			"module_autorepair",
		}
	},
	{
		name = "shotty",
		modules = {
			"commweapon_shotgun", 
			"weaponmod_autoflechette",
			"commweapon_napalmgrenade",
			"module_companion_drone",
		}
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
			"commweapon_sunburst",
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
			"commweapon_flamethrower",
			"commweapon_flamethrower",
			"module_dmg_booster",
			"module_dmg_booster",
		}
	},
	
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
		ret[ret.count].chassis = chassis[i].value
		ret[ret.count].name = "test_" .. chassis[i].name .. base[j].name
	end
end

return ret

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--[[
-- example of modoption data
ewogIGM1MzgzXzU1MTRfMCA9IHsKICAgIGNoYXNzaXMgPSAiY29yY29tMSIsCiAgICBtb2R1bGVzID0ge30sCiAgICBjb3N0ID0gMCwKICAgIG5hbWUgPSAiU2VhY29tIGxldmVsIDAiCiAgfSwKICBjNTM4M181NTE0XzEgPSB7CiAgICBjaGFzc2lzID0gImNvcmNvbTEiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25fdG9ycGVkbyIsCiAgICAgICJtb2R1bGVfZW5lcmd5X2NlbGwiCiAgICB9LAogICAgY29zdCA9IDI4MCwKICAgIG5hbWUgPSAiU2VhY29tIGxldmVsIDEiCiAgfSwKICBjNTM4M181NTE0XzIgPSB7CiAgICBjaGFzc2lzID0gImNvcmNvbTIiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25fdG9ycGVkbyIsCiAgICAgICJtb2R1bGVfZW5lcmd5X2NlbGwiLAogICAgICAibW9kdWxlX2Fkdl9uYW5vIiwKICAgICAgIm1vZHVsZV9yZXN1cnJlY3QiCiAgICB9LAogICAgY29zdCA9IDk4MCwKICAgIG5hbWUgPSAiU2VhY29tIGxldmVsIDIiCiAgfSwKICBjNTM4M181NTE0XzMgPSB7CiAgICBjaGFzc2lzID0gImNvcmNvbTMiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25fdG9ycGVkbyIsCiAgICAgICJjb21td2VhcG9uX3RvcnBlZG8iLAogICAgICAibW9kdWxlX2VuZXJneV9jZWxsIiwKICAgICAgIm1vZHVsZV9hZHZfbmFubyIsCiAgICAgICJtb2R1bGVfcmVzdXJyZWN0IiwKICAgICAgIm1vZHVsZV9hZHZfbmFubyIsCiAgICAgICJtb2R1bGVfYWR2X25hbm8iCiAgICB9LAogICAgY29zdCA9IDIyODAsCiAgICBuYW1lID0gIlNlYWNvbSBsZXZlbCAzIgogIH0sCiAgYzUzODNfNTUxNF80ID0gewogICAgY2hhc3NpcyA9ICJjb3Jjb200IiwKICAgIG1vZHVsZXMgPSB7CiAgICAgICJjb21td2VhcG9uX3RvcnBlZG8iLAogICAgICAiY29tbXdlYXBvbl90b3JwZWRvIiwKICAgICAgIm1vZHVsZV9lbmVyZ3lfY2VsbCIsCiAgICAgICJtb2R1bGVfYWR2X25hbm8iLAogICAgICAibW9kdWxlX3Jlc3VycmVjdCIsCiAgICAgICJtb2R1bGVfYWR2X25hbm8iLAogICAgICAibW9kdWxlX2Fkdl9uYW5vIiwKICAgICAgIm1vZHVsZV9hcmVhc2hpZWxkIiwKICAgICAgIm1vZHVsZV9wZXJzb25hbF9zaGllbGQiLAogICAgICAibW9kdWxlX2Fkdl9uYW5vIgogICAgfSwKICAgIGNvc3QgPSAzNjMwLAogICAgbmFtZSA9ICJTZWFjb20gbGV2ZWwgNCIKICB9LAogIGM1MzgzXzU1MTNfMCA9IHsKICAgIGNoYXNzaXMgPSAiY29yY29tMSIsCiAgICBtb2R1bGVzID0ge30sCiAgICBjb3N0ID0gMCwKICAgIG5hbWUgPSAiRW5lcmNvbiBsZXZlbCAwIgogIH0sCiAgYzUzODNfNTUxM18xID0gewogICAgY2hhc3NpcyA9ICJjb3Jjb20xIiwKICAgIG1vZHVsZXMgPSB7CiAgICAgICJjb21td2VhcG9uX2JlYW1sYXNlciIsCiAgICAgICJtb2R1bGVfZW5lcmd5X2NlbGwiCiAgICB9LAogICAgY29zdCA9IDIzMCwKICAgIG5hbWUgPSAiRW5lcmNvbiBsZXZlbCAxIgogIH0sCiAgYzUzODNfNTUxM18yID0gewogICAgY2hhc3NpcyA9ICJjb3Jjb20yIiwKICAgIG1vZHVsZXMgPSB7CiAgICAgICJjb21td2VhcG9uX2JlYW1sYXNlciIsCiAgICAgICJtb2R1bGVfZW5lcmd5X2NlbGwiLAogICAgICAibW9kdWxlX2Fkdl9uYW5vIiwKICAgICAgIm1vZHVsZV9hZHZfbmFubyIKICAgIH0sCiAgICBjb3N0ID0gODMwLAogICAgbmFtZSA9ICJFbmVyY29uIGxldmVsIDIiCiAgfSwKICBjNTM4M181NTEzXzMgPSB7CiAgICBjaGFzc2lzID0gImNvcmNvbTMiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25fYmVhbWxhc2VyIiwKICAgICAgImNvbW13ZWFwb25fcmlvdGNhbm5vbiIsCiAgICAgICJtb2R1bGVfZW5lcmd5X2NlbGwiLAogICAgICAibW9kdWxlX2Fkdl9uYW5vIiwKICAgICAgIm1vZHVsZV9hZHZfbmFubyIsCiAgICAgICJtb2R1bGVfYWR2X25hbm8iLAogICAgICAibW9kdWxlX2Fkdl9uYW5vIgogICAgfSwKICAgIGNvc3QgPSAyMTMwLAogICAgbmFtZSA9ICJFbmVyY29uIGxldmVsIDMiCiAgfSwKICBjNTM4M181NTEzXzQgPSB7CiAgICBjaGFzc2lzID0gImNvcmNvbTQiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25fYmVhbWxhc2VyIiwKICAgICAgImNvbW13ZWFwb25fcmlvdGNhbm5vbiIsCiAgICAgICJtb2R1bGVfZW5lcmd5X2NlbGwiLAogICAgICAibW9kdWxlX2Fkdl9uYW5vIiwKICAgICAgIm1vZHVsZV9hZHZfbmFubyIsCiAgICAgICJtb2R1bGVfYWR2X25hbm8iLAogICAgICAibW9kdWxlX2Fkdl9uYW5vIiwKICAgICAgIm1vZHVsZV9hZHZfbmFubyIsCiAgICAgICJtb2R1bGVfYWR2X25hbm8iLAogICAgICAibW9kdWxlX2Fkdl9uYW5vIgogICAgfSwKICAgIGNvc3QgPSAzMDMwLAogICAgbmFtZSA9ICJFbmVyY29uIGxldmVsIDQiCiAgfSwKICBjNTM4M181NTEyXzAgPSB7CiAgICBjaGFzc2lzID0gImNvbW1yZWNvbjEiLAogICAgbW9kdWxlcyA9IHt9LAogICAgY29zdCA9IDAsCiAgICBuYW1lID0gIkVuZXJqdW1wIGxldmVsIDAiCiAgfSwKICBjNTM4M181NTEyXzEgPSB7CiAgICBjaGFzc2lzID0gImNvbW1yZWNvbjEiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25fYmVhbWxhc2VyIiwKICAgICAgIm1vZHVsZV9lbmVyZ3lfY2VsbCIKICAgIH0sCiAgICBjb3N0ID0gMjMwLAogICAgbmFtZSA9ICJFbmVyanVtcCBsZXZlbCAxIgogIH0sCiAgYzUzODNfNTUxMl8yID0gewogICAgY2hhc3NpcyA9ICJjb21tcmVjb24yIiwKICAgIG1vZHVsZXMgPSB7CiAgICAgICJjb21td2VhcG9uX2JlYW1sYXNlciIsCiAgICAgICJtb2R1bGVfZW5lcmd5X2NlbGwiLAogICAgICAibW9kdWxlX2Fkdl9uYW5vIiwKICAgICAgIm1vZHVsZV9hZHZfbmFubyIKICAgIH0sCiAgICBjb3N0ID0gODMwLAogICAgbmFtZSA9ICJFbmVyanVtcCBsZXZlbCAyIgogIH0sCiAgYzUzODNfNTUxMl8zID0gewogICAgY2hhc3NpcyA9ICJjb21tcmVjb24zIiwKICAgIG1vZHVsZXMgPSB7CiAgICAgICJjb21td2VhcG9uX2JlYW1sYXNlciIsCiAgICAgICJjb21td2VhcG9uX2hlYXRyYXkiLAogICAgICAibW9kdWxlX2VuZXJneV9jZWxsIiwKICAgICAgIm1vZHVsZV9hZHZfbmFubyIsCiAgICAgICJtb2R1bGVfYWR2X25hbm8iLAogICAgICAibW9kdWxlX2Fkdl9uYW5vIiwKICAgICAgIm1vZHVsZV9hZHZfbmFubyIKICAgIH0sCiAgICBjb3N0ID0gMjEzMCwKICAgIG5hbWUgPSAiRW5lcmp1bXAgbGV2ZWwgMyIKICB9LAogIGM1MzgzXzU1MTJfNCA9IHsKICAgIGNoYXNzaXMgPSAiY29tbXJlY29uNCIsCiAgICBtb2R1bGVzID0gewogICAgICAiY29tbXdlYXBvbl9iZWFtbGFzZXIiLAogICAgICAiY29tbXdlYXBvbl9oZWF0cmF5IiwKICAgICAgIm1vZHVsZV9lbmVyZ3lfY2VsbCIsCiAgICAgICJtb2R1bGVfYWR2X25hbm8iLAogICAgICAibW9kdWxlX2Fkdl9uYW5vIiwKICAgICAgIm1vZHVsZV9hZHZfbmFubyIsCiAgICAgICJtb2R1bGVfYWR2X25hbm8iLAogICAgICAibW9kdWxlX2Fkdl9uYW5vIiwKICAgICAgIm1vZHVsZV9hZHZfbmFubyIsCiAgICAgICJtb2R1bGVfYWR2X25hbm8iCiAgICB9LAogICAgY29zdCA9IDMwMzAsCiAgICBuYW1lID0gIkVuZXJqdW1wIGxldmVsIDQiCiAgfSwKICBjNTM4M185NTU5XzAgPSB7CiAgICBjaGFzc2lzID0gImNvbW1yZWNvbjEiLAogICAgbW9kdWxlcyA9IHt9LAogICAgY29zdCA9IDAsCiAgICBuYW1lID0gIkZpcmVqdW1wIGxldmVsIDAiCiAgfSwKICBjNTM4M185NTU5XzEgPSB7CiAgICBjaGFzc2lzID0gImNvbW1yZWNvbjEiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25faGVhdnltYWNoaW5lZ3VuIiwKICAgICAgIm1vZHVsZV9lbmVyZ3lfY2VsbCIKICAgIH0sCiAgICBjb3N0ID0gMzA1LAogICAgbmFtZSA9ICJGaXJlanVtcCBsZXZlbCAxIgogIH0sCiAgYzUzODNfOTU1OV8yID0gewogICAgY2hhc3NpcyA9ICJjb21tcmVjb24yIiwKICAgIG1vZHVsZXMgPSB7CiAgICAgICJjb21td2VhcG9uX2hlYXZ5bWFjaGluZWd1biIsCiAgICAgICJtb2R1bGVfZW5lcmd5X2NlbGwiLAogICAgICAibW9kdWxlX2F1dG9yZXBhaXIiLAogICAgICAibW9kdWxlX3BlcnNvbmFsX2Nsb2FrIgogICAgfSwKICAgIGNvc3QgPSAxMTA1LAogICAgbmFtZSA9ICJGaXJlanVtcCBsZXZlbCAyIgogIH0sCiAgYzUzODNfOTU1OV8zID0gewogICAgY2hhc3NpcyA9ICJjb21tcmVjb24zIiwKICAgIG1vZHVsZXMgPSB7CiAgICAgICJjb21td2VhcG9uX2hlYXZ5bWFjaGluZWd1biIsCiAgICAgICJjb21td2VhcG9uX25hcGFsbWdyZW5hZGUiLAogICAgICAibW9kdWxlX2VuZXJneV9jZWxsIiwKICAgICAgIm1vZHVsZV9hdXRvcmVwYWlyIiwKICAgICAgIm1vZHVsZV9wZXJzb25hbF9jbG9hayIsCiAgICAgICJtb2R1bGVfYWJsYXRpdmVfYXJtb3IiLAogICAgICAibW9kdWxlX2Fkdl90YXJnZXRpbmciCiAgICB9LAogICAgY29zdCA9IDI0NTUsCiAgICBuYW1lID0gIkZpcmVqdW1wIGxldmVsIDMiCiAgfSwKICBjNTM4M185NTU5XzQgPSB7CiAgICBjaGFzc2lzID0gImNvbW1yZWNvbjQiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25faGVhdnltYWNoaW5lZ3VuIiwKICAgICAgImNvbW13ZWFwb25fbmFwYWxtZ3JlbmFkZSIsCiAgICAgICJtb2R1bGVfZW5lcmd5X2NlbGwiLAogICAgICAibW9kdWxlX2F1dG9yZXBhaXIiLAogICAgICAibW9kdWxlX3BlcnNvbmFsX2Nsb2FrIiwKICAgICAgIm1vZHVsZV9hYmxhdGl2ZV9hcm1vciIsCiAgICAgICJtb2R1bGVfYWR2X3RhcmdldGluZyIsCiAgICAgICJtb2R1bGVfYWR2X3RhcmdldGluZyIsCiAgICAgICJtb2R1bGVfYWR2X3RhcmdldGluZyIsCiAgICAgICJtb2R1bGVfYWR2X3RhcmdldGluZyIKICAgIH0sCiAgICBjb3N0ID0gMzM1NSwKICAgIG5hbWUgPSAiRmlyZWp1bXAgbGV2ZWwgNCIKICB9LAogIGM1ODA2XzI0M18wID0gewogICAgY2hhc3NpcyA9ICJhcm1jb20xIiwKICAgIG1vZHVsZXMgPSB7fSwKICAgIGNvc3QgPSAwLAogICAgbmFtZSA9ICJQcmluY2VzcyBMdW5hIGxldmVsIDAiCiAgfSwKICBjNTgwNl8yNDNfMSA9IHsKICAgIGNoYXNzaXMgPSAiYXJtY29tMSIsCiAgICBtb2R1bGVzID0gewogICAgICAiY29tbXdlYXBvbl9saWdodG5pbmdndW4iLAogICAgICAibW9kdWxlX2ZpZWxkcmFkYXIiCiAgICB9LAogICAgY29zdCA9IDE3NSwKICAgIG5hbWUgPSAiUHJpbmNlc3MgTHVuYSBsZXZlbCAxIgogIH0sCiAgYzU4MDZfMjQzXzIgPSB7CiAgICBjaGFzc2lzID0gImFybWNvbTIiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25fbGlnaHRuaW5nZ3VuIiwKICAgICAgIm1vZHVsZV9maWVsZHJhZGFyIiwKICAgICAgIm1vZHVsZV9hYmxhdGl2ZV9hcm1vciIKICAgIH0sCiAgICBjb3N0ID0gNjUwLAogICAgbmFtZSA9ICJQcmluY2VzcyBMdW5hIGxldmVsIDIiCiAgfSwKICBjNTgwNl8yNDNfMyA9IHsKICAgIGNoYXNzaXMgPSAiYXJtY29tMyIsCiAgICBtb2R1bGVzID0gewogICAgICAiY29tbXdlYXBvbl9saWdodG5pbmdndW4iLAogICAgICAiY29tbXdlYXBvbl9kaXNpbnRlZ3JhdG9yIiwKICAgICAgIm1vZHVsZV9maWVsZHJhZGFyIiwKICAgICAgIm1vZHVsZV9hYmxhdGl2ZV9hcm1vciIsCiAgICAgICJtb2R1bGVfcGVyc29uYWxfY2xvYWsiLAogICAgICAibW9kdWxlX2FibGF0aXZlX2FybW9yIgogICAgfSwKICAgIGNvc3QgPSAyMjI1LAogICAgbmFtZSA9ICJQcmluY2VzcyBMdW5hIGxldmVsIDMiCiAgfSwKICBjNTgwNl8yNDNfNCA9IHsKICAgIGNoYXNzaXMgPSAiYXJtY29tNCIsCiAgICBtb2R1bGVzID0gewogICAgICAiY29tbXdlYXBvbl9saWdodG5pbmdndW4iLAogICAgICAiY29tbXdlYXBvbl9kaXNpbnRlZ3JhdG9yIiwKICAgICAgIm1vZHVsZV9maWVsZHJhZGFyIiwKICAgICAgIm1vZHVsZV9hYmxhdGl2ZV9hcm1vciIsCiAgICAgICJtb2R1bGVfcGVyc29uYWxfY2xvYWsiLAogICAgICAibW9kdWxlX2FibGF0aXZlX2FybW9yIiwKICAgICAgIndlYXBvbm1vZF9zdHVuX2Jvb3N0ZXIiLAogICAgICAibW9kdWxlX2hpZ2hfcG93ZXJfc2Vydm9zIiwKICAgICAgIm1vZHVsZV9oZWF2eV9hcm1vciIKICAgIH0sCiAgICBjb3N0ID0gMzQ3NSwKICAgIG5hbWUgPSAiUHJpbmNlc3MgTHVuYSBsZXZlbCA0IgogIH0sCiAgYzU4MDZfNzE3XzAgPSB7CiAgICBjaGFzc2lzID0gImNvbW1yZWNvbjEiLAogICAgbW9kdWxlcyA9IHt9LAogICAgY29zdCA9IDAsCiAgICBuYW1lID0gIlNwaXRmaXJlIGxldmVsIDAiCiAgfSwKICBjNTgwNl83MTdfMSA9IHsKICAgIGNoYXNzaXMgPSAiY29tbXJlY29uMSIsCiAgICBtb2R1bGVzID0gewogICAgICAiY29tbXdlYXBvbl9oZWF0cmF5IiwKICAgICAgIm1vZHVsZV9maWVsZHJhZGFyIgogICAgfSwKICAgIGNvc3QgPSAxNzUsCiAgICBuYW1lID0gIlNwaXRmaXJlIGxldmVsIDEiCiAgfSwKICBjNTgwNl83MTdfMiA9IHsKICAgIGNoYXNzaXMgPSAiY29tbXJlY29uMiIsCiAgICBtb2R1bGVzID0gewogICAgICAiY29tbXdlYXBvbl9oZWF0cmF5IiwKICAgICAgIm1vZHVsZV9maWVsZHJhZGFyIiwKICAgICAgIm1vZHVsZV9hYmxhdGl2ZV9hcm1vciIKICAgIH0sCiAgICBjb3N0ID0gNjUwLAogICAgbmFtZSA9ICJTcGl0ZmlyZSBsZXZlbCAyIgogIH0sCiAgYzU4MDZfNzE3XzMgPSB7CiAgICBjaGFzc2lzID0gImNvbW1yZWNvbjMiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25faGVhdHJheSIsCiAgICAgICJjb21td2VhcG9uX25hcGFsbWdyZW5hZGUiLAogICAgICAibW9kdWxlX2ZpZWxkcmFkYXIiLAogICAgICAibW9kdWxlX2FibGF0aXZlX2FybW9yIiwKICAgICAgIm1vZHVsZV9wZXJzb25hbF9jbG9hayIsCiAgICAgICJtb2R1bGVfYWJsYXRpdmVfYXJtb3IiCiAgICB9LAogICAgY29zdCA9IDIxMDAsCiAgICBuYW1lID0gIlNwaXRmaXJlIGxldmVsIDMiCiAgfSwKICBjNTgwNl83MTdfNCA9IHsKICAgIGNoYXNzaXMgPSAiY29tbXJlY29uNCIsCiAgICBtb2R1bGVzID0gewogICAgICAiY29tbXdlYXBvbl9oZWF0cmF5IiwKICAgICAgImNvbW13ZWFwb25fbmFwYWxtZ3JlbmFkZSIsCiAgICAgICJtb2R1bGVfZmllbGRyYWRhciIsCiAgICAgICJtb2R1bGVfYWJsYXRpdmVfYXJtb3IiLAogICAgICAibW9kdWxlX3BlcnNvbmFsX2Nsb2FrIiwKICAgICAgIm1vZHVsZV9hYmxhdGl2ZV9hcm1vciIsCiAgICAgICJ3ZWFwb25tb2RfcGxhc21hX2NvbnRhaW5tZW50IiwKICAgICAgIm1vZHVsZV9hZHZfdGFyZ2V0aW5nIiwKICAgICAgIm1vZHVsZV9hdXRvcmVwYWlyIgogICAgfSwKICAgIGNvc3QgPSAzNDUwLAogICAgbmFtZSA9ICJTcGl0ZmlyZSBsZXZlbCA0IgogIH0sCiAgYzU4MDZfMTQ2OF8wID0gewogICAgY2hhc3NpcyA9ICJjb3Jjb20xIiwKICAgIG1vZHVsZXMgPSB7fSwKICAgIGNvc3QgPSAwLAogICAgbmFtZSA9ICJCaWcgTWFjaW50b3NoIGxldmVsIDAiCiAgfSwKICBjNTgwNl8xNDY4XzEgPSB7CiAgICBjaGFzc2lzID0gImNvcmNvbTEiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25fYXNzYXVsdGNhbm5vbiIsCiAgICAgICJtb2R1bGVfZmllbGRyYWRhciIKICAgIH0sCiAgICBjb3N0ID0gMTc1LAogICAgbmFtZSA9ICJCaWcgTWFjaW50b3NoIGxldmVsIDEiCiAgfSwKICBjNTgwNl8xNDY4XzIgPSB7CiAgICBjaGFzc2lzID0gImNvcmNvbTIiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25fYXNzYXVsdGNhbm5vbiIsCiAgICAgICJtb2R1bGVfZmllbGRyYWRhciIsCiAgICAgICJtb2R1bGVfaGlnaF9wb3dlcl9zZXJ2b3MiLAogICAgICAibW9kdWxlX2FibGF0aXZlX2FybW9yIgogICAgfSwKICAgIGNvc3QgPSA4MDAsCiAgICBuYW1lID0gIkJpZyBNYWNpbnRvc2ggbGV2ZWwgMiIKICB9LAogIGM1ODA2XzE0NjhfMyA9IHsKICAgIGNoYXNzaXMgPSAiY29yY29tMyIsCiAgICBtb2R1bGVzID0gewogICAgICAiY29tbXdlYXBvbl9hc3NhdWx0Y2Fubm9uIiwKICAgICAgImNvbW13ZWFwb25fY2x1c3RlcmJvbWIiLAogICAgICAibW9kdWxlX2ZpZWxkcmFkYXIiLAogICAgICAibW9kdWxlX2hpZ2hfcG93ZXJfc2Vydm9zIiwKICAgICAgIm1vZHVsZV9hYmxhdGl2ZV9hcm1vciIsCiAgICAgICJtb2R1bGVfYWR2X3RhcmdldGluZyIsCiAgICAgICJtb2R1bGVfY29tcGFuaW9uX2Ryb25lIgogICAgfSwKICAgIGNvc3QgPSAyMjAwLAogICAgbmFtZSA9ICJCaWcgTWFjaW50b3NoIGxldmVsIDMiCiAgfSwKICBjNTgwNl8xNDY4XzQgPSB7CiAgICBjaGFzc2lzID0gImNvcmNvbTQiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25fYXNzYXVsdGNhbm5vbiIsCiAgICAgICJjb21td2VhcG9uX2NsdXN0ZXJib21iIiwKICAgICAgIm1vZHVsZV9maWVsZHJhZGFyIiwKICAgICAgIm1vZHVsZV9oaWdoX3Bvd2VyX3NlcnZvcyIsCiAgICAgICJtb2R1bGVfYWJsYXRpdmVfYXJtb3IiLAogICAgICAibW9kdWxlX2Fkdl90YXJnZXRpbmciLAogICAgICAibW9kdWxlX2NvbXBhbmlvbl9kcm9uZSIsCiAgICAgICJtb2R1bGVfaGVhdnlfYXJtb3IiLAogICAgICAibW9kdWxlX2hpZ2hfcG93ZXJfc2Vydm9zIgogICAgfSwKICAgIGNvc3QgPSAzMjI1LAogICAgbmFtZSA9ICJCaWcgTWFjaW50b3NoIGxldmVsIDQiCiAgfSwKICBjNTgwNl8xNDY2XzAgPSB7CiAgICBjaGFzc2lzID0gImNvbW1zdXBwb3J0MSIsCiAgICBtb2R1bGVzID0ge30sCiAgICBjb3N0ID0gMCwKICAgIG5hbWUgPSAiUHJpbmNlc3MgQ2FkZW5jZSBsZXZlbCAwIgogIH0sCiAgYzU4MDZfMTQ2Nl8xID0gewogICAgY2hhc3NpcyA9ICJjb21tc3VwcG9ydDEiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25fZ2F1c3NyaWZsZSIsCiAgICAgICJtb2R1bGVfaGlnaF9wb3dlcl9zZXJ2b3MiCiAgICB9LAogICAgY29zdCA9IDIyNSwKICAgIG5hbWUgPSAiUHJpbmNlc3MgQ2FkZW5jZSBsZXZlbCAxIgogIH0sCiAgYzU4MDZfMTQ2Nl8yID0gewogICAgY2hhc3NpcyA9ICJjb21tc3VwcG9ydDIiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25fZ2F1c3NyaWZsZSIsCiAgICAgICJtb2R1bGVfaGlnaF9wb3dlcl9zZXJ2b3MiLAogICAgICAibW9kdWxlX2FibGF0aXZlX2FybW9yIgogICAgfSwKICAgIGNvc3QgPSA3MDAsCiAgICBuYW1lID0gIlByaW5jZXNzIENhZGVuY2UgbGV2ZWwgMiIKICB9LAogIGM1ODA2XzE0NjZfMyA9IHsKICAgIGNoYXNzaXMgPSAiY29tbXN1cHBvcnQzIiwKICAgIG1vZHVsZXMgPSB7CiAgICAgICJjb21td2VhcG9uX2dhdXNzcmlmbGUiLAogICAgICAiY29tbXdlYXBvbl9kaXNydXB0b3Jib21iIiwKICAgICAgIm1vZHVsZV9oaWdoX3Bvd2VyX3NlcnZvcyIsCiAgICAgICJtb2R1bGVfYWJsYXRpdmVfYXJtb3IiLAogICAgICAibW9kdWxlX3BlcnNvbmFsX2Nsb2FrIiwKICAgICAgImNvbnZlcnNpb25fc2hvY2tyaWZsZSIKICAgIH0sCiAgICBjb3N0ID0gMjQyNSwKICAgIG5hbWUgPSAiUHJpbmNlc3MgQ2FkZW5jZSBsZXZlbCAzIgogIH0sCiAgYzU4MDZfMTQ2Nl80ID0gewogICAgY2hhc3NpcyA9ICJjb21tc3VwcG9ydDQiLAogICAgbW9kdWxlcyA9IHsKICAgICAgImNvbW13ZWFwb25fZ2F1c3NyaWZsZSIsCiAgICAgICJjb21td2VhcG9uX2Rpc3J1cHRvcmJvbWIiLAogICAgICAibW9kdWxlX2hpZ2hfcG93ZXJfc2Vydm9zIiwKICAgICAgIm1vZHVsZV9hYmxhdGl2ZV9hcm1vciIsCiAgICAgICJtb2R1bGVfcGVyc29uYWxfY2xvYWsiLAogICAgICAiY29udmVyc2lvbl9zaG9ja3JpZmxlIiwKICAgICAgIm1vZHVsZV9oaWdoX3Bvd2VyX3NlcnZvcyIsCiAgICAgICJtb2R1bGVfYWR2X3RhcmdldGluZyIsCiAgICAgICJtb2R1bGVfcmVzdXJyZWN0IgogICAgfSwKICAgIGNvc3QgPSAzNDI1LAogICAgbmFtZSA9ICJQcmluY2VzcyBDYWRlbmNlIGxldmVsIDQiCiAgfQp9

{
  c5383_5514_0 = {
    chassis = "corcom1",
    modules = {},
    cost = 0,
    name = "Seacom level 0"
  },
  c5383_5514_1 = {
    chassis = "corcom1",
    modules = {
      "commweapon_torpedo",
      "module_energy_cell"
    },
    cost = 280,
    name = "Seacom level 1"
  },
  c5383_5514_2 = {
    chassis = "corcom2",
    modules = {
      "commweapon_torpedo",
      "module_energy_cell",
      "module_adv_nano",
      "module_resurrect"
    },
    cost = 980,
    name = "Seacom level 2"
  },
  c5383_5514_3 = {
    chassis = "corcom3",
    modules = {
      "commweapon_torpedo",
      "commweapon_torpedo",
      "module_energy_cell",
      "module_adv_nano",
      "module_resurrect",
      "module_adv_nano",
      "module_adv_nano"
    },
    cost = 2280,
    name = "Seacom level 3"
  },
  c5383_5514_4 = {
    chassis = "corcom4",
    modules = {
      "commweapon_torpedo",
      "commweapon_torpedo",
      "module_energy_cell",
      "module_adv_nano",
      "module_resurrect",
      "module_adv_nano",
      "module_adv_nano",
      "module_areashield",
      "module_personal_shield",
      "module_adv_nano"
    },
    cost = 3630,
    name = "Seacom level 4"
  },
  c5383_5513_0 = {
    chassis = "corcom1",
    modules = {},
    cost = 0,
    name = "Enercon level 0"
  },
  c5383_5513_1 = {
    chassis = "corcom1",
    modules = {
      "commweapon_beamlaser",
      "module_energy_cell"
    },
    cost = 230,
    name = "Enercon level 1"
  },
  c5383_5513_2 = {
    chassis = "corcom2",
    modules = {
      "commweapon_beamlaser",
      "module_energy_cell",
      "module_adv_nano",
      "module_adv_nano"
    },
    cost = 830,
    name = "Enercon level 2"
  },
  c5383_5513_3 = {
    chassis = "corcom3",
    modules = {
      "commweapon_beamlaser",
      "commweapon_riotcannon",
      "module_energy_cell",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano"
    },
    cost = 2130,
    name = "Enercon level 3"
  },
  c5383_5513_4 = {
    chassis = "corcom4",
    modules = {
      "commweapon_beamlaser",
      "commweapon_riotcannon",
      "module_energy_cell",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano"
    },
    cost = 3030,
    name = "Enercon level 4"
  },
  c5383_5512_0 = {
    chassis = "commrecon1",
    modules = {},
    cost = 0,
    name = "Enerjump level 0"
  },
  c5383_5512_1 = {
    chassis = "commrecon1",
    modules = {
      "commweapon_beamlaser",
      "module_energy_cell"
    },
    cost = 230,
    name = "Enerjump level 1"
  },
  c5383_5512_2 = {
    chassis = "commrecon2",
    modules = {
      "commweapon_beamlaser",
      "module_energy_cell",
      "module_adv_nano",
      "module_adv_nano"
    },
    cost = 830,
    name = "Enerjump level 2"
  },
  c5383_5512_3 = {
    chassis = "commrecon3",
    modules = {
      "commweapon_beamlaser",
      "commweapon_heatray",
      "module_energy_cell",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano"
    },
    cost = 2130,
    name = "Enerjump level 3"
  },
  c5383_5512_4 = {
    chassis = "commrecon4",
    modules = {
      "commweapon_beamlaser",
      "commweapon_heatray",
      "module_energy_cell",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano",
      "module_adv_nano"
    },
    cost = 3030,
    name = "Enerjump level 4"
  },
  c5383_9559_0 = {
    chassis = "commrecon1",
    modules = {},
    cost = 0,
    name = "Firejump level 0"
  },
  c5383_9559_1 = {
    chassis = "commrecon1",
    modules = {
      "commweapon_heavymachinegun",
      "module_energy_cell"
    },
    cost = 305,
    name = "Firejump level 1"
  },
  c5383_9559_2 = {
    chassis = "commrecon2",
    modules = {
      "commweapon_heavymachinegun",
      "module_energy_cell",
      "module_autorepair",
      "module_personal_cloak"
    },
    cost = 1105,
    name = "Firejump level 2"
  },
  c5383_9559_3 = {
    chassis = "commrecon3",
    modules = {
      "commweapon_heavymachinegun",
      "commweapon_napalmgrenade",
      "module_energy_cell",
      "module_autorepair",
      "module_personal_cloak",
      "module_ablative_armor",
      "module_adv_targeting"
    },
    cost = 2455,
    name = "Firejump level 3"
  },
  c5383_9559_4 = {
    chassis = "commrecon4",
    modules = {
      "commweapon_heavymachinegun",
      "commweapon_napalmgrenade",
      "module_energy_cell",
      "module_autorepair",
      "module_personal_cloak",
      "module_ablative_armor",
      "module_adv_targeting",
      "module_adv_targeting",
      "module_adv_targeting",
      "module_adv_targeting"
    },
    cost = 3355,
    name = "Firejump level 4"
  },
  c5806_243_0 = {
    chassis = "armcom1",
    modules = {},
    cost = 0,
    name = "Princess Luna level 0"
  },
  c5806_243_1 = {
    chassis = "armcom1",
    modules = {
      "commweapon_lightninggun",
      "module_fieldradar"
    },
    cost = 175,
    name = "Princess Luna level 1"
  },
  c5806_243_2 = {
    chassis = "armcom2",
    modules = {
      "commweapon_lightninggun",
      "module_fieldradar",
      "module_ablative_armor"
    },
    cost = 650,
    name = "Princess Luna level 2"
  },
  c5806_243_3 = {
    chassis = "armcom3",
    modules = {
      "commweapon_lightninggun",
      "commweapon_disintegrator",
      "module_fieldradar",
      "module_ablative_armor",
      "module_personal_cloak",
      "module_ablative_armor"
    },
    cost = 2225,
    name = "Princess Luna level 3"
  },
  c5806_243_4 = {
    chassis = "armcom4",
    modules = {
      "commweapon_lightninggun",
      "commweapon_disintegrator",
      "module_fieldradar",
      "module_ablative_armor",
      "module_personal_cloak",
      "module_ablative_armor",
      "weaponmod_stun_booster",
      "module_high_power_servos",
      "module_heavy_armor"
    },
    cost = 3475,
    name = "Princess Luna level 4"
  },
  c5806_717_0 = {
    chassis = "commrecon1",
    modules = {},
    cost = 0,
    name = "Spitfire level 0"
  },
  c5806_717_1 = {
    chassis = "commrecon1",
    modules = {
      "commweapon_heatray",
      "module_fieldradar"
    },
    cost = 175,
    name = "Spitfire level 1"
  },
  c5806_717_2 = {
    chassis = "commrecon2",
    modules = {
      "commweapon_heatray",
      "module_fieldradar",
      "module_ablative_armor"
    },
    cost = 650,
    name = "Spitfire level 2"
  },
  c5806_717_3 = {
    chassis = "commrecon3",
    modules = {
      "commweapon_heatray",
      "commweapon_napalmgrenade",
      "module_fieldradar",
      "module_ablative_armor",
      "module_personal_cloak",
      "module_ablative_armor"
    },
    cost = 2100,
    name = "Spitfire level 3"
  },
  c5806_717_4 = {
    chassis = "commrecon4",
    modules = {
      "commweapon_heatray",
      "commweapon_napalmgrenade",
      "module_fieldradar",
      "module_ablative_armor",
      "module_personal_cloak",
      "module_ablative_armor",
      "weaponmod_plasma_containment",
      "module_adv_targeting",
      "module_autorepair"
    },
    cost = 3450,
    name = "Spitfire level 4"
  },
  c5806_1468_0 = {
    chassis = "corcom1",
    modules = {},
    cost = 0,
    name = "Big Macintosh level 0"
  },
  c5806_1468_1 = {
    chassis = "corcom1",
    modules = {
      "commweapon_assaultcannon",
      "module_fieldradar"
    },
    cost = 175,
    name = "Big Macintosh level 1"
  },
  c5806_1468_2 = {
    chassis = "corcom2",
    modules = {
      "commweapon_assaultcannon",
      "module_fieldradar",
      "module_high_power_servos",
      "module_ablative_armor"
    },
    cost = 800,
    name = "Big Macintosh level 2"
  },
  c5806_1468_3 = {
    chassis = "corcom3",
    modules = {
      "commweapon_assaultcannon",
      "commweapon_clusterbomb",
      "module_fieldradar",
      "module_high_power_servos",
      "module_ablative_armor",
      "module_adv_targeting",
      "module_companion_drone"
    },
    cost = 2200,
    name = "Big Macintosh level 3"
  },
  c5806_1468_4 = {
    chassis = "corcom4",
    modules = {
      "commweapon_assaultcannon",
      "commweapon_clusterbomb",
      "module_fieldradar",
      "module_high_power_servos",
      "module_ablative_armor",
      "module_adv_targeting",
      "module_companion_drone",
      "module_heavy_armor",
      "module_high_power_servos"
    },
    cost = 3225,
    name = "Big Macintosh level 4"
  },
  c5806_1466_0 = {
    chassis = "commsupport1",
    modules = {},
    cost = 0,
    name = "Princess Cadence level 0"
  },
  c5806_1466_1 = {
    chassis = "commsupport1",
    modules = {
      "commweapon_gaussrifle",
      "module_high_power_servos"
    },
    cost = 225,
    name = "Princess Cadence level 1"
  },
  c5806_1466_2 = {
    chassis = "commsupport2",
    modules = {
      "commweapon_gaussrifle",
      "module_high_power_servos",
      "module_ablative_armor"
    },
    cost = 700,
    name = "Princess Cadence level 2"
  },
  c5806_1466_3 = {
    chassis = "commsupport3",
    modules = {
      "commweapon_gaussrifle",
      "commweapon_disruptorbomb",
      "module_high_power_servos",
      "module_ablative_armor",
      "module_personal_cloak",
      "conversion_shockrifle"
    },
    cost = 2425,
    name = "Princess Cadence level 3"
  },
  c5806_1466_4 = {
    chassis = "commsupport4",
    modules = {
      "commweapon_gaussrifle",
      "commweapon_disruptorbomb",
      "module_high_power_servos",
      "module_ablative_armor",
      "module_personal_cloak",
      "conversion_shockrifle",
      "module_high_power_servos",
      "module_adv_targeting",
      "module_resurrect"
    },
    cost = 3425,
    name = "Princess Cadence level 4"
  }
}

-- example of playerkey data
ewogIFsiU2VhY29tIl0gPSB7CiAgICAiYzUzODNfNTUxNF8wIiwKICAgICJjNTM4M181NTE0XzEiLAogICAgImM1MzgzXzU1MTRfMiIsCiAgICAiYzUzODNfNTUxNF8zIiwKICAgICJjNTM4M181NTE0XzQiCiAgfSwKICBbIkVuZXJjb24iXSA9IHsKICAgICJjNTM4M181NTEzXzAiLAogICAgImM1MzgzXzU1MTNfMSIsCiAgICAiYzUzODNfNTUxM18yIiwKICAgICJjNTM4M181NTEzXzMiLAogICAgImM1MzgzXzU1MTNfNCIKICB9LAogIFsiRW5lcmp1bXAiXSA9IHsKICAgICJjNTM4M181NTEyXzAiLAogICAgImM1MzgzXzU1MTJfMSIsCiAgICAiYzUzODNfNTUxMl8yIiwKICAgICJjNTM4M181NTEyXzMiLAogICAgImM1MzgzXzU1MTJfNCIKICB9LAogIFsiRmlyZWp1bXAiXSA9IHsKICAgICJjNTM4M185NTU5XzAiLAogICAgImM1MzgzXzk1NTlfMSIsCiAgICAiYzUzODNfOTU1OV8yIiwKICAgICJjNTM4M185NTU5XzMiLAogICAgImM1MzgzXzk1NTlfNCIKICB9Cn0=

{
  ["Seacom"] = {
    "c5383_5514_0",
    "c5383_5514_1",
    "c5383_5514_2",
    "c5383_5514_3",
    "c5383_5514_4"
  },
  ["Enercon"] = {
    "c5383_5513_0",
    "c5383_5513_1",
    "c5383_5513_2",
    "c5383_5513_3",
    "c5383_5513_4"
  },
  ["Enerjump"] = {
    "c5383_5512_0",
    "c5383_5512_1",
    "c5383_5512_2",
    "c5383_5512_3",
    "c5383_5512_4"
  },
  ["Firejump"] = {
    "c5383_9559_0",
    "c5383_9559_1",
    "c5383_9559_2",
    "c5383_9559_3",
    "c5383_9559_4"
  }
}
]]--