return{
    moduledef={
        commweapon_flamethrower={
            name="Flamethrower",
		    description="Flamethrower: Good for deep-frying swarmers and large targets alike",
        }
    },
    dynamic_comm_def=function (shared)
		shared=ModularCommDefsShared or shared
		local moduleImagePath=shared.moduleImagePath
		local COST_MULT=shared.COST_MULT
		local HP_MULT=shared.HP_MULT
        
        local moddef={
            name = "commweapon_flamethrower",
            humanName = "Flamethrower",
            description = "Flamethrower: Good for deep-frying swarmers and large targets alike",
            image = moduleImagePath .. "commweapon_flamethrower.png",
            limit = 2,
            cost = 0,
            requireChassis = {"recon", "assault", "knight"},
            requireLevel = 1,
            slotType = "basic_weapon",
            applicationFunction = function (modules, sharedData)
                if sharedData.noMoreWeapons then
                    return
                end
                if not sharedData.weapon1 then
                    sharedData.weapon1 = "commweapon_flamethrower"
                else
                    sharedData.weapon2 = "commweapon_flamethrower"
                end
            end,
            hardcodedID=6,
        }
        local GenAdvWeaponModule=shared.GenAdvWeaponModule
        local moddef2=GenAdvWeaponModule(moddef)
        moddef2.hardcodedID=53
        --lazy remove(moddef2.requireChassis,"knight")
        moddef2.requireChassis[#moddef2.requireChassis]=nil
        --lazy remove(moddef2.requireChassis,"knight")
        
		return {moddef,moddef2}
    end
}