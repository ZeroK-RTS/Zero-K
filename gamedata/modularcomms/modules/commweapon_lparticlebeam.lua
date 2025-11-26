return{
    moduledef={
        commweapon_lparticlebeam={
            name="Light Particle Beam",
		    description="Light Particle Beam: Fast, light pulsed energy weapon",
        }
    },
    dynamic_comm_def=function (shared)
		shared=ModularCommDefsShared or shared
		local moduleImagePath=shared.moduleImagePath
		local COST_MULT=shared.COST_MULT
		local HP_MULT=shared.HP_MULT
        local moduleDefNamesToIDs=shared.moduleDefNamesToIDs
        
        local moddef={
            name = "commweapon_lparticlebeam",
            humanName = "Light Particle Beam",
            description = "Light Particle Beam: Fast, light pulsed energy weapon",
            image = moduleImagePath .. "commweapon_lparticlebeam.png",
            limit = 2,
            cost = 0,
            requireChassis = {"support", "recon", "strike", "knight"},
            requireLevel = 1,
            slotType = "basic_weapon",
            applicationFunction = function (modules, sharedData)
                if sharedData.noMoreWeapons then
                    return
                end
                local weaponName = (modules[moduleDefNamesToIDs.conversion_disruptor[1]] and "commweapon_disruptor") or "commweapon_lparticlebeam"
                if not sharedData.weapon1 then
                    sharedData.weapon1 = weaponName
                else
                    sharedData.weapon2 = weaponName
                end
            end,
            hardcodedID=10
        }
        local GenAdvWeaponModule=shared.GenAdvWeaponModule
        local moddef2=GenAdvWeaponModule(moddef)
        moddef2.hardcodedID=57
        --lazy remove(moddef2.requireChassis,"knight")
        moddef2.requireChassis[#moddef2.requireChassis]=nil
        --lazy remove(moddef2.requireChassis,"knight")
		return {moddef,moddef2}
    end
}