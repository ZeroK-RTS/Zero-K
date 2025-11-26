
local humanName="Flame Thrower"
local description= "Flame Thrower"
return {
    moduledef={
        commweapon_chickenflamethrower={
            name=humanName,
		    description=description,
        }
    },
    dynamic_comm_def=function (shared)
		shared=ModularCommDefsShared or shared
		local moduleImagePath=shared.moduleImagePath
		local COST_MULT=shared.COST_MULT
		local HP_MULT=shared.HP_MULT
        
        local applicationFunctionApplyWeapon=shared.applicationFunctionApplyWeapon
		return {{
            name = "commweapon_chickenflamethrower",
			humanName = humanName,
			description = description,
            image = moduleImagePath .. "commweapon_flamethrower.png",
            limit = 2,
            cost = 0,
            requireChassis = {},-- bugged
            requireLevel = 1,
            slotType = "basic_weapon",
            applicationFunction = applicationFunctionApplyWeapon(function ()
                return "commweapon_chickenflamethrower"
            end),
            isBasicWeapon=true,
        }}
    end
}