return {
	clonedefs = {
		dynstrike1 = {
			dynstrike0 = {
				level = 0,
				customparams = { shield_emit_height = 38 },
			},
			dynstrike2 = {
				level = 2,
				mainstats = { health = 4600, objectname = "strikecom_1.dae", collisionvolumescales = [[50 55 50]], },
				customparams = { modelradius = [[28]], shield_emit_height = 41.8 },
				wreckmodel = "strikecom_dead_1.dae",
			},
			dynstrike3 = {
				level = 3,
				mainstats = { health = 5200, objectname = "strikecom_2.dae", collisionvolumescales = [[55 60 55]], },
				customparams = { modelradius = [[30]], shield_emit_height = 45.6 },
				wreckmodel = "strikecom_dead_2.dae",
			},
			dynstrike4 = {
				level = 4,
				mainstats = { health = 5800, objectname = "strikecom_3.dae", collisionvolumescales = [[58 66 58]], },
				customparams = { modelradius = [[33]], shield_emit_height = 47.5 },
				wreckmodel = "strikecom_dead_3.dae",
			},
			dynstrike5 = {
				level = 5,
				mainstats = { health = 6400, objectname = "strikecom_4.dae", collisionvolumescales = [[60 72 60]], },
				customparams = { modelradius = [[36]], shield_emit_height = 49.4 },
				wreckmodel = "strikecom_dead_4.dae",
			},
		}
	},
	dynamic_comm_defs_name = "strike",
	---@param shared ModularCommDefsShared
	dynamic_comm_defs = function(shared)
		local extraLevelCostFunction = shared.extraLevelCostFunction
		local morphBuildPower = shared.morphBuildPower
		local morphCosts = shared.morphCosts
		local COST_MULT = shared.COST_MULT
		local GetCloneModuleString = shared.GetCloneModuleString
		local morphUnitDefFunction = shared.morphUnitDefFunction
		local moduleDefNames = shared.moduleDefNames


		local function GetStrikeCloneModulesString(modulesByDefID)
			return (modulesByDefID[moduleDefNames.strike.commweapon_personal_shield] or 0) ..
				(modulesByDefID[moduleDefNames.strike.commweapon_areashield] or 0)
		end

		return {
			name = "strike",
			humanName = "Strike",
			baseUnitDef = UnitDefNames and UnitDefNames["dynstrike0"].id,
			extraLevelCostFunction = extraLevelCostFunction,
			maxNormalLevel = 5,
			secondPeashooter = false,
			levelDefs = {
				[0] = {
					morphBuildPower = 5,
					morphBaseCost = 0,
					chassisApplicationFunction = function(modules, sharedData)
						sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
					end,
					morphUnitDefFunction = function(modulesByDefID)
						return UnitDefNames["dynstrike0"].id
					end,
					upgradeSlots = {},
				},
				[1] = {
					morphBuildPower = morphBuildPower[1],
					morphBaseCost = morphCosts[1],
					chassisApplicationFunction = function(modules, sharedData)
						sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 8
					end,
					morphUnitDefFunction = function(modulesByDefID)
						return UnitDefNames["dynstrike1_" .. GetStrikeCloneModulesString(modulesByDefID)].id
					end,
					upgradeSlots = {
						{
							defaultModule = moduleDefNames.strike.commweapon_beamlaser,
							slotAllows = "basic_weapon",
						},
						{
							defaultModule = moduleDefNames.strike.nullmodule,
							slotAllows = "module",
						},
					},
				},
				[2] = {
					morphBuildPower = morphBuildPower[2],
					morphBaseCost = morphCosts[2] * COST_MULT,
					chassisApplicationFunction = function(modules, sharedData)
						sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 12
					end,
					morphUnitDefFunction = function(modulesByDefID)
						return UnitDefNames["dynstrike2_" .. GetStrikeCloneModulesString(modulesByDefID)].id
					end,
					upgradeSlots = {
						{
							defaultModule = moduleDefNames.strike.nullmodule,
							slotAllows = "module",
						},
						{
							defaultModule = moduleDefNames.strike.nullmodule,
							slotAllows = "module",
						},
					},
				},
				[3] = {
					morphBuildPower = morphBuildPower[3],
					morphBaseCost = morphCosts[3] * COST_MULT,
					chassisApplicationFunction = function(modules, sharedData)
						sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 16
					end,
					morphUnitDefFunction = function(modulesByDefID)
						return UnitDefNames["dynstrike3_" .. GetStrikeCloneModulesString(modulesByDefID)].id
					end,
					upgradeSlots = {
						{
							defaultModule = moduleDefNames.strike.commweapon_beamlaser_adv,
							slotAllows = { "dual_basic_weapon", "adv_weapon" },
						},
						{
							defaultModule = moduleDefNames.strike.nullmodule,
							slotAllows = "module",
						},
						{
							defaultModule = moduleDefNames.strike.nullmodule,
							slotAllows = "module",
						},
					},
				},
				[4] = {
					morphBuildPower = morphBuildPower[4],
					morphBaseCost = morphCosts[4] * COST_MULT,
					chassisApplicationFunction = function(modules, sharedData)
						sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 20
					end,
					morphUnitDefFunction = function(modulesByDefID)
						return UnitDefNames["dynstrike4_" .. GetStrikeCloneModulesString(modulesByDefID)].id
					end,
					upgradeSlots = {
						{
							defaultModule = moduleDefNames.strike.nullmodule,
							slotAllows = "module",
						},
						{
							defaultModule = moduleDefNames.strike.nullmodule,
							slotAllows = "module",
						},
						{
							defaultModule = moduleDefNames.strike.nullmodule,
							slotAllows = "module",
						},
					},
				},
				[5] = {
					morphBuildPower = morphBuildPower[5],
					morphBaseCost = morphCosts[5] * COST_MULT,
					chassisApplicationFunction = function(modules, sharedData)
						sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 25
					end,
					morphUnitDefFunction = function(modulesByDefID)
						return UnitDefNames["dynstrike5_" .. GetStrikeCloneModulesString(modulesByDefID)].id
					end,
					upgradeSlots = {
						{
							defaultModule = moduleDefNames.strike.nullmodule,
							slotAllows = "module",
						},
						{
							defaultModule = moduleDefNames.strike.nullmodule,
							slotAllows = "module",
						},
						{
							defaultModule = moduleDefNames.strike.nullmodule,
							slotAllows = "module",
						},
					},
				},
			}
		}
	end,
	dyncomm_chassis_generator = {
		name = "dynstrike1",
		weapons = {
			"commweapon_peashooter",
			"commweapon_missilelauncher", -- 415
			"commweapon_missilelauncher", -- 415
			"commweapon_beamlaser",
			"commweapon_lparticlebeam",
			"commweapon_shotgun",
			"commweapon_shotgun_disrupt",
			"commweapon_disruptor",
			"commweapon_heavymachinegun",
			"commweapon_heavymachinegun_disrupt",
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
			"commweapon_lightninggun",
			"commweapon_lightninggun_improved",
			"commweapon_multistunner",
			"commweapon_multistunner_improved",
			"commweapon_disruptorbomb",
			"commweapon_disintegrator",
			-- Space for shield
		}
	},
	dyncomms_predefined = {
		dyntrainer_strike = {
			name = "Strike",
			chassis = "strike",
			modules = {
				{ "commweapon_heavymachinegun", "module_radarnet" },
				{ "module_ablative_armor",      "module_autorepair" },
				{ "commweapon_lightninggun",    "module_personal_cloak", "module_ablative_armor" },
				{ "module_high_power_servos",   "module_ablative_armor", "module_dmg_booster" },
				{ "module_high_power_servos",   "module_ablative_armor", "module_dmg_booster" },
			},
			--decorations = {"banner_overhead"},
			--images = {overhead = "184"}
		},
	},
	staticcomms = {
		"dynstrike",
		{ { 0, 0 },                 { 1, 0 },           { 1, 1 }, { 1, 1 }, { 1, 1 } },
		{ "module_personal_shield", "module_areashield" }
	}
}
