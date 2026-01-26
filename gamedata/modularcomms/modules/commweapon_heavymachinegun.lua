return{
    moduledef={
        commweapon_heavymachinegun={
            name="Machine Gun",
		    description="Machine Gun: Close-in automatic weapon with AoE",
        }
    },
    dynamic_comm_def=function (shared)
		shared=ModularCommDefsShared or shared
		local moduleImagePath=shared.moduleImagePath
		local COST_MULT=shared.COST_MULT
		local HP_MULT=shared.HP_MULT
        local moduleDefNamesToIDs=shared.moduleDefNamesToIDs
        
        local moddef={
            name = "commweapon_heavymachinegun",
            humanName = "Machine Gun",
            description = "Machine Gun: Close-in automatic weapon with AoE",
            image = moduleImagePath .. "commweapon_heavymachinegun.png",
            limit = 2,
            cost = 0,
            requireChassis = {"recon", "assault", "strike", "knight"},
            requireLevel = 1,
            slotType = "basic_weapon",
            applicationFunction = function (modules, sharedData)
                if sharedData.noMoreWeapons then
                    return
                end
                local weaponName = (modules[moduleDefNamesToIDs.conversion_disruptor[1]] and "commweapon_heavymachinegun_disrupt") or "commweapon_heavymachinegun"
                if not sharedData.weapon1 then
                    sharedData.weapon1 = weaponName
                else
                    sharedData.weapon2 = weaponName
                end
            end,
            hardcodedID=8
        }
        local GenAdvWeaponModule=shared.GenAdvWeaponModule
        local moddef2=GenAdvWeaponModule(moddef)
        moddef2.hardcodedID=55
        --lazy remove(moddef2.requireChassis,"knight")
        moddef2.requireChassis[#moddef2.requireChassis]=nil
        --lazy remove(moddef2.requireChassis,"knight")
		return {moddef,moddef2}
    end
}