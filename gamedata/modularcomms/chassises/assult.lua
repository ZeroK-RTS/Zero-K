return {
    clonedefs={
        dynassault1 = {
            dynassault0 = {
                level = 0,
                customparams = {shield_emit_height = 32.5},
            },
            dynassault2 = {
                level = 2,
                collisionvolumescales  = [[50 60 50]],
                mainstats = {health = 5000, objectname = "benzcom2.s3o"},
                customparams = {modelradius = [[30]], shield_emit_height = 35.75},
                wreckmodel = "benzcom2_wreck.s3o",
            },
            dynassault3 = {
                level = 3,
                collisionvolumescales  = [[55 65 55]],
                mainstats = {health = 5700, objectname = "benzcom3.s3o",},
                customparams = {modelradius = [[33]], shield_emit_height = 39},
                wreckmodel = "benzcom3_wreck.s3o",
            },
            dynassault4 = {
                level = 4,
                collisionvolumescales  = [[58 68 58]],
                mainstats = {health = 6600, objectname = "benzcom4.s3o",},
                customparams = {modelradius = [[34]], shield_emit_height = 40.625},
                wreckmodel = "benzcom4_wreck.s3o",
            },
            dynassault5 = {
                level = 5,
                collisionvolumescales  = [[60 71 60]],
                mainstats = {health = 7600, objectname = "benzcom5.s3o",},
                customparams = {modelradius = [[36]], shield_emit_height = 42.25},
                wreckmodel = "benzcom5_wreck.s3o",
            },
        },
    },
    dynamic_comm_defs_name="assault",
    dynamic_comm_defs=function(shared)
        
        shared=ModularCommDefsShared or shared
        local extraLevelCostFunction=shared.extraLevelCostFunction
        local morphBuildPower=shared.morphBuildPower
        local morphCosts=shared.morphCosts
        local COST_MULT=shared.COST_MULT
        local GetCloneModuleString=shared.GetCloneModuleString
        local morphUnitDefFunction=shared.morphUnitDefFunction
        local moduleDefNames=shared.moduleDefNames

        local function GetAssaultCloneModulesString(modulesByDefID)
            return (modulesByDefID[moduleDefNames.assault.commweapon_personal_shield] or 0) ..
                (modulesByDefID[moduleDefNames.assault.commweapon_areashield] or 0)
        end

        return {
            name = "assault",
            humanName = "Guardian",
            baseUnitDef = UnitDefNames and UnitDefNames["dynassault0"].id,
            extraLevelCostFunction = extraLevelCostFunction,
            maxNormalLevel = 5,
            secondPeashooter = false,
            levelDefs = {
                [0] = {
                    morphBuildPower = 5,
                    morphBaseCost = 0,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                        sharedData.drones = (sharedData.drones or 0) + 1
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynassault0"].id
                    end,
                    upgradeSlots = {},
                },
                [1] = {
                    morphBuildPower = morphBuildPower[1],
                    morphBaseCost = morphCosts[1],
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                        sharedData.drones = (sharedData.drones or 0) + 1
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynassault1_" .. GetAssaultCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.assault.commweapon_beamlaser,
                            slotAllows = "basic_weapon",
                        },
                        {
                            defaultModule = moduleDefNames.assault.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
                [2] = {
                    morphBuildPower = morphBuildPower[2],
                    morphBaseCost = morphCosts[2] * COST_MULT,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                        sharedData.drones = (sharedData.drones or 0) + 2
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynassault2_" .. GetAssaultCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.assault.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.assault.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
                [3] = {
                    morphBuildPower = morphBuildPower[3],
                    morphBaseCost = morphCosts[3] * COST_MULT,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                        sharedData.drones = (sharedData.drones or 0) + 2
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynassault3_" .. GetAssaultCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.assault.commweapon_beamlaser_adv,
                            slotAllows = {"dual_basic_weapon", "adv_weapon"},
                        },
                        {
                            defaultModule = moduleDefNames.assault.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.assault.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
                [4] = {
                    morphBuildPower = morphBuildPower[4],
                    morphBaseCost = morphCosts[4] * COST_MULT,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                        sharedData.drones = (sharedData.drones or 0) + 2
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynassault4_" .. GetAssaultCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.assault.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.assault.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.assault.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
                [5] = {
                    morphBuildPower = morphBuildPower[5],
                    morphBaseCost = morphCosts[5] * COST_MULT,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                        sharedData.drones = (sharedData.drones or 0) + 3
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynassault5_" .. GetAssaultCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.assault.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.assault.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.assault.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
            }
        }
    end,
    dyncomm_chassis_generator={
        name = "dynassault1",
        weapons = {
            "commweapon_peashooter",
            "commweapon_rocketlauncher", -- 430
            "commweapon_rocketlauncher_napalm", -- 430
            "commweapon_rocketlauncher", -- 430
            "commweapon_rocketlauncher_napalm", -- 430
            "commweapon_beamlaser",
            "commweapon_heatray",
            "commweapon_heavymachinegun",
            "commweapon_flamethrower",
            "commweapon_riotcannon",
            "commweapon_riotcannon_napalm",
            "commweapon_peashooter",
            "commweapon_beamlaser",
            "commweapon_heatray",
            "commweapon_heavymachinegun",
            "commweapon_flamethrower",
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
    dyncomms_predefined={
        dyntrainer_assault = {
            name = "Guardian",
            chassis = "assault",
            modules = {
                {"commweapon_heavymachinegun", "module_radarnet"},
                {"module_ablative_armor", "module_autorepair"},
                {"commweapon_shotgun", "commweapon_personal_shield", "module_heavy_armor"},
                {"module_dmg_booster", "module_dmg_booster", "module_heavy_armor"},
                {"conversion_disruptor","module_dmg_booster", "module_heavy_armor"},
            },
            --decorations = {"banner_overhead"},
            --images = {overhead = "166"}
        },
    },
    staticcomms={
        "dynassault",
        {{0, 0}, {1, 0}, {1, 1}, {1, 1}, {1, 1}},
        {"module_personal_shield", "module_areashield"}
    }
}