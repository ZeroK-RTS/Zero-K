return {
	clonedefs = {
		dynrecon1 = {
			dynrecon0 = {
				level = 0,
				customparams = { shield_emit_height = 30 },
			},
			dynrecon2 = {
				level = 2,
				mainstats = { health = 3400, objectname = "commrecon2.s3o", aimposoffset = [[0 12 0]] },
				customparams = { shield_emit_height = 33, jump_reload = 20, jump_speed = 4.75 },
				wreckmodel = "commrecon2_dead.s3o",
			},
			dynrecon3 = {
				level = 3,
				mainstats = { health = 3600, objectname = "commrecon3.s3o", aimposoffset = [[0 14 0]] },
				customparams = { shield_emit_height = 36, jump_reload = 20, jump_speed = 5 },
				wreckmodel = "commrecon3_dead.s3o",
			},
			dynrecon4 = {
				level = 4,
				mainstats = { health = 3800, objectname = "commrecon4.s3o", aimposoffset = [[0 16 0]] },
				customparams = { shield_emit_height = 37.5, jump_reload = 18, jump_speed = 5.25 },
				wreckmodel = "commrecon4_dead.s3o",
			},
			dynrecon5 = {
				level = 5,
				mainstats = { health = 4000, objectname = "commrecon5.s3o", aimposoffset = [[0 18 0]] },
				customparams = { shield_emit_height = 39, jump_reload = 16, jump_speed = 5.5 },
				wreckmodel = "commrecon5_dead.s3o",
			},
		},
	},
	dynamic_comm_defs_name = "recon",
	---@param shared ModularCommDefsShared
	dynamic_comm_defs = function(shared)
		local extraLevelCostFunction = shared.extraLevelCostFunction
		local morphBuildPower = shared.morphBuildPower
		local morphCosts = shared.morphCosts
		local COST_MULT = shared.COST_MULT
		local GetCloneModuleString = shared.GetCloneModuleString
		local morphUnitDefFunction = shared.morphUnitDefFunction
		local moduleDefNames = shared.moduleDefNames

		local function GetReconCloneModulesString(modulesByDefID)
			return (modulesByDefID[moduleDefNames.recon.commweapon_personal_shield] or 0)
		end

		return {
			name = "recon",
			humanName = "Recon",
			baseUnitDef = UnitDefNames and UnitDefNames["dynrecon0"].id,
			extraLevelCostFunction = extraLevelCostFunction,
			maxNormalLevel = 5,
			levelDefs = {
				[0] = {
					morphBuildPower = 5,
					morphBaseCost = 0,
					chassisApplicationFunction = function(modules, sharedData)
						sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
					end,
					morphUnitDefFunction = function(modulesByDefID)
						return UnitDefNames["dynrecon0"].id
					end,
					upgradeSlots = {},
				},
				[1] = {
					morphBuildPower = morphBuildPower[1],
					morphBaseCost = morphCosts[1],
					chassisApplicationFunction = function(modules, sharedData)
						sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
					end,
					morphUnitDefFunction = function(modulesByDefID)
						return UnitDefNames["dynrecon1_" .. GetReconCloneModulesString(modulesByDefID)].id
					end,
					upgradeSlots = {
						{
							defaultModule = moduleDefNames.recon.commweapon_beamlaser,
							slotAllows = "basic_weapon",
						},
						{
							defaultModule = moduleDefNames.recon.nullmodule,
							slotAllows = "module",
						},
					},
				},
				[2] = {
					morphBuildPower = morphBuildPower[2],
					morphBaseCost = morphCosts[2] * COST_MULT,
					chassisApplicationFunction = function(modules, sharedData)
						sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
					end,
					morphUnitDefFunction = function(modulesByDefID)
						return UnitDefNames["dynrecon2_" .. GetReconCloneModulesString(modulesByDefID)].id
					end,
					upgradeSlots = {
						{
							defaultModule = moduleDefNames.recon.nullmodule,
							slotAllows = "module",
						},
						{
							defaultModule = moduleDefNames.recon.nullmodule,
							slotAllows = "module",
						},
					},
				},
				[3] = {
					morphBuildPower = morphBuildPower[3],
					morphBaseCost = morphCosts[3] * COST_MULT,
					chassisApplicationFunction = function(modules, sharedData)
						sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
					end,
					morphUnitDefFunction = function(modulesByDefID)
						return UnitDefNames["dynrecon3_" .. GetReconCloneModulesString(modulesByDefID)].id
					end,
					upgradeSlots = {
						{
							defaultModule = moduleDefNames.recon.commweapon_disruptorbomb,
							slotAllows = "adv_weapon",
						},
						{
							defaultModule = moduleDefNames.recon.nullmodule,
							slotAllows = "module",
						},
						{
							defaultModule = moduleDefNames.recon.nullmodule,
							slotAllows = "module",
						},
					},
				},
				[4] = {
					morphBuildPower = morphBuildPower[4],
					morphBaseCost = morphCosts[4] * COST_MULT,
					chassisApplicationFunction = function(modules, sharedData)
						sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
					end,
					morphUnitDefFunction = function(modulesByDefID)
						return UnitDefNames["dynrecon4_" .. GetReconCloneModulesString(modulesByDefID)].id
					end,
					upgradeSlots = {
						{
							defaultModule = moduleDefNames.recon.nullmodule,
							slotAllows = "module",
						},
						{
							defaultModule = moduleDefNames.recon.nullmodule,
							slotAllows = "module",
						},
						{
							defaultModule = moduleDefNames.recon.nullmodule,
							slotAllows = "module",
						},
					},
				},
				[5] = {
					morphBuildPower = morphBuildPower[5],
					morphBaseCost = morphCosts[5] * COST_MULT,
					chassisApplicationFunction = function(modules, sharedData)
						sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
					end,
					morphUnitDefFunction = function(modulesByDefID)
						return UnitDefNames["dynrecon5_" .. GetReconCloneModulesString(modulesByDefID)].id
					end,
					upgradeSlots = {
						{
							defaultModule = moduleDefNames.recon.nullmodule,
							slotAllows = "module",
						},
						{
							defaultModule = moduleDefNames.recon.nullmodule,
							slotAllows = "module",
						},
						{
							defaultModule = moduleDefNames.recon.nullmodule,
							slotAllows = "module",
						},
					},
				},
			}
		}
	end,

	dyncomm_chassis_generator = {
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
	dyncomms_predefined = {
		dyntrainer_recon = {
			name = "Recon",
			chassis = "recon",
			modules = {
				{ "commweapon_heavymachinegun", "module_radarnet" },
				{ "module_ablative_armor",      "module_autorepair" },
				{ "commweapon_clusterbomb",     "commweapon_personal_shield", "module_ablative_armor" },
				{ "module_high_power_servos",   "module_ablative_armor",      "module_dmg_booster" },
				{ "module_high_power_servos",   "module_ablative_armor",      "module_dmg_booster" },
			},
			--decorations = {"skin_recon_dark", "banner_overhead"},
			--images = {overhead = "184"}
		},
	},
	staticcomms = {
		"dynrecon",
		{ { 0 },                   { 1 }, { 1 }, { 1 }, { 1 } },
		{ "module_personal_shield" }
	}
}
