return {
    clonedefs={
        dynsupport1 = {
            dynsupport0 = {
                level = 0,
                customparams = {shield_emit_height = 36, builddistance = 220},
            },
            dynsupport2 = {
                level = 2,
                mainstats = {health = 4000, objectname = "commsupport2.s3o", aimposoffset = [[0 17 0]], builddistance = 244},
                customparams = {shield_emit_height = 39.6},
                wreckmodel = "commsupport2_dead.s3o",
            },
            dynsupport3 = {
                level = 3,
                mainstats = {health = 4300, objectname = "commsupport3.s3o", aimposoffset = [[0 19 0]], builddistance = 256},
                customparams = {shield_emit_height = 43.62},
                wreckmodel = "commsupport3_dead.s3o",
            },
            dynsupport4 = {
                level = 4,
                mainstats = {health = 4600, objectname = "commsupport4.s3o", aimposoffset = [[0 22 0]], builddistance = 268},
                customparams = {shield_emit_height = 45},
                wreckmodel = "commsupport4_dead.s3o",
            },
            dynsupport5 = {
                level = 5,
                mainstats = {health = 5000, objectname = "commsupport5.s3o", aimposoffset = [[0 25 0]], builddistance = 280},
                customparams = {shield_emit_height = 46.48},
                wreckmodel = "commsupport5_dead.s3o",
            },
        },
    },
    dynamic_comm_defs_name="support",
    dynamic_comm_defs=function(shared)
        
        shared=ModularCommDefsShared or shared
        local extraLevelCostFunction=shared.extraLevelCostFunction
        local morphBuildPower=shared.morphBuildPower
        local morphCosts=shared.morphCosts
        local COST_MULT=shared.COST_MULT
        local GetCloneModuleString=shared.GetCloneModuleString
        local morphUnitDefFunction=shared.morphUnitDefFunction
        local moduleDefNames=shared.moduleDefNames

        local function GetSupportCloneModulesString(modulesByDefID)
            return (modulesByDefID[moduleDefNames.support.commweapon_personal_shield] or 0) ..
                (modulesByDefID[moduleDefNames.support.commweapon_areashield] or 0) ..
                (modulesByDefID[moduleDefNames.support.module_resurrect] or 0)
        end

        return {
            name = "support",
            humanName = "Engineer",
            baseUnitDef = UnitDefNames and UnitDefNames["dynsupport0"].id,
            extraLevelCostFunction = extraLevelCostFunction,
            maxNormalLevel = 5,
            levelDefs = {
                [0] = {
                    morphBuildPower = 5,
                    morphBaseCost = 0,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynsupport0"].id
                    end,
                    upgradeSlots = {},
                },
                [1] = {
                    morphBuildPower = morphBuildPower[1],
                    morphBaseCost = morphCosts[1],
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 2
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynsupport1_" .. GetSupportCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.support.commweapon_beamlaser,
                            slotAllows = "basic_weapon",
                        },
                        {
                            defaultModule = moduleDefNames.support.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
                [2] = {
                    morphBuildPower = morphBuildPower[2],
                    morphBaseCost = morphCosts[2] * COST_MULT,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 4
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynsupport2_" .. GetSupportCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.support.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.support.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
                [3] = {
                    morphBuildPower = morphBuildPower[3],
                    morphBaseCost = morphCosts[3] * COST_MULT,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 6
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynsupport3_" .. GetSupportCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.support.commweapon_disruptorbomb,
                            slotAllows = "adv_weapon",
                        },
                        {
                            defaultModule = moduleDefNames.support.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.support.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
                [4] = {
                    morphBuildPower = morphBuildPower[4],
                    morphBaseCost = morphCosts[4],
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 9
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynsupport4_" .. GetSupportCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.support.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.support.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.support.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
                [5] = {
                    morphBuildPower = morphBuildPower[5],
                    morphBaseCost = morphCosts[5],
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 12
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynsupport5_" .. GetSupportCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.support.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.support.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.support.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
            }
        }
    end,
    dyncomm_chassis_generator={
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
    dyncomms_predefined={
        dyntrainer_support = {
            name = "Engineer",
            chassis = "support",
            modules = {
                {"commweapon_lparticlebeam", "module_radarnet"},
                {"module_ablative_armor", "module_autorepair"},
                {"commweapon_hparticlebeam", "module_personal_cloak", "module_adv_nano"},
                {"module_dmg_booster", "module_adv_targeting", "module_adv_targeting"},
                {"module_adv_targeting", "module_adv_nano", "module_resurrect"},
            },
            --decorations = {"skin_support_hotrod"},
        },
    },
    staticcomms={
"dynsupport",
	{{0, 0, 0}, {1, 0, 1}, {1, 1, 1}, {1, 1, 1}, {1, 1, 1}},
	{"module_personal_shield", "module_areashield", "module_resurrect"}
    }
}