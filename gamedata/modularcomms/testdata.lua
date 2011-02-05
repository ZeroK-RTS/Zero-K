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

