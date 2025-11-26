
local humanName="Chicken Spike"
local description= "Chicken Spike: Mid range skirmish weapon, can onlt shot at front"

return {
    moduledef={
        commweapon_chickenspike={
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
            name = "commweapon_chickenspike",
			humanName = humanName,
			description = description,
            image = moduleImagePath .. "chickens.png",
            limit = 2,
            cost = 0,
            requireChassis = {"chicken"},
            requireLevel = 1,
            slotType = "basic_weapon",
            applicationFunction = applicationFunctionApplyWeapon(function ()
                return "commweapon_chickenspike"
            end),
            isBasicWeapon=true,
        }}
    end
}