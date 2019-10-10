function gadget:GetInfo()
  return {
    name      = "Weapon Timed Replace",
    desc      = "Replaces a projectile with another projectile a certain time after firing.",
    author    = "Google Frog",
    date      = "10 June 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false,
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
local UNIT = 117

local weaponLoseTrackingFrames = {}
local projectiles = {}
local projectileAllyTeam = {}

function gadget:Initialize()
	weaponLoseTrackingFrames[WeaponDefNames["bomberdive_bombsabot"].id] = 14
	Script.SetWatchProjectile(WeaponDefNames["bomberdive_bombsabot"].id, true)
end

function gadget:GameFrame(n)
	for proID, frame in pairs(projectiles) do
		if n == frame then
			local targetType, targetID = Spring.GetProjectileTarget(proID)
			if targetType == UNIT then
				local allyTeam = projectileAllyTeam[proID]
				local los = Spring.GetUnitLosState(targetID,allyTeam,true)
				if los and (los % 2 == 1) then
					-- If the unit is visible then target the ground beneath it.
					local x,_,z = Spring.GetUnitPosition(targetID)
					local y = Spring.GetGroundHeight(x,z)
					Spring.SetProjectileTarget(proID, x, y, z)
				else
					-- If the unit is not visible we have been homing onto a radar
					-- dot. The radar dot position is unknown to lua so target
					-- ground beneath the projectile.
					local x,_,z = Spring.GetProjectilePosition(proID)
					local y = Spring.GetGroundHeight(x,z)
					Spring.SetProjectileTarget(proID, x, y, z)
				end
			elseif targetType == FEATURE then
				local x,_,z = Spring.GetFeaturePosition(targetID)
				local y = Spring.GetGroundHeight(x,z)
				Spring.SetProjectileTarget(proID, x, y, z)
			end
			projectiles[proID] = nil
			projectileAllyTeam[proID] = nil
			
			--local x, _, z = Spring.GetProjectilePosition(proID)
			
			--[[local x, y, z = Spring.GetProjectilePosition(proID)
			local vx, vy, vz = Spring.GetProjectileVelocity(proID)
			
			-- Create new projectile
			Spring.SpawnProjectile(data.replacement, {
				pos = {x, y, z},
				speed = {vx, vy, vz},
				ttl = 180,
				tracking = false
			})
			
			-- Destroy old projectile
			Spring.DeleteProjectile(proID)
			--]]
		end
		
	end
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if weaponLoseTrackingFrames[weaponID] then
		projectiles[proID] = Spring.GetGameFrame() + weaponLoseTrackingFrames[weaponID]
		if proOwnerID then
			projectileAllyTeam[proID] = Spring.GetUnitAllyTeam(proOwnerID)
		end
	end
end

function gadget:ProjectileDestroyed(proID)
	if projectiles[proID] then
		projectiles[proID] = nil
		projectileAllyTeam[proID] = nil
	end
end
