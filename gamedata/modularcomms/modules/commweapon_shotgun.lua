return{
    moduledef={
        commweapon_shotgun={
            name="Shotgun",
		    description="Shotgun: Can hammer a single large target or shred several small ones",
        }
    },
    dynamic_comm_def=function (shared)
		shared=ModularCommDefsShared or shared
		local moduleImagePath=shared.moduleImagePath
		local COST_MULT=shared.COST_MULT
		local HP_MULT=shared.HP_MULT
        local moduleDefNamesToIDs=shared.moduleDefNamesToIDs
        
        local moddef={
            name = "commweapon_shotgun",
            humanName = "Shotgun",
            description = "Shotgun: Can hammer a single large target or shred several small ones",
            image = moduleImagePath .. "commweapon_shotgun.png",
            limit = 2,
            cost = 0,
            requireChassis = {"recon", "support", "strike", "knight"},
            requireLevel = 1,
            slotType = "basic_weapon",
            applicationFunction = function (modules, sharedData)
                if sharedData.noMoreWeapons then
                    return
                end
                local weaponName = (modules[moduleDefNamesToIDs.conversion_disruptor[1]] and "commweapon_shotgun_disrupt") or "commweapon_shotgun"
                if not sharedData.weapon1 then
                    sharedData.weapon1 = weaponName
                else
                    sharedData.weapon2 = weaponName
                end
            end,
            hardcodedID=14
        }
        local GenAdvWeaponModule=shared.GenAdvWeaponModule
        local moddef2=GenAdvWeaponModule(moddef)
        moddef2.hardcodedID=61
        --lazy remove(moddef2.requireChassis,"knight")
        moddef2.requireChassis[#moddef2.requireChassis]=nil
        --lazy remove(moddef2.requireChassis,"knight")
		return {moddef,moddef2}
    end
}