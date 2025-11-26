return {
    clonedefs={
        dynknight1 = {
            dynknight0 = {
                level = 0,
                customparams = {shield_emit_height = 30},
            },
            dynknight2 = {
                level = 2,
                mainstats = {health = 4600, objectname = "cremcom2.s3o", collisionvolumescales  = [[50 55 50]],},
                customparams = {modelradius = [[28]], shield_emit_height = 33},
                wreckmodel = "cremcom2_dead.s3o",
            },
            dynknight3 = {
                level = 3,
                mainstats = {health = 5200, objectname = "cremcom3.s3o", collisionvolumescales  = [[55 60 55]],},
                customparams = {modelradius = [[30]], shield_emit_height = 36},
                wreckmodel = "cremcom3_dead.s3o",
            },
            dynknight4 = {
                level = 4,
                mainstats = {health = 5800, objectname = "cremcom4.s3o", collisionvolumescales  = [[60 65 60]],},
                customparams = {modelradius = [[33]], shield_emit_height = 37.5},
                wreckmodel = "cremcom4_dead.s3o",
            },
            dynknight5 = {
                level = 5,
                mainstats = {health = 6400, objectname = "cremcom5.s3o", collisionvolumescales  = [[65 70 65]],},
                customparams = {modelradius = [[35]], shield_emit_height = 39},
                wreckmodel = "cremcom5_dead.s3o",
            },
        },
    },
    dyncomm_chassis_generator={
        name = "dynknight1",
        weapons = {
            -- Aiming from earlier weapons is overridden by later
            "commweapon_peashooter",
            "commweapon_rocketlauncher", -- 430
            "commweapon_rocketlauncher_napalm", -- 430
            "commweapon_missilelauncher", -- 415
            "commweapon_hparticlebeam", -- 390
            "commweapon_beamlaser", -- 330
            "commweapon_lightninggun", -- 300
            "commweapon_lightninggun_improved", -- 300
            "commweapon_lparticlebeam", -- 300
            "commweapon_riotcannon", -- 300
            "commweapon_riotcannon_napalm", -- 300
            "commweapon_disruptor", -- 300
            "commweapon_heatray", -- 300
            "commweapon_shotgun", -- 290
            "commweapon_shotgun_disrupt", -- 290
            "commweapon_heavymachinegun", -- 285
            "commweapon_heavymachinegun_disrupt", -- 285
            "commweapon_flamethrower", -- 270
            "commweapon_multistunner",
            "commweapon_multistunner_improved",
            "commweapon_peashooter",
            "commweapon_hpartillery",
            "commweapon_hpartillery_napalm",
            "commweapon_disintegrator",
            "commweapon_napalmgrenade",
            "commweapon_slamrocket",
            "commweapon_disruptorbomb",
            "commweapon_concussion",
            "commweapon_clusterbomb",
            "commweapon_shockrifle",
            -- Space for shield
        }
    },
    dynamic_comm_defs_name="knight",
    dynamic_comm_defs=function(shared)
        
        shared=ModularCommDefsShared or shared
        local extraLevelCostFunction=shared.extraLevelCostFunction
        local morphBuildPower=shared.morphBuildPower
        local morphCosts=shared.morphCosts
        local COST_MULT=shared.COST_MULT
        local GetCloneModuleString=shared.GetCloneModuleString
        local morphUnitDefFunction=shared.morphUnitDefFunction
        local moduleDefNames=shared.moduleDefNames


        local function GetKnightCloneModulesString(modulesByDefID)
            return (modulesByDefID[moduleDefNames.knight.commweapon_personal_shield] or 0) ..
                (modulesByDefID[moduleDefNames.knight.commweapon_areashield] or 0) ..
                (modulesByDefID[moduleDefNames.knight.module_resurrect] or 0) ..
                (modulesByDefID[moduleDefNames.knight.module_jumpjet] or 0)
        end

        return {
            name = "knight",
            humanName = "Knight",
            baseUnitDef = UnitDefNames and UnitDefNames["dynknight0"].id,
            extraLevelCostFunction = extraLevelCostFunction,
            maxNormalLevel = 5,
            notSelectable = (Spring.GetModOptions().campaign_chassis ~= "1"),
            secondPeashooter = true,
            levelDefs = {
                [0] = {
                    morphBuildPower = 5,
                    morphBaseCost = 0,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        -- Level 1 is the same as level 0 in stats and has support for clone modules (such as shield).
                        return UnitDefNames["dynknight1_" .. GetKnightCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {},
                },
                [1] = {
                    morphBuildPower = morphBuildPower[1],
                    morphBaseCost = morphCosts[1],
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 8
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynknight1_" .. GetKnightCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.knight.commweapon_beamlaser,
                            slotAllows = "basic_weapon",
                        },
                        {
                            defaultModule = moduleDefNames.knight.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
                [2] = {
                    morphBuildPower = morphBuildPower[2],
                    morphBaseCost = morphCosts[2] * COST_MULT,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 12
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynknight2_" .. GetKnightCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.knight.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.knight.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
                [3] = {
                    morphBuildPower = morphBuildPower[3],
                    morphBaseCost = morphCosts[3] * COST_MULT,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 16
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynknight3_" .. GetKnightCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.knight.commweapon_beamlaser_adv,
                            slotAllows = {"dual_basic_weapon", "adv_weapon"},
                        },
                        {
                            defaultModule = moduleDefNames.knight.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.knight.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
                [4] = {
                    morphBuildPower = morphBuildPower[4],
                    morphBaseCost = morphCosts[4] * COST_MULT,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 20
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynknight4_" .. GetKnightCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.knight.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.knight.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.knight.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
                [5] = {
                    morphBuildPower = morphBuildPower[5],
                    morphBaseCost = morphCosts[5] * COST_MULT,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 25
                    end,
                    morphUnitDefFunction = function(modulesByDefID)
                        return UnitDefNames["dynknight5_" .. GetKnightCloneModulesString(modulesByDefID)].id
                    end,
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.knight.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.knight.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.knight.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
            }
        }
    end,
    dyncomms_predefined={
        dyntrainer_knight={
            name = "Campaign",
            chassis = "knight",
        
            modules = { -- all null because nabs want to personalize
                {"nullbasicweapon", "nullmodule"},
                {"nullmodule", "nullmodule"},
                {"nulladvweapon", "nullmodule", "nullmodule"},
                {"nullmodule", "nullmodule", "nullmodule"},
                {"nullmodule", "nullmodule", "nullmodule"},
            },
        }
    },
    staticcomms={
"dynknight",
	{{1, 1, 1, 1}, {1, 1, 1, 1}, {1, 1, 1, 1}, {1, 1, 1, 1}, {1, 1, 1, 1}},
	{"module_personal_shield", "module_areashield", "module_resurrect", "module_jumpjet"}
    }
}