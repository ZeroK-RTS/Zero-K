return{
    moduledef={
        commweapon_lightninggun={
            name="Lightning Rifle",
		    description="Lightning Rifle: Paralyzes and damages annoying bugs",
        }
    },
    dynamic_comm_def=function (shared)
		shared=ModularCommDefsShared or shared
		local moduleImagePath=shared.moduleImagePath
		local COST_MULT=shared.COST_MULT
		local HP_MULT=shared.HP_MULT
        local moduleDefNamesToIDs=shared.moduleDefNamesToIDs
        
        local moddef={
            name = "commweapon_lightninggun",
            humanName = "Lightning Rifle",
            description = "Lightning Rifle: Paralyzes and damages annoying bugs",
            image = moduleImagePath .. "commweapon_lightninggun.png",
            limit = 2,
            cost = 0,
            requireChassis = {"recon", "support", "strike", "knight"},
            requireLevel = 1,
            slotType = "basic_weapon",
            applicationFunction = function (modules, sharedData)
                if sharedData.noMoreWeapons then
                    return
                end
                local weaponName = (modules[moduleDefNamesToIDs.weaponmod_stun_booster[1]] and "commweapon_lightninggun_improved") or "commweapon_lightninggun"
                if not sharedData.weapon1 then
                    sharedData.weapon1 = weaponName
                else
                    sharedData.weapon2 = weaponName
                end
            end,
            hardcodedID=9
        }
        local GenAdvWeaponModule=shared.GenAdvWeaponModule
        local moddef2=GenAdvWeaponModule(moddef)
        moddef2.hardcodedID=56
        --lazy remove(moddef2.requireChassis,"knight")
        moddef2.requireChassis[#moddef2.requireChassis]=nil
        --lazy remove(moddef2.requireChassis,"knight")
		return {moddef,moddef2}
    end
}