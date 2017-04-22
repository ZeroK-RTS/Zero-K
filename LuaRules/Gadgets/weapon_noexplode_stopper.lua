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

local devCompatibility = Spring.Utilities.IsCurrentVersionNewerThan(100, 0)

local passedProjectile = {}
local shieldDamages = {}
for i = 1, #WeaponDefs do
	shieldDamages[i] = tonumber(WeaponDefs[i].customParams.shield_damage)
end

function gadget:ProjectileDestroyed(proID)
	if passedProjectile[proID] then
		passedProjectile[proID] = false
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
	elseif weaponDefID and shieldCarrierUnitID and shieldEmitterWeaponNum then
		local wd = WeaponDefs[weaponDefID]
		if wd and wd.noExplode then
			local on, charge = Spring.GetUnitShieldState(shieldCarrierUnitID)	--FIXME figure out a way to get correct shield
			if charge and shieldDamages[weaponDefID] < charge then
				--Spring.MarkerAddPoint(x,y,z,"")
				if devCompatibility then
					Spring.DeleteProjectile(proID)
				else
					Spring.SetProjectilePosition(proID,-100000,-100000,-100000)
					Spring.SetProjectileCollision(proID)
				end
			else
				passedProjectile[proID] = true
			end
		end
	end

	return false
	
end