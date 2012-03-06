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

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local passedProjectile = {}

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
	
	
	local wname = Spring.GetProjectileName(proID)
	if passedProjectile[proID] then
		return true
	--elseif select(2, Spring.GetProjectilePosition(proID)) < 0 then
	--	passedProjectile[proID] = true
	--	return true
	elseif wname and  shieldCarrierUnitID and shieldEmitterWeaponNum then
		local wd = WeaponDefNames[wname]
		if wd and wd.noExplode then
			local _, charge = Spring.GetUnitShieldState(shieldCarrierUnitID,shieldEmitterWeaponNum)
			if charge and wd.damages[0] < charge then
				--Spring.MarkerAddPoint(x,y,z,"")
				Spring.SetProjectileCollision(proID)
				Spring.SetProjectilePosition(proID,-100000,-100000,-100000)
			else
				passedProjectile[proID] = true
			end
		end
	end

	return false
	
end

end
