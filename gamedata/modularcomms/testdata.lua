-- deprecated

Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/base64.lua")

--indexed by playerID
--[[
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

-- modoption
{
  strike = { 
	chassis = "armcom", 
	name = "Her Royal Majesty",
	modules = { "commweapon_shotgun", }
  },
  advstrike = {
    chassis = "armadvcom",
	name = "The Empress",
    modules = { "commweapon_gaussrifle", "module_ablative_armor" }
  },
  battle = {
    chassis = "corcom",
	name = "Mr. Amazing",
    modules = { "commweapon_rocketlauncher", "module_fieldradar"}
  },
  heavyrecon = {
    chassis = "commrecon",
	name = "John Q. Rambo",
    modules = { "commweapon_heavymachinegun", "module_autorepair",  }
  },
}

ew0KICBzdHJpa2UgPSB7IA0KCWNoYXNzaXMgPSAiYXJtY29tIiwgDQoJbmFtZSA9ICJIZXIgUm95
YWwgTWFqZXN0eSIsDQoJbW9kdWxlcyA9IHsgImNvbW13ZWFwb25fc2hvdGd1biIsIH0NCiAgfSwN
CiAgYWR2c3RyaWtlID0gew0KICAgIGNoYXNzaXMgPSAiYXJtYWR2Y29tIiwNCgluYW1lID0gIlRo
ZSBFbXByZXNzIiwNCiAgICBtb2R1bGVzID0geyAiY29tbXdlYXBvbl9nYXVzc3JpZmxlIiwgIm1v
ZHVsZV9hYmxhdGl2ZV9hcm1vciIgfQ0KICB9LA0KICBiYXR0bGUgPSB7DQogICAgY2hhc3NpcyA9
ICJjb3Jjb20iLA0KCW5hbWUgPSAiTXIuIEFtYXppbmciLA0KICAgIG1vZHVsZXMgPSB7ICJjb21t
d2VhcG9uX3JvY2tldGxhdW5jaGVyIiwgIm1vZHVsZV9maWVsZHJhZGFyIn0NCiAgfSwNCiAgaGVh
dnlyZWNvbiA9IHsNCiAgICBjaGFzc2lzID0gImNvbW1yZWNvbiIsDQoJbmFtZSA9ICJKb2huIFEu
IFJhbWJvIiwNCiAgICBtb2R1bGVzID0geyAiY29tbXdlYXBvbl9oZWF2eW1hY2hpbmVndW4iLCAi
bW9kdWxlX2F1dG9yZXBhaXIiLCAgfQ0KICB9LA0KfQ==

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

