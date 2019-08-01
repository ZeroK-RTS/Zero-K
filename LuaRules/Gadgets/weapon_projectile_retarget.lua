function gadget:GetInfo()
  return {
    name      = "Projectile Retarget",
    desc      = "Retargets newly created projectiles and implements burnblow.",
    author    = "Google Frog",
    date      = "10 June 2014",
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

local FEATURE = 102
local GROUND = 103
local UNIT = 117

local projectiles = {}
local thereAreProjectiles = false

-- In elmos/frame
local projectileSpeed = {
	[WeaponDefNames["bomberheavy_arm_pidr"].id] = 19, -- empirical
}

-- Recluse projectile speed at different distances formula is a result of the least squares linear fit
-- of the following data set of {distance, averageSpeed} data.
-- {{290.8, 7.458}, {125.0, 6.252}, {451.9,8.369}, {31.436, 5.238}, {207.89, 6.929}, {371.8, 7.911}, {474.12, 8.466}}
-- speed = 0.00701024*distance + 5.27606

function gadget:Initialize()
	for id, _ in pairs(projectileSpeed) do 
		if Script.SetWatchProjectile then
			Script.SetWatchProjectile(id, true)
		else
			Script.SetWatchWeapon(id, true)
		end
	end
end
local function Dist3Dsqr(x,y,z)
	return x*x + y*y + z*z
end

local function Dist3D(x,y,z)
	return math.sqrt(x*x + y*y + z*z)
end

function gadget:GameFrame(n)
	if thereAreProjectiles then
		thereAreProjectiles = false
		for proID, data in pairs(projectiles) do
			thereAreProjectiles = true
			if data[4] then
				local _,_,_, _,_,_, tx, ty, tz = Spring.GetUnitPosition(data[4], true, true)
				if tx then
					data[1], data[2], data[3] = tx, ty, tz
					Spring.SetProjectileTarget(proID, tx, ty, tz)
				else
					data[4] = nil
				end
			end
			local px,py,pz = Spring.GetProjectilePosition(proID)
			if px and Dist3Dsqr(data[1] - px, data[2] - py, data[3] - pz) < 121 then
				Spring.SetProjectileCollision(proID)
			end
		end
	end
end

local function GetAimPosition(proID, targetID, speed, alwaysBurnblow, trackTarget)
	if trackTarget then
		local _,_,_, _,_,_, tx, ty, tz = Spring.GetUnitPosition(targetID, true, true)
		return {tx, ty, tz, trackTarget and targetID}
	end
	-- Replace prediction for mobile targets
	local bx,by,bz,ux,uy,uz = Spring.GetUnitPosition(targetID, true)
	local px,py,pz = Spring.GetProjectilePosition(proID)
	local vx, vy, vz = Spring.GetUnitVelocity(targetID)
	local hitTime = Dist3D(px - ux, py - uy, pz - uz)/speed
	
	-- Check whether the target is on the ground
	local h = Spring.GetGroundHeight(bx, bz)
	if by < h + 1 then
		-- Target is on the ground so snap target position to the ground.
		-- Reduce the effect of hit time because fast jinking units can cause the shot to go wide.
		-- Units fast enough to jink will be killed by the AoE of imperfect prediction.
		hitTime = hitTime*0.4
		
		local x,z = bx + hitTime*vx, bz + hitTime*vz
		local y = Spring.GetGroundHeight(x,z)
		Spring.SetProjectileTarget(proID, x, y, z)
		if alwaysBurnblow then
			return {x, y, z, trackTarget and proID}
		end
	else
		-- Target is in the air so predict perfectly and implement burnblow
		local x,y,z = ux + hitTime*vx, uy + hitTime*vy, uz + hitTime*vz
		Spring.SetProjectileTarget(proID, x, y, z)
		return {x, y, z, trackTarget and proID}
	end
end

local function AddProjectile(proID, speed, alwaysBurnblow, trackTarget)
	local targetType, targetID = Spring.GetProjectileTarget(proID)
	if targetType == UNIT and Spring.ValidUnitID(targetID) then
		local unitDefID = Spring.GetUnitDefID(targetID)
		-- May as well home perfectly onto immobile targets, they are not going anywhere.
		if not (unitDefID and UnitDefs[unitDefID].isImmobile) then
			local targetData = GetAimPosition(proID, targetID, speed, alwaysBurnblow, trackTarget)
			if targetData then
				projectiles[proID] = targetData
				thereAreProjectiles = true
			end
		else
			-- Targets may die, so always implement retargeting and burnblow.
			local _,_,_, _,_,_, tx, ty, tz = Spring.GetUnitPosition(targetID, true, true)
			Spring.SetProjectileTarget(proID, tx, ty, tz)
			projectiles[proID] = {tx, ty, tz}
			thereAreProjectiles = true
		end
	elseif targetType == FEATURE and Spring.ValidFeatureID(targetID) then
		local x,y,z = Spring.GetFeaturePosition(targetID)
		Spring.SetProjectileTarget(proID, x, y, z)
		if alwaysBurnblow then
			projectiles[proID] = {x, y, z}
			thereAreProjectiles = true
		end
	elseif targetType ~= GROUND then
		-- If the target type is not ground then the target was an invalid unit or feature
		-- Target straight
		local px,py,pz = Spring.GetProjectilePosition(proID)
		local vx, vy, vz = Spring.GetProjectileVelocity(proID)
		local x, y, z = px + 30*vx, py + 30*vy, pz + 30*vz
		Spring.SetProjectileTarget(proID, x, y, z)
		if alwaysBurnblow then
			projectiles[proID] = {x, y, z}
			thereAreProjectiles = true
		end
	else
		if alwaysBurnblow and type(targetID) == "table" then
			projectiles[proID] = {targetID[1], targetID[2], targetID[3]}
			thereAreProjectiles = true
		end
	end
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if projectileSpeed[weaponID] then
		AddProjectile(proID, projectileSpeed[weaponID], false)
	end
end

GG.ProjectileRetarget_AddProjectile = AddProjectile

function gadget:ProjectileDestroyed(proID)
	if projectiles and projectiles[proID] then
		projectiles[proID] = nil
	end
end