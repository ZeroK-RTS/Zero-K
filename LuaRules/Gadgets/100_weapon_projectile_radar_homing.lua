function gadget:GetInfo()
  return {
    name      = "100 Projectile Radar Homing",
    desc      = "Implements homing when close enough for starburst launchers.",
    author    = "Google Frog",
    date      = "9 January 2016",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = not Spring.Utilities.IsCurrentVersionNewerThan(100, 0),
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

local projectileHomingDistance = {
	[WeaponDefNames["gunshipaa_aa_missile"].id] = 150^2,
	[WeaponDefNames["hoveraa_weapon"].id] = 150^2,
	[WeaponDefNames["shieldarty_emp_rocket"].id] = 200^2,
}

function gadget:Initialize()
	for id, _ in pairs(projectileHomingDistance) do 
		if Script.SetWatchProjectile then
			Script.SetWatchProjectile(id, true)
		else
			Script.SetWatchWeapon(id, true)
		end
		Script.SetWatchWeapon(id, true)
	end
end

local function Dist3Dsqr(x,y,z)
	return x*x + y*y + z*z
end

function gadget:GameFrame(n)
	for proID, data in pairs(projectiles) do
		if Spring.ValidUnitID(data.unitID) then
			local px, py, pz = Spring.GetProjectilePosition(proID)
			local _, _, _, ux, uy, uz = Spring.GetUnitPosition(data.unitID, true)
			if px and ux then
				if (not Spring.GetUnitIsCloaked(data.unitID)) and Dist3Dsqr(ux - px, uy - py, uz - pz) < data.homeDistance then
					Spring.SetProjectileTarget(proID, ux, uy, uz)
				else
					Spring.SetProjectileTarget(proID, data.unitID)
				end
			end
		end
	end
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if projectileHomingDistance[weaponID] then
		local targetType, targetID = Spring.GetProjectileTarget(proID)
		if targetType == UNIT and Spring.ValidUnitID(targetID) then
			projectiles[proID] = {
				unitID = targetID,
				homeDistance = projectileHomingDistance[weaponID]
			}
		end
	end
end

function gadget:ProjectileDestroyed(proID)
	if projectiles and projectiles[proID] then
		projectiles[proID] = nil
	end
end