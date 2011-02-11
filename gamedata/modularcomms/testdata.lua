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
	modules = { "commweapon_shotgun", "module_areashield", }
  },
  advstrike = {
    chassis = "armadvcom",
	name = "The Empress",
    modules = { "commweapon_gaussrifle", "module_ablative_armor", "module_jammer", }
  },
  battle = {
    chassis = "corcom",
	name = "Mr. Amazing",
    modules = { "commweapon_slowbeam", "module_fieldradar", "module_cloak_field", }
  },
  heavyrecon = {
    chassis = "commrecon",
	name = "John Q. Rambo",
    modules = { "commweapon_riotcannon", "module_autorepair", "module_repair_field",  }
  },
}

ew0KICBzdHJpa2UgPSB7IA0KCWNoYXNzaXMgPSAiYXJtY29tIiwgDQoJbmFtZSA9ICJIZXIgUm95
YWwgTWFqZXN0eSIsDQoJbW9kdWxlcyA9IHsgImNvbW13ZWFwb25fc2hvdGd1biIsICJtb2R1bGVf
YXJlYXNoaWVsZCIsIH0NCiAgfSwNCiAgYWR2c3RyaWtlID0gew0KICAgIGNoYXNzaXMgPSAiYXJt
YWR2Y29tIiwNCgluYW1lID0gIlRoZSBFbXByZXNzIiwNCiAgICBtb2R1bGVzID0geyAiY29tbXdl
YXBvbl9nYXVzc3JpZmxlIiwgIm1vZHVsZV9hYmxhdGl2ZV9hcm1vciIsICJtb2R1bGVfamFtbWVy
IiwgfQ0KICB9LA0KICBiYXR0bGUgPSB7DQogICAgY2hhc3NpcyA9ICJjb3Jjb20iLA0KCW5hbWUg
PSAiTXIuIEFtYXppbmciLA0KICAgIG1vZHVsZXMgPSB7ICJjb21td2VhcG9uX3Nsb3diZWFtIiwg
Im1vZHVsZV9maWVsZHJhZGFyIiwgIm1vZHVsZV9jbG9ha19maWVsZCIsIH0NCiAgfSwNCiAgaGVh
dnlyZWNvbiA9IHsNCiAgICBjaGFzc2lzID0gImNvbW1yZWNvbiIsDQoJbmFtZSA9ICJKb2huIFEu
IFJhbWJvIiwNCiAgICBtb2R1bGVzID0geyAiY29tbXdlYXBvbl9yaW90Y2Fubm9uIiwgIm1vZHVs
ZV9hdXRvcmVwYWlyIiwgIm1vZHVsZV9yZXBhaXJfZmllbGQiLCAgfQ0KICB9LA0KfQ==

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

