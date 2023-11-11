if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name = "Impact Swap",
		desc = "Swaps one projectile for another upon destruction",
		author = "GoogleFrog",
		date = "11 November 2023",
		license  = "GNU GPL, v2 or later",
		layer = -1,
		enabled = true
	}
end

local chainDefs = {}
for i = 1,#WeaponDefs do
	local wcp = WeaponDefs[i].customParams
	if wcp and wcp.child_chain_projectile then
		chainDefs[i] = {
			childDefID = WeaponDefNames[wcp.child_chain_projectile].id,
		}
	end
end

function gadget:ProjectileDestroyed(proID, proOwnerID)
	if not proID then
		return
	end
	local weaponDefID = Spring.GetProjectileDefID(proID)
	if not (weaponDefID and chainDefs[weaponDefID]) then
		return
	end
	local chainDef = chainDefs[weaponDefID]
	local projectileParams = {}
	
	local x, y, z = Spring.GetProjectilePosition(proID)
	x = x
	projectileParams.pos = {x, y, z}
	
	local vx, vy, vz = Spring.GetProjectileVelocity(proID)
	projectileParams["end"] = {x + vx, y + vy, z + vz}
	projectileParams.speed = math.sqrt(vx*vx + vy*vy + vz*vz)
	
	projectileParams.spread = {0, 0, 0}
	projectileParams.error = projectileParams.spread
	
	projectileParams.owner = Spring.GetProjectileOwnerID(proID)
	projectileParams.team = Spring.GetProjectileTeamID(proID)
	
	local newProID = Spring.SpawnProjectile(chainDef.childDefID, projectileParams)
	Spring.SetProjectileVelocity(newProID, vx, vy, vz)
end

function gadget:Initialize()
	for weaponDefID, _ in pairs(chainDefs) do
		Script.SetWatchWeapon(weaponDefID, true)
	end
end
