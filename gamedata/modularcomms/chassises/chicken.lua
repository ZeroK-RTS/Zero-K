
local nomainstates={
    collisionvolumescales=true,
    modelradius=true,
    explodeas=true,
    selfdestructas=true,
    footprintx=true,
    footprintz=true,
    movementclass=true
}
return {
    clonedefs={
        dynchicken1 = {
            dynchicken0 = {
                level = 0,
                customparams = {shield_emit_height = 30},
                nomainstats=nomainstates,
            },
            dynchicken2 = {
                level = 2,
                mainstats = {health = 4600},
                customparams = {def_scale=1.2},
                nomainstats=nomainstates,
            },
            dynchicken3 = {
                level = 3,
                mainstats = {health = 5200},
                customparams = {def_scale=1.4},
                nomainstats=nomainstates,
            },
            dynchicken4 = {
                level = 4,
                mainstats = {health = 5800},
                customparams = {def_scale=1.6},
                nomainstats=nomainstates,
            },
            dynchicken5 = {
                level = 5,
                mainstats = {health = 6400},
                customparams = {def_scale=1.7},
                nomainstats=nomainstates,
            },
        },
    },
    dynamic_comm_defs_name="chicken",
    dynamic_comm_defs_modules={
        {
            name = "commweapon_personal_shield",
        },
        {
            name = "module_radarnet",
        },
        {
            requireChassis = {
                "support",
            },
            name = "module_resurrect",
        },
        {
            name = "module_dmg_booster",
        },{
            requireChassis = {
                "assault",
            },
            name = "module_high_power_servos",
        },
        {
            name = "module_adv_targeting",
        },{
            requireChassis = {
                [1] = "recon",
            },
            name = "module_adv_nano",
        },{
            name = "banner_overhead",
        },
    },
    dynamic_comm_defs=function(shared)
        shared=ModularCommDefsShared or shared
        local extraLevelCostFunction=shared.extraLevelCostFunction
        local morphBuildPower=shared.morphBuildPower
        local morphCosts=shared.morphCosts
        local COST_MULT=shared.COST_MULT
        local GetCloneModuleString=shared.GetCloneModuleString
        local morphUnitDefFunction=shared.morphUnitDefFunction
        local mymorphUnitDefFunction=morphUnitDefFunction("dynchicken",GetCloneModuleString("chicken",{
            "commweapon_personal_shield","commweapon_chickenshield"
        }))
        local moduleDefNames=shared.moduleDefNames

        return {
            name = "chicken",
            humanName = "Chicken",
            baseUnitDef = UnitDefNames and UnitDefNames["dynchicken0"].id,
            extraLevelCostFunction = extraLevelCostFunction,
            maxNormalLevel = 5,
            secondPeashooter = false,
            chassisImage="unitpics/chickenbroodqueen.png",
            initWeapon="commweapon_chickenspores",
            levelDefs = {
                [0] = {
                    morphBuildPower = 5,
                    morphBaseCost = 0,
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 5
                    end,
                    morphUnitDefFunction = mymorphUnitDefFunction(1),
                    upgradeSlots = {},
                },
                [1] = {
                    morphBuildPower = morphBuildPower[1],
                    morphBaseCost = morphCosts[1],
                    chassisApplicationFunction = function (modules, sharedData)
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 8
                    end,
                    morphUnitDefFunction = mymorphUnitDefFunction(1),
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.chicken.commweapon_chickenspores,
                            slotAllows = "basic_weapon",
                        },
                        {
                            defaultModule = moduleDefNames.chicken.nullmodule,
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
                    morphUnitDefFunction = mymorphUnitDefFunction(2),
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
                        sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 16
                    end,
                    morphUnitDefFunction = mymorphUnitDefFunction(3),
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.chicken.commweapon_beamlaser_adv,
                            slotAllows = {"dual_basic_weapon", "adv_weapon"},
                        },
                        {
                            defaultModule = moduleDefNames.chicken.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.chicken.nullmodule,
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
                    morphUnitDefFunction = mymorphUnitDefFunction(4),
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.chicken.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.chicken.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.chicken.nullmodule,
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
                    morphUnitDefFunction = mymorphUnitDefFunction(5),
                    upgradeSlots = {
                        {
                            defaultModule = moduleDefNames.chicken.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.chicken.nullmodule,
                            slotAllows = "module",
                        },
                        {
                            defaultModule = moduleDefNames.chicken.nullmodule,
                            slotAllows = "module",
                        },
                    },
                },
            }
        }
    end,
    dyncomm_chassis_generator={
        name="dynchicken1",
        weapons={
            --"commweapon_beamlaser",
            "commweapon_chickenclaw",
            "commweapon_chickenclaw",
            "commweapon_chickengoo",
            "commweapon_chickenspike",
            "commweapon_chickenspike",
            "commweapon_chickenspores",
            "commweapon_chickenspores",
            "commweapon_chickenflamethrower",
            "commweapon_chickenflamethrower",
            --"commweapon_personal_shield",
        }
    },
    dyncomms_predefined={
        dyntrainer_chicken = {
            name = "Chicken",
            chassis = "chicken",
    
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
"dynchicken",
	{{0,0}, {1,0}, {1,1}, {1,1}, {1,1}},
	{"module_personal_shield","module_chickenshield"}
    }
}