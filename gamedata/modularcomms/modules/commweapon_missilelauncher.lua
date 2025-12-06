return{
    moduledef={
        commweapon_missilelauncher={
            name="Missile Launcher",
		    description="Missile Launcher: Lightweight seeker missile with good range",
        }
    },
    dynamic_comm_def=function (shared)
		shared=ModularCommDefsShared or shared
		local moduleImagePath=shared.moduleImagePath
		local COST_MULT=shared.COST_MULT
		local HP_MULT=shared.HP_MULT
        local moduleDefNamesToIDs=shared.moduleDefNamesToIDs
        
        local moddef={
            name = "commweapon_missilelauncher",
            humanName = "Missile Launcher",
            description = "Missile Launcher: Lightweight seeker missile with good range",
            image = moduleImagePath .. "commweapon_missilelauncher.png",
            limit = 2,
            cost = 0,
            requireChassis = {"support", "strike", "knight"},
            requireLevel = 1,
            slotType = "basic_weapon",
            applicationFunction = function (modules, sharedData)
                if sharedData.noMoreWeapons then
                    return
                end
                if not sharedData.weapon1 then
                    sharedData.weapon1 = "commweapon_missilelauncher"
                else
                    sharedData.weapon2 = "commweapon_missilelauncher"
                end
            end,
            hardcodedID=11
        }
        local GenAdvWeaponModule=shared.GenAdvWeaponModule
        local moddef2=GenAdvWeaponModule(moddef)
        moddef2.hardcodedID=58
        --lazy remove(moddef2.requireChassis,"knight")
        moddef2.requireChassis[#moddef2.requireChassis]=nil
        --lazy remove(moddef2.requireChassis,"knight")
		return {moddef,moddef2}
    end
}