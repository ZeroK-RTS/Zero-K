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

local replaceDefs = {}
local projectiles = {}

function gadget:Initialize()

	replaceDefs[WeaponDefNames["bomberdive_bomb"].id] =	{
		frames = 2,
		replacement = WeaponDefNames["bomberdive_bombsabot"].id,
	}

	Script.SetWatchWeapon(WeaponDefNames["bomberdive_bomb"].id, true)
end

function gadget:GameFrame(n)
	for proID, data in pairs(projectiles) do
		if n == data.frame then
			local x, y, z = Spring.GetProjectilePosition(proID)
			local vx, vy, vz = Spring.GetProjectileVelocity(proID)
			
			-- Create new projectile
			Spring.SpawnProjectile(data.replacement, {
				pos = {x, y, z},
				speed = {vx*0.04, -5.625, vz*0.04},
				ttl = 300,
			})
			
			-- Destroy old projectile
			Spring.SetProjectilePosition(proID,-100000,-100000,-100000)
			Spring.SetProjectileCollision(proID)
		end
	end
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if replaceDefs[weaponID] then
		local x, y, z = Spring.GetProjectilePosition(proID)
		local def = replaceDefs[weaponID]
		projectiles[proID] = {
			frame = Spring.GetGameFrame() + def.frames,
			replacement = def.replacement,
		}
	end
end	

function gadget:ProjectileDestroyed(proID)
	if projectiles[proID] then
		projectiles[proID] = nil
	end
end