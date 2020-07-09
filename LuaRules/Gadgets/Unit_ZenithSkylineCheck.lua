if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
  return {
    name      = "Zenith Skyline Checker",
    desc      = "A meteor blocking test gadget",
    author    = "Shaman",
    date      = "July 8 2020",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = true,
  }
end	


local gravityWeaponDefID = WeaponDefNames["zenith_gravity_neg"].id

function gadget:Explosion(weaponDefID, px, py, pz, AttackerID, ProjectileID)
	if weaponDefID == gravityWeaponDefID then
		Spring.SetUnitRulesParam(AttackerID, "isBlocked", 1)
	end
end

function gadget:Initialize()
	Script.SetWatchWeapon(gravityWeaponDefID, true)
end
