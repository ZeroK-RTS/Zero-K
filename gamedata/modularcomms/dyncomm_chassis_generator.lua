local chassisDefs = {
	{
		name = "dynrecon1",
		weapons = {
			"commweapon_peashooter",
			"commweapon_personal_shield",
			"commweapon_beamlaser",
			"commweapon_lparticlebeam",
			"commweapon_shotgun",
			--slow "commweapon_shotgun",
			--slow "commweapon_shotgun",
			"commweapon_lightninggun",
			"commweapon_flamethrower",
			"commweapon_heatray",
			"commweapon_heavymachinegun",
			--slow "commweapon_heavymachinegun",
			"commweapon_multistunner",
			"commweapon_napalmgrenade",
			"commweapon_clusterbomb",
			"commweapon_disruptorbomb",
		}
	},
	{
		name = "dynsupport1",
		weapons = {
			"commweapon_peashooter",
			"commweapon_personal_shield",
			"commweapon_areashield",
			"commweapon_beamlaser",
			"commweapon_lparticlebeam",
			"commweapon_lightninggun",
			"commweapon_disruptor",
			"commweapon_missilelauncher",
			"commweapon_rocketlauncher",
			-- flaming "commweapon_rocketlauncher",
			"commweapon_hpartillery",
			"commweapon_hpartillery_napalm",
			"commweapon_shockrifle",
			"commweapon_concussion",
			"commweapon_multistunner",
			"commweapon_disruptorbomb",
		}
	},
	{
		name = "dynassault1",
		weapons = {
			"commweapon_peashooter",
			"commweapon_personal_shield",
			"commweapon_areashield",
			"commweapon_heatray",
			"commweapon_heavymachinegun",
			-- slow "commweapon_heavymachinegun",
			"commweapon_flamethrower",
			"commweapon_rocketlauncher",
			-- flaming "commweapon_rocketlauncher",
			"commweapon_hpartillery",
			"commweapon_hpartillery_napalm",
			"commweapon_riotcannon",
			"commweapon_disintegrator",
			"commweapon_slamrocket",
			"commweapon_napalmgrenade",
			"commweapon_clusterbomb",
		}
	},
}

local statOverrides = {
	-- For personal cloak
	cloakcost           = 5,
	cloakcostmoving     = 10, 
	-- For jammer and cloaker toggling
	onoffable           = true,
	maxdamage           = 1235,
}

for i = 1, #chassisDefs do
	local name = chassisDefs[i].name
	local unitDef = UnitDefs[name]
	
	for key, data in pairs(statOverrides) do
		unitDef[key] = data
	end
	
	for num = 1, #chassisDefs[i].weapons do
		weaponName = chassisDefs[i].weapons[num]
		DynamicApplyWeapon(unitDef, weaponName, true, num)
	end
	
	if #chassisDefs[i].weapons > 16 then
		Spring.Echo("Too many commander weapons on:", name, "Limit is 16, found weapons:", #chassisDefs[i].weapons)
	end
end