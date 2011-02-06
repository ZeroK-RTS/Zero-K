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
  strike = { chassis = "armcom", name = "Fair Maiden", },
  advstrike = {
    chassis = "armadvcom",
    modules = { "adv_composite_armor", "high_power_servos" }
  },
  battle = {
    chassis = "corcom",
    modules = { "radarmodule", "high_power_servos" }
  }
}

ew0KICBzdHJpa2UgPSB7IGNoYXNzaXMgPSAiYXJtY29tIiwgbmFtZSA9ICJGYWlyIE1haWRlbiIsIH0sDQogIGFkdnN0cmlrZSA9IHsNCiAgICBjaGFzc2lzID0gImFybWFkdmNvbSIsDQogICAgbW9kdWxlcyA9IHsgImFkdl9jb21wb3NpdGVfYXJtb3IiLCAiaGlnaF9wb3dlcl9zZXJ2b3MiIH0NCiAgfSwNCiAgYmF0dGxlID0gew0KICAgIGNoYXNzaXMgPSAiY29yY29tIiwNCiAgICBtb2R1bGVzID0geyAicmFkYXJtb2R1bGUiLCAiaGlnaF9wb3dlcl9zZXJ2b3MiIH0NCiAgfQ0KfQ==

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

