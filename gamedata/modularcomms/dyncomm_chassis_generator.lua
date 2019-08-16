local chassisDefs = {
	{
		name = "dynstrike1",
		weapons = {
			"commweapon_peashooter",
			"commweapon_beamlaser",
			"commweapon_lparticlebeam",
			"commweapon_shotgun",
			"commweapon_shotgun_disrupt",
			"commweapon_disruptor",
			"commweapon_heavymachinegun",
			"commweapon_heavymachinegun_disrupt",
			"commweapon_missilelauncher",
			"commweapon_lightninggun",
			"commweapon_lightninggun_improved",
			"commweapon_peashooter",
			"commweapon_beamlaser",
			"commweapon_lparticlebeam",
			"commweapon_shotgun",
			"commweapon_shotgun_disrupt",
			"commweapon_disruptor",
			"commweapon_heavymachinegun",
			"commweapon_heavymachinegun_disrupt",
			"commweapon_missilelauncher",
			"commweapon_lightninggun",
			"commweapon_lightninggun_improved",
			"commweapon_multistunner",
			"commweapon_multistunner_improved",
			"commweapon_disruptorbomb",
			"commweapon_disintegrator",
			-- Space for shield
		}
	},
	{
		name = "dynrecon1",
		weapons = {
			"commweapon_peashooter",
			"commweapon_beamlaser",
			"commweapon_lparticlebeam",
			"commweapon_disruptor",
			"commweapon_shotgun",
			"commweapon_shotgun_disrupt",
			"commweapon_lightninggun",
			"commweapon_lightninggun_improved",
			"commweapon_flamethrower",
			"commweapon_heavymachinegun",
			"commweapon_heavymachinegun_disrupt",
			"commweapon_multistunner",
			"commweapon_multistunner_improved",
			"commweapon_napalmgrenade",
			"commweapon_clusterbomb",
			"commweapon_disruptorbomb",
			"commweapon_concussion",
			-- Space for shield
		}
	},
	{
		name = "dynsupport1",
		weapons = {
			"commweapon_peashooter",
			"commweapon_beamlaser",
			"commweapon_shotgun",
			"commweapon_shotgun_disrupt",
			"commweapon_lparticlebeam",
			"commweapon_disruptor",
			"commweapon_hparticlebeam",
			"commweapon_heavy_disruptor",
			"commweapon_lightninggun",
			"commweapon_lightninggun_improved",
			"commweapon_missilelauncher",
			"commweapon_shockrifle",
			"commweapon_multistunner",
			"commweapon_multistunner_improved",
			"commweapon_disruptorbomb",
			-- Space for shield
		}
	},
	{
		name = "dynassault1",
		weapons = {
			"commweapon_peashooter",
			"commweapon_beamlaser",
			"commweapon_heatray",
			"commweapon_heavymachinegun",
			"commweapon_flamethrower",
			"commweapon_rocketlauncher",
			"commweapon_rocketlauncher_napalm",
			"commweapon_riotcannon",
			"commweapon_riotcannon_napalm",
			"commweapon_peashooter",
			"commweapon_beamlaser",
			"commweapon_heatray",
			"commweapon_heavymachinegun",
			"commweapon_flamethrower",
			"commweapon_rocketlauncher",
			"commweapon_rocketlauncher_napalm",
			"commweapon_riotcannon",
			"commweapon_riotcannon_napalm",
			"commweapon_hpartillery",
			"commweapon_hpartillery_napalm",
			"commweapon_disintegrator",
			"commweapon_napalmgrenade",
			"commweapon_slamrocket",
			"commweapon_clusterbomb",
			-- Space for shield
		}
	},
	{
		name = "dynknight1",
		weapons = {
			"commweapon_peashooter",
			"commweapon_beamlaser",
			"commweapon_lparticlebeam",
			"commweapon_shotgun",
			"commweapon_shotgun_disrupt",
			"commweapon_disruptor",
			"commweapon_heatray",
			"commweapon_heavymachinegun",
			"commweapon_heavymachinegun_disrupt",
			"commweapon_missilelauncher",
			"commweapon_lightninggun",
			"commweapon_lightninggun_improved",
			"commweapon_multistunner",
			"commweapon_multistunner_improved",
			"commweapon_flamethrower",
			"commweapon_rocketlauncher",
			"commweapon_rocketlauncher_napalm",
			"commweapon_riotcannon",
			"commweapon_riotcannon_napalm",
			"commweapon_peashooter",
			"commweapon_hpartillery",
			"commweapon_hpartillery_napalm",
			"commweapon_disintegrator",
			"commweapon_napalmgrenade",
			"commweapon_slamrocket",
			"commweapon_disruptorbomb",
			"commweapon_concussion",
			"commweapon_clusterbomb",
			"commweapon_hparticlebeam",
			"commweapon_shockrifle",
			-- Space for shield
		}
	},
}

local commanderCost = 1100

local statOverrides = {
	cloakcost       = 5, -- For personal cloak
	cloakcostmoving = 10,
	onoffable       = true, -- For jammer and cloaker toggling
	canmanualfire   = true, -- For manualfire weapons.
	buildcostmetal  = commanderCost,
	buildcostenergy = commanderCost,
	buildtime       = commanderCost,
	power           = 1200,
}

for i = 1, #chassisDefs do
	local name = chassisDefs[i].name
	local unitDef = UnitDefs[name]
	
	for wreckName, wreckDef in pairs(unitDef.featuredefs) do
		wreckDef.metal = commanderCost * (wreckName == "heap" and 0.2 or 0.4)
		wreckDef.reclaimtime = wreckDef.metal
	end
	
	for key, data in pairs(statOverrides) do
		unitDef[key] = data
	end
	
	for j = 1, 7 do
		unitDef.sfxtypes.explosiongenerators[j] = unitDef.sfxtypes.explosiongenerators[j] or [[custom:NONE]]
	end
	
	for num = 1, #chassisDefs[i].weapons do
		local weaponName = chassisDefs[i].weapons[num]
		DynamicApplyWeapon(unitDef, weaponName, num)
	end
	
	if #chassisDefs[i].weapons > 31 then
		-- Limit of 31 for shield space.
		Spring.Echo("Too many commander weapons on:", name, "Limit is 31, found weapons:", #chassisDefs[i].weapons)
	end
end
