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
	name = "Fair Maiden",
	modules = { "commweapon_shotgun", }
  },
  advstrike = {
    chassis = "armadvcom",
    modules = { "adv_composite_armor", "high_power_servos" }
  },
  battle = {
    chassis = "corcom",
    modules = { "radarmodule", "high_power_servos" }
  }
}

ew0KICBzdHJpa2UgPSB7IA0KCWNoYXNzaXMgPSAiYXJtY29tIiwgDQoJbmFtZSA9ICJGYWlyIE1haWRlbiIsDQoJbW9kdWxlcyA9IHsgImNvbW13ZWFwb25fc2hvdGd1biIsIH0NCiAgfSwNCiAgYWR2c3RyaWtlID0gew0KICAgIGNoYXNzaXMgPSAiYXJtYWR2Y29tIiwNCiAgICBtb2R1bGVzID0geyAiYWR2X2NvbXBvc2l0ZV9hcm1vciIsICJoaWdoX3Bvd2VyX3NlcnZvcyIgfQ0KICB9LA0KICBiYXR0bGUgPSB7DQogICAgY2hhc3NpcyA9ICJjb3Jjb20iLA0KICAgIG1vZHVsZXMgPSB7ICJyYWRhcm1vZHVsZSIsICJoaWdoX3Bvd2VyX3NlcnZvcyIgfQ0KICB9DQp9

-- player data
{
  strike = {
    "strike",
    "advstrike",
  },
  battle = {
    "battle",
  },
  recon = {
    "commrecon",
    "commadvrecon",
  },
  support = {
    "commsupport",
    "armadvcom",
  },
}
ew0KICBzdHJpa2UgPSB7DQogICAgInN0cmlrZSIsDQogICAgImFkdnN0cmlrZSIsDQogIH0sDQog
IGJhdHRsZSA9IHsNCiAgICAiYmF0dGxlIiwNCiAgfSwNCiAgcmVjb24gPSB7DQogICAgImNvbW1y
ZWNvbiIsDQogICAgImNvbW1hZHZyZWNvbiIsDQogIH0sDQogIHN1cHBvcnQgPSB7DQogICAgImNv
bW1zdXBwb3J0IiwNCiAgICAiYXJtYWR2Y29tIiwNCiAgfSwNCn0=

]]--

