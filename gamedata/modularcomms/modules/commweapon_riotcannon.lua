return{
    moduledef={
        commweapon_riotcannon={
            name="Riot Cannon",
		    description="Riot Cannon: The weapon of choice for crowd control",
        }
    },
    dynamic_comm_def=function (shared)
		shared=ModularCommDefsShared or shared
		local moduleImagePath=shared.moduleImagePath
		local COST_MULT=shared.COST_MULT
		local HP_MULT=shared.HP_MULT
        local moduleDefNamesToIDs=shared.moduleDefNamesToIDs
        
        local moddef={
            name = "commweapon_riotcannon",
            humanName = "Riot Cannon",
            description = "Riot Cannon: The weapon of choice for crowd control",
            image = moduleImagePath .. "commweapon_riotcannon.png",
            limit = 2,
            cost = 0,
            requireChassis = {"assault", "knight"},
            requireLevel = 1,
            slotType = "basic_weapon",
            applicationFunction = function (modules, sharedData)
                if sharedData.noMoreWeapons then
                    return
                end
                local weaponName = (modules[moduleDefNamesToIDs.weaponmod_napalm_warhead[1]] and "commweapon_riotcannon_napalm") or "commweapon_riotcannon"
                if not sharedData.weapon1 then
                    sharedData.weapon1 = weaponName
                else
                    sharedData.weapon2 = weaponName
                end
            end,
            hardcodedID=12
        }
        local GenAdvWeaponModule=shared.GenAdvWeaponModule
        local moddef2=GenAdvWeaponModule(moddef)
        moddef2.hardcodedID=59
        --lazy remove(moddef2.requireChassis,"knight")
        moddef2.requireChassis[#moddef2.requireChassis]=nil
        --lazy remove(moddef2.requireChassis,"knight")
		return {moddef,moddef2}
    end
}