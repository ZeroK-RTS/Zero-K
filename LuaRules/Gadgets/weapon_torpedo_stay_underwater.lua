function gadget:GetInfo()
  return {
    name      = "Torpedo Stay Underwater",
    desc      = "Makes relevant torpedoes stay underwater.",
    author    = "GoogleFrog",
    date      = "27 Feb 2019",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

-------------------------------------------------------------
-------------------------------------------------------------
if not (gadgetHandler:IsSyncedCode()) then 
	return false
end
-------------------------------------------------------------
-------------------------------------------------------------

local projectileDefs = {
	[WeaponDefNames["subraider_torpedo"].id] = true,
	[WeaponDefNames["amphriot_torpedo"].id] = true,
}

-------------------------------------------------------------
-------------------------------------------------------------

local spSetProjectileGravity = Spring.SetProjectileGravity
function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)
	if not projectileDefs[weaponDefID] then
		return
	end
	local px, py, pz = Spring.GetProjectilePosition(proID)
	if (py or 1) > 0 then
		return
	end
	spSetProjectileGravity(proID, -1)
end

function gadget:Initialize()
	for id,_ in pairs(projectileDefs) do
		if Script.SetWatchProjectile then
			Script.SetWatchProjectile(id, true)
		else
			Script.SetWatchWeapon(id, true)
		end
	end
end
