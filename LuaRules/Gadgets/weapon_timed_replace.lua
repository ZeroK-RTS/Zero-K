function gadget:GetInfo()
  return {
    name      = "Weapon Timed Replace",
    desc      = "Replaces a projectile with another projectile a certain time after firing.",
    author    = "Google Frog",
    date      = "10 June 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = not (Game.version:find('91.0') == 1),
  }
end

-------------------------------------------------------------
-------------------------------------------------------------
if not (gadgetHandler:IsSyncedCode()) then 
	return false
end
-------------------------------------------------------------
-------------------------------------------------------------

local weaponLoseTrackingFrames = {}
local projectiles = {}

function gadget:Initialize()
	weaponLoseTrackingFrames[WeaponDefNames["bomberdive_bombsabot"].id] = 14
	Script.SetWatchWeapon(WeaponDefNames["bomberdive_bombsabot"].id, true)
end

function gadget:GameFrame(n)
	for proID, frame in pairs(projectiles) do
		if n == frame then
			local x, _, z = Spring.GetProjectilePosition(proID)
			local y = Spring.GetGroundHeight(x,z)
			Spring.SetProjectileTarget(proID, x, y, z)
			
			projectiles[proID] = nil
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
			Spring.SetProjectilePosition(proID,-100000,-100000,-100000)
			Spring.SetProjectileCollision(proID)
			--]]
		end
		
	end
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if weaponLoseTrackingFrames[weaponID] then
		local x, y, z = Spring.GetProjectilePosition(proID)
		projectiles[proID] = Spring.GetGameFrame() + weaponLoseTrackingFrames[weaponID]
	end
end

function gadget:ProjectileDestroyed(proID)
	if projectiles[proID] then
		projectiles[proID] = nil
	end
end
