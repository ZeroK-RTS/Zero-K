commTypes = {
	recon = {
		[1] = CopyTable(UnitDefs.commrecon),
		[2] = CopyTable(UnitDefs.commadvrecon),
	},
	strike = {
		[1] = CopyTable(UnitDefs.armcom),
		[2] = CopyTable(UnitDefs.armadvcom),
	},
	battle = {
		[1] = CopyTable(UnitDefs.corcom),
		[2] = CopyTable(UnitDefs.coradvcom),
	},
	support = {
		[1] = CopyTable(UnitDefs.commsupport),
		[2] = CopyTable(UnitDefs.commadvsupport),
	},
}

upgrades = {
	adv_composite_armor = {
		name = "Advanced Composite Armor",
		description = "Improved armor increases commander health by 20%",
		func = function(unitDef)
				unitDef.maxdamage = unitDef.maxdamage * 1.2
			end,
	},
	focusing_prism = {
		name = "Focusing Prism",
		description = "Reduces laser attenuation - increases primary weapon range by 20%",
		func = function(unitDef)
				if not (unitDef.weapons and unitDef.weapondefs) then return end
				local wepName = (unitDef.weapons[4] and unitDef.weapons[4].def) or (unitDef.weapons[1] and unitDef.weapons[1].def)
				wepName = string.lower(wepName)
				unitDef.weapondefs[wepName].range = unitDef.weapondefs[wepName].range * 1.2
			end,
	},
	high_power_servos = {
		name = "High Power Servos",
		description = "More powerful leg servos increase speed by 20%",
		func = function(unitDef)
				unitDef.maxvelocity = unitDef.maxvelocity * 1.2
			end,
	},
	radarmodule = {
		name = "Radar Module",
		description = "Basic radar module with 1200 range",
		func = function(unitDef)
				if unitDef.radardistance == nil or unitDef.radardistance < 1200 then unitDef.radardistance = 1200 end
			end,
	},
	adv_nano = {
		name = "CarRepairer's Nanolathe",
		description = "Used by a mythical mechanic/coder, this improved nanolathe adds +3 metal/s build speed",
		func = function(unitDef)
				if unitDef.workertime then unitDef.workertime = unitDef.workertime + 3 end
			end,
	},
}

