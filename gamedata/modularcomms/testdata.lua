-- deprecated

Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/base64.lua")

--indexed by playerID
testdata = {
	[0] = {
		--indexed by level
		strike = {
			[1] = {
				name = "Ms. Amazing",
				upgrades = {},
				allowMorph = true
			},
		},
	},
	[1] = {
		recon = {
			[1] = {
				name = "Jumping Jack Flash",
				upgrades = {"adv_composite_armor"},
			},
			[2] = {
				upgrades = {"adv_composite_armor", "focusing_prism"},
			},
		},
		unlocks = { "spherepole" },
	},
	[3] = {
		unlocks = { "armmerl" },
	}
}

return testdata
--return Spring.Utilities.Base64Encode(tostring(testdata))

-- just some stuff
--[[
-- modoption
{
  strike = { 
	chassis = "armcom", 
	name = "Her Royal Majesty",
	modules = { "commweapon_rocketlauncher", }
  },
  advstrike = {
    chassis = "armadvcom",
	name = "The Empress",
    modules = { "adv_composite_armor", "high_power_servos" }
  },
  battle = {
    chassis = "corcom",
	name = "Mr. Amazing",
    modules = { "commweapon_shotgun", "radarmodule", "high_power_servos" }
  },
  heavyrecon = {
    chassis = "commrecon",
	name = "John Q. Rambo",
    modules = { "commweapon_heavymachinegun", "radarmodule", "high_power_servos" }
  },
}

ew0KICBzdHJpa2UgPSB7IA0KCWNoYXNzaXMgPSAiYXJtY29tIiwgDQoJbmFtZSA9ICJIZXIgUm95YWwgTWFqZXN0eSIsDQoJbW9kdWxlcyA9IHsgImNvbW13ZWFwb25fcm9ja2V0bGF1bmNoZXIiLCB9DQogIH0sDQogIGFkdnN0cmlrZSA9IHsNCiAgICBjaGFzc2lzID0gImFybWFkdmNvbSIsDQoJbmFtZSA9ICJUaGUgRW1wcmVzcyIsDQogICAgbW9kdWxlcyA9IHsgImFkdl9jb21wb3NpdGVfYXJtb3IiLCAiaGlnaF9wb3dlcl9zZXJ2b3MiIH0NCiAgfSwNCiAgYmF0dGxlID0gew0KICAgIGNoYXNzaXMgPSAiY29yY29tIiwNCgluYW1lID0gIk1yLiBBbWF6aW5nIiwNCiAgICBtb2R1bGVzID0geyAiY29tbXdlYXBvbl9zaG90Z3VuIiwgInJhZGFybW9kdWxlIiwgImhpZ2hfcG93ZXJfc2Vydm9zIiB9DQogIH0sDQogIGhlYXZ5cmVjb24gPSB7DQogICAgY2hhc3NpcyA9ICJjb21tcmVjb24iLA0KCW5hbWUgPSAiSm9obiBRLiBSYW1ibyIsDQogICAgbW9kdWxlcyA9IHsgImNvbW13ZWFwb25faGVhdnltYWNoaW5lZ3VuIiwgInJhZGFybW9kdWxlIiwgImhpZ2hfcG93ZXJfc2Vydm9zIiB9DQogIH0sDQp9

-- player data
{
  mystrike = {
    "strike",
    "advstrike",
  },
  mybattle = {
    "battle",
  },
  myrecon = {
    "heavyrecon",
    "commadvrecon",
  },
}
ew0KICBteXN0cmlrZSA9IHsNCiAgICAic3RyaWtlIiwNCiAgICAiYWR2c3RyaWtlIiwNCiAgfSwNCiAgbXliYXR0bGUgPSB7DQogICAgImJhdHRsZSIsDQogIH0sDQogIG15cmVjb24gPSB7DQogICAgImhlYXZ5cmVjb24iLA0KICAgICJjb21tYWR2cmVjb24iLA0KICB9LA0KfQ==

]]--

