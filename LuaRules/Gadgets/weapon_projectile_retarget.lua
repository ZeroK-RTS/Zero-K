function gadget:GetInfo()
  return {
    name      = "Projectile Retarget",
    desc      = "Retargets newly created projectiles.",
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

--local projectiles = {}

-- In elmos/frame
local projectileSpeed = {
	[WeaponDefNames["armcybr_arm_pidr"].id] = 19, -- empirical
}

-- Recluse projectile speed at different distances formula is a result of the least squares linear fit
-- of the following data set of {distance, averageSpeed} data.
-- {{290.8, 7.458}, {125.0, 6.252}, {451.9,8.369}, {31.436, 5.238}, {207.89, 6.929}, {371.8, 7.911}, {474.12, 8.466}}
-- speed = 0.00701024*distance + 5.27606

function gadget:Initialize()
	for id, _ in pairs(projectileSpeed) do 
		Script.SetWatchWeapon(id, true)
	end
end

local function Dist3D(x,y,z)
	return math.sqrt(x*x + y*y + z*z)
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if projectileSpeed[weaponID] then
		local targetType, targetID = Spring.GetProjectileTarget(proID)
		if targetType == UNIT and Spring.ValidUnitID(targetID) then
			local unitDefID = Spring.GetUnitDefID(targetID)
			-- May as well home perfectly onto immobile targets, they are not going anywhere.
			if not (unitDefID and UnitDefs[unitDefID].isImmobile) then
				-- Replace prediction for mobile targets
				local bx,by,bz,ux,uy,uz = Spring.GetUnitPosition(targetID, true)
				local px,py,pz = Spring.GetProjectilePosition(proID)
				local vx, vy, vz = Spring.GetUnitVelocity(targetID)
				local hitTime = Dist3D(px - ux, py - uy, pz - uz)/projectileSpeed[weaponID]
				
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
				else
					-- Target is in the air so predict perfectly and hope for flightTime to do its job.
					local x,y,z = ux + hitTime*vx, uy + hitTime*vy, uz + hitTime*vz
					Spring.SetProjectileTarget(proID, x, y, z)
				end
			end
		elseif targetType == FEATURE and Spring.ValidFeatureID(targetID) then
			local x,y,z = Spring.GetFeaturePosition(targetID)
			Spring.SetProjectileTarget(proID, x, y, z)
		elseif targetType ~= GROUND then
			-- If the target type is not ground then the target was an invalid unit or feature
			-- Target straight
			local px,py,pz = Spring.GetProjectilePosition(proID)
			local vx, vy, vz = Spring.GetProjectileVelocity(proID)
			Spring.SetProjectileTarget(proID, px + 30*vx, py + 30*vy, pz + 30*vz)
		end
	end
end

--function gadget:ProjectileDestroyed(proID)
--	if projectiles[proID] then
--		local data = projectiles[proID] 
--		local px,py,pz = Spring.GetProjectilePosition(proID)
--		local f = Spring.GetGameFrame()
--		local dist = Dist3D(data[1] - px, data[2] - py, data[3] - pz)
--		local hitTime = f - data[4]
--		Spring.Echo(dist, dist/hitTime)
--	end
--end