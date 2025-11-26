
local humanName="Chicken Claw"
local description= "Chicken Claw: CLUCK"

return {
    moduledef={
        commweapon_chickenclaw={
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
            name = "commweapon_chickenclaw",
			humanName = humanName,
			description = description,
            image = moduleImagePath .. "chickena.png",
            limit = 2,
            cost = 0,
            requireChassis = {"chicken"},
            requireLevel = 1,
            slotType = "basic_weapon",
            applicationFunction = applicationFunctionApplyWeapon(function ()
                return "commweapon_chickenclaw"
            end),
            isBasicWeapon=true,
        }}
    end
}