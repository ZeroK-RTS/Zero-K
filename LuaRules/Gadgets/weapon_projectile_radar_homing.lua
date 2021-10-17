function gadget:GetInfo()
  return {
    name      = "Projectile Radar Homing",
    desc      = "Implements missile and starburst launcher homing on radar dots.",
    author    = "Google Frog",
    date      = "9 January 2016",
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

local UNIT = string.byte('u')

local projectiles = {}

local projectileHomingDistance = {}

for wdid = 1, #WeaponDefs do
	local wd = WeaponDefs[wdid]
	if (wd.customParams.radar_homing_distance) then
		projectileHomingDistance[wdid] = tonumber(wd.customParams.radar_homing_distance)^2
	elseif wd.tracks and
			(wd.type == "TorpedoLauncher" or wd.type == "MissileLauncher" or wd.type == "StarburstLauncher") then
		projectileHomingDistance[wdid] = (10 * wd.projectilespeed)^2
	end
end

function gadget:Initialize()
	for id, _ in pairs(projectileHomingDistance) do
		Script.SetWatchProjectile(id, true)
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
					Spring.SetProjectileIgnoreTrackingError(proID, true)
					projectiles[proID] = nil
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
