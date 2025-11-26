
local humanName="Chicken Spores"
local description= "Chicken Spores: Chasing Projectile, x0.5 damage vs ground"
return {
    moduledef={
        commweapon_chickenspores={
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
            name = "commweapon_chickenspores",
			humanName = humanName,
			description = description,
            image = moduleImagePath .. "chickend.png",
            limit = 2,
            cost = 0,
            requireChassis = {"chicken"},
            requireLevel = 1,
            slotType = "basic_weapon",
            applicationFunction = applicationFunctionApplyWeapon(function ()
                return "commweapon_chickenspores"
            end),
            isBasicWeapon=true,
        }}
    end
}