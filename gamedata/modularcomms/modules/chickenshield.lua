
local humanName="Chicken Shield"
local description= humanName.." - Generates a weak but high regen shield"

return {
    moduledef={
        module_chickenshield={
            name=humanName,
    		description=description,order = 5,
            func = function(unitDef)
                if unitDef.customparams.dynamic_comm then
---@diagnostic disable-next-line: undefined-global
                  DynamicApplyWeapon(unitDef, "commweapon_chickenshield", #unitDef.weapons + 1)
                else
---@diagnostic disable-next-line: undefined-global
                  ApplyWeapon(unitDef, "commweapon_chickenshield", 4)
                end
              end,
        }
    },
    dynamic_comm_def=function (shared)
		shared=ModularCommDefsShared or shared
		--local shared=ModularCommDefsShared
        local moduleImagePath=shared.moduleImagePath
        local applicationFunctionApplyWeapon=shared.applicationFunctionApplyWeapon
        local COST_MULT=shared.COST_MULT
        return {{
            name = "commweapon_chickenshield",
            humanName = humanName,
            description = description,
            image = moduleImagePath .. "module_personal_shield.png",
            limit = 1,
            cost = 300 * COST_MULT,
            prohibitingModules = {"module_personal_cloak"},
            requireOneOf = {"commweapon_personal_shield"},
            requireChassis = {"chicken"},
            requireLevel = 3,
            slotType = "module",

            applicationFunction = function (modules, sharedData)
                -- Do not override area shield
                sharedData.shield = "commweapon_chickenshield"
            end
        }}
    end
}