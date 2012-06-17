--[[

local moduleSetCount = 21
local moduleSet = { -- alphebetical
	[1] = {count = 8, sn = "aa", name = "module_ablative_armor"},
	[2] = {count = 1, sn = "af", name = "weaponmod_autoflechette"},
	[3] = {count = 8, sn = "an", name = "module_adv_nano"},
	[4] = {count = 8, sn = "ar", name = "module_autorepair"},
	[5] = {count = 1, sn = "as", name = "module_areashield"},
	[6] = {count = 8, sn = "at", name = "module_adv_targeting"},
	[7] = {count = 1, sn = "cf", name = "module_cloak_field"},
	[8] = {count = 1, sn = "cl", name = "module_personal_cloak"},
	[9] = {count = 1, sn = "da", name = "weaponmod_disruptor_ammo"},
	[10] = {count = 8, sn = "db", name = "module_dmg_booster"},
	[11] = {count = 8, sn = "ec", name = "module_energy_cell"},
	[12] = {count = 1, sn = "fr", name = "module_fieldradar"},
	[13] = {count = 8, sn = "ha", name = "module_heavy_armor"},
	[14] = {count = 1, sn = "hc", name = "weaponmod_high_caliber_barrel"},
	[15] = {count = 1, sn = "hf", name = "weaponmod_high_frequency_beam"},
	[16] = {count = 1, sn = "ja", name = "module_jammer"},
	[17] = {count = 1, sn = "nw", name = "weaponmod_napalm_warhead"},
	[18] = {count = 1, sn = "pc", name = "weaponmod_plasma_containment"},
	[19] = {count = 8, sn = "ps", name = "module_high_power_servos"},
	[20] = {count = 1, sn = "re", name = "module_resurrect"},
	[21] = {count = 1, sn = "sr", name = "weaponmod_standoff_rocket"},
}

local function orderedTableCopyAndConcat(oldTable, value)
	local newTable = {count = oldTable.count+1, data = {}, text = oldTable.text .. moduleSet[value].sn}
	for i = 1, oldTable.count do
		newTable.data[i] = oldTable.data[i]
	end
	newTable.data[newTable.count] = value
	return newTable
end

local function orderedTableCopy(oldTable)
	local newTable = {count = oldTable.count, data = {}, text = oldTable.text}
	for i = 1, oldTable.count do
		newTable.data[i] = oldTable.data[i]
	end
	return newTable
end

local function chooseNextElement(picksLeft, bound, setSoFar, picksOfThisIndex)
	
	if picksLeft == 0 then
		--Spring.Echo(setSoFar.text)
		return {count = 1, data = {[1] = setSoFar}} -- if there are no picks left simply return the set so far
	end
	
	local returnSets = {count = 1, data = {[1] = orderedTableCopy(setSoFar)}} -- return sets initially contains this set as sets must not be of max size
	
	-- add another of the most recent element if there is one to choose from
	if picksOfThisIndex < moduleSet[bound].count then
		local setSet = chooseNextElement(picksLeft-1, bound, orderedTableCopyAndConcat(setSoFar, bound), picksOfThisIndex + 1)
		for i = 1, setSet.count do
			returnSets.count = returnSets.count + 1
			returnSets.data[returnSets.count] = setSet.data[i]
		end
	end
	
	-- each element greater than this one can be added as well
	for element = bound+1, moduleSetCount do
		local setSet = chooseNextElement(picksLeft-1, element, orderedTableCopyAndConcat(setSoFar, element), 1)
		for i = 1, setSet.count do
			returnSets.count = returnSets.count + 1
			returnSets.data[returnSets.count] = setSet.data[i]
		end
	end

	return returnSets
end

local massiveSetSet = chooseNextElement(8, 1, {count = 0, data = {}, text = ""}, 0)

Spring.Echo(massiveSetSet.count)

for i = 1, massiveSetSet.count do
	Spring.Echo(massiveSetSet.data[i].text)
end



local weaponSet = {
	commweapon_beamlaser = 1,
	commweapon_heavymachinegun = 1,
	commweapon_heatray = 1,
	commweapon_gaussrifle = 1,
	commweapon_partillery = 1,
	commweapon_riotcannon = 1,
	commweapon_rocketlauncher = 1,
	commweapon_shotgun = 1,
	commweapon_slowbeam = 1,
	
	commweapon_concussion = 3,
	commweapon_clusterbomb = 3,
	commweapon_disintegrator = 3,
	commweapon_disruptorbomb = 3,
	commweapon_napalmgrenade = 3,
	commweapon_sunburst = 3,
	commweapon_disruptor = 3,
	commweapon_shockrifle = 3,
}

local comSet = {
	armcom1 = "strike_",
	corcom1 = "bat_",
	commsupport1 = "sup_",
	commrecon1 = "recon_",
}
	
local fullModuleSet = {}

--]]

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
			"module_adv_targeting",
			"module_adv_targeting",
			"module_adv_targeting",
			"module_adv_targeting",
			"module_adv_targeting",
			"module_adv_targeting"
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
		name = "partbeam",
		modules = {
			"commweapon_lparticlebeam",
			"commweapon_hparticlebeam",
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

-- deprecated stuff

--[[

-- modoption
{
  strike = { 
	chassis = "armcom", 
	name = "Her Royal Majesty",
	modules = { "commweapon_heatray", "module_areashield", },
	cost = 100,
  },
  advstrike = {
    chassis = "commsupport2",
	name = "The Empress",
    modules = { "commweapon_gaussrifle", "module_ablative_armor", "module_jammer", },
	cost = 320,
  },
  battle = {
    chassis = "corcom",
	name = "Mr. Amazing",
    modules = { "commweapon_shotgun", "module_fieldradar", "module_cloak_field", },
	cost = 640,
  },
  heavyrecon = {
    chassis = "commrecon",
	name = "John Q. Rambo",
    modules = { "commweapon_heavymachinegun", "module_autorepair", "module_repair_field",  },
	cost = 250,
  },
}

ew0KICBzdHJpa2UgPSB7IA0KCWNoYXNzaXMgPSAiYXJtY29tIiwgDQoJbmFtZSA9ICJIZXIgUm95
YWwgTWFqZXN0eSIsDQoJbW9kdWxlcyA9IHsgImNvbW13ZWFwb25faGVhdHJheSIsICJtb2R1bGVf
YXJlYXNoaWVsZCIsIH0sDQoJY29zdCA9IDEwMCwNCiAgfSwNCiAgYWR2c3RyaWtlID0gew0KICAg
IGNoYXNzaXMgPSAiY29tbXN1cHBvcnQyIiwNCgluYW1lID0gIlRoZSBFbXByZXNzIiwNCiAgICBt
b2R1bGVzID0geyAiY29tbXdlYXBvbl9nYXVzc3JpZmxlIiwgIm1vZHVsZV9hYmxhdGl2ZV9hcm1v
ciIsICJtb2R1bGVfamFtbWVyIiwgfSwNCgljb3N0ID0gMzIwLA0KICB9LA0KICBiYXR0bGUgPSB7
DQogICAgY2hhc3NpcyA9ICJjb3Jjb20iLA0KCW5hbWUgPSAiTXIuIEFtYXppbmciLA0KICAgIG1v
ZHVsZXMgPSB7ICJjb21td2VhcG9uX3Nob3RndW4iLCAibW9kdWxlX2ZpZWxkcmFkYXIiLCAibW9k
dWxlX2Nsb2FrX2ZpZWxkIiwgfSwNCgljb3N0ID0gNjQwLA0KICB9LA0KICBoZWF2eXJlY29uID0g
ew0KICAgIGNoYXNzaXMgPSAiY29tbXJlY29uIiwNCgluYW1lID0gIkpvaG4gUS4gUmFtYm8iLA0K
ICAgIG1vZHVsZXMgPSB7ICJjb21td2VhcG9uX2hlYXZ5bWFjaGluZWd1biIsICJtb2R1bGVfYXV0
b3JlcGFpciIsICJtb2R1bGVfcmVwYWlyX2ZpZWxkIiwgIH0sDQoJY29zdCA9IDI1MCwNCiAgfSwN
Cn0=

-- player data
{
  mystrike = {
    "strike",
    "advstrike",
	"battle",
  },
  mybattle = {
    "battle",
  },
  myrecon = {
    "heavyrecon",
    "commadvrecon",
  },
}
ew0KICBteXN0cmlrZSA9IHsNCiAgICAic3RyaWtlIiwNCiAgICAiYWR2c3RyaWtlIiwNCgkiYmF0
dGxlIiwNCiAgfSwNCiAgbXliYXR0bGUgPSB7DQogICAgImJhdHRsZSIsDQogIH0sDQogIG15cmVj
b24gPSB7DQogICAgImhlYXZ5cmVjb24iLA0KICAgICJjb21tYWR2cmVjb24iLA0KICB9LA0KfQ==

]]--

