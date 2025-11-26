
local humanName="Chicken Blob"
local description= humanName .. " - Blob, can only shot at front, replace other weapons"

return {
    moduledef={
        commweapon_chickengoo={
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
            name = "commweapon_chickengoo",
			humanName = humanName,
			description = description,
            image = moduleImagePath .. "commweapon_clusterbomb.png",
            limit = 1,
            cost = 0,
            requireChassis = {"chicken"},
            requireLevel = 3,
            slotType = "adv_weapon",
            applicationFunction = applicationFunctionApplyWeapon(function ()
                return "commweapon_chickengoo"
            end),
            --[=[
            function (modules, sharedData)
                if sharedData.noMoreWeapons then
                    return
                end
                local weaponName = "commweapon_chickengoo"
                sharedData.weapon1 = weaponName
                sharedData.weapon2 = nil
                sharedData.noMoreWeapons = true
            end,]=]
            --isBasicWeapon=true,
        }}
    end
}