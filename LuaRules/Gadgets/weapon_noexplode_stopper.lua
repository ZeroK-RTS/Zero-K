--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name = "Noexplode Stopper",
		desc = "Implements noexplodes that do not penetrate shields.",
		author = "GoogleFrog",
		date = "4 Feb 2012",
		license = "None",
		layer = 50,
		enabled = true
	}
end

local passedProjectile = {}
local shieldDamages = {}
local noExplode = {}
for i = 1, #WeaponDefs do
	shieldDamages[i] = tonumber(WeaponDefs[i].customParams.shield_damage)
	if WeaponDefs[i].noExplode then
		noExplode[i] = true
	end
end

function gadget:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile)
	
	--[[
	-- Code that causes projectile bounce
	if Spring.ValidUnitID(shieldCarrierUnitID) then
	
		local px, py, pz = Spring.GetProjectilePosition(proID)
		local vx, vy, vz = Spring.GetProjectileVelocity(proID)
		local sx, sy, sz = Spring.GetUnitPosition(shieldCarrierUnitID)
		
		local rx, ry, rz = px-sx, py-sy, pz-sz
		
		local f = 2 * (rx*vx + ry*vy + rz*vz) / (rx^2 + ry^2 + rz^2)
		
		local nx, ny, nz = vx - f*rx, vy - f*ry, vz - f*rz
		Spring.SetProjectileVelocity(proID, nx, ny, nz)
	
		return true
	end
	
	return false
	--]]
	
	local weaponDefID = Spring.GetProjectileDefID(proID)
	if passedProjectile[proID] then
		return true
	--elseif select(2, Spring.GetProjectilePosition(proID)) < 0 then
	--	passedProjectile[proID] = true
	--	return true
	elseif weaponDefID and shieldCarrierUnitID and shieldEmitterWeaponNum and noExplode[weaponDefID] then
		local _, charge = Spring.GetUnitShieldState(shieldCarrierUnitID) --FIXME figure out a way to get correct shield
		if charge and shieldDamages[weaponDefID] < charge then
			Spring.DeleteProjectile(proID)
		else
			passedProjectile[proID] = true
		end
	end

	return false
	
end

function gadget:ProjectileDestroyed(proID)
	if passedProjectile[proID] then
		passedProjectile[proID] = false
	end
end


function gadget:Initialize()
	for id, _ in pairs(noExplode) do
		Script.SetWatchProjectile(id, true)
	end
end
