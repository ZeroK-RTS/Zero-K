return{
    moduledef={
        commweapon_beamlaser={
            name="Beam Laser",
		    description="Beam Laser: An effective short-range cutting tool",
        }
    },
    dynamic_comm_def=function (shared)
		shared=ModularCommDefsShared or shared
		local moduleImagePath=shared.moduleImagePath
		local COST_MULT=shared.COST_MULT
		local HP_MULT=shared.HP_MULT
        local moddef={
            name = "commweapon_beamlaser",
            humanName = "Beam Laser",
            description = "Beam Laser: An effective short-range cutting tool",
            image = moduleImagePath .. "commweapon_beamlaser.png",
            limit = 2,
            cost = 0,
            requireLevel = 1,
            requireChassis={"recon", "strike", "assault", "support", "knight"},
            slotType = "basic_weapon",
            applicationFunction = function (modules, sharedData)
                if sharedData.noMoreWeapons then
                    return
                end
                if not sharedData.weapon1 then
                    sharedData.weapon1 = "commweapon_beamlaser"
                else
                    sharedData.weapon2 = "commweapon_beamlaser"
                end
            end,
            hardcodedID=5,
        }
        local GenAdvWeaponModule=shared.GenAdvWeaponModule
        local moddef2=GenAdvWeaponModule(moddef)
        moddef2.hardcodedID=52
        --lazy remove(moddef2.requireChassis,"knight")
        moddef2.requireChassis[#moddef2.requireChassis]=nil
        --lazy remove(moddef2.requireChassis,"knight")
		return {moddef,moddef2}
    end
}