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

local Unit = Spring.Utilities.Vector.Unit
local Cross = Spring.Utilities.Vector.Cross

local FLOW_VELOCITY = 8

local passedProjectile = {}
local shieldDamages = {}
local noExplode = {}
local flowAroundShield = {}
for i = 1, #WeaponDefs do
	shieldDamages[i] = tonumber(WeaponDefs[i].customParams.shield_damage)
	if WeaponDefs[i].noExplode then
		noExplode[i] = true
		if WeaponDefs[i].customParams.flamethrower then
			flowAroundShield[i] = true
		end
	end
end

local function SetNewProjectileVelocity(shieldCarrierUnitID, proID)
	local _, _ ,_ ,sx, sy, sz = Spring.GetUnitPosition(shieldCarrierUnitID, true)
	local px, py, pz = Spring.GetProjectilePosition(proID)
	if not (px and sx) then
		Spring.SetProjectileVelocity(proID,
			math.random()*FLOW_VELOCITY - FLOW_VELOCITY/2,
			math.random()*FLOW_VELOCITY - FLOW_VELOCITY/2,
			math.random()*FLOW_VELOCITY - FLOW_VELOCITY/2)
		return
	end
	
	local vx, vy, vz = sx - px, sy - py, sz - pz
	if vx == 0 and vz == 0 then
		vx = math.random()*0.001
		vz = math.random()*0.001
	end
	local ax, ay, az = Unit(Cross(vx, vy, vz, 0, 1, 0))
	local bx, by, bz = Unit(Cross(vx, vy, vz, ax, ay, az))
	local angle = math.random()*math.pi*2
	local af, bf = math.cos(angle), math.sin(angle)
	local cx, cy, cz = ax*af + bx*bf, ay*af + by*bf, az*af + bz*bf
	
	Spring.SetProjectileVelocity(proID, cx*FLOW_VELOCITY, cy*FLOW_VELOCITY, cz*FLOW_VELOCITY)
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
		local damageMult = Spring.ValidUnitID(proOwnerID) and Spring.GetUnitRulesParam(proOwnerID, "comm_damage_mult") or 1
		local _, charge = Spring.GetUnitShieldState(shieldCarrierUnitID) --FIXME figure out a way to get correct shield
		if charge and shieldDamages[weaponDefID] * damageMult < charge then
			Spring.DeleteProjectile(proID)
			if flowAroundShield[weaponDefID] then
				SetNewProjectileVelocity(shieldCarrierUnitID, proID)
			end
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
