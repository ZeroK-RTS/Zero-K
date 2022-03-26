function gadget:GetInfo()
  return {
    name      = "Projectile Gravity",
    desc      = "Forces missile projectiles into a cone in the direction of gravity.",
    author    = "GoogleFrog",
    date      = "17 Jan 2022",
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

local spGetProjectileTarget   = Spring.GetProjectileTarget
local spGetUnitVelocity       = Spring.GetUnitVelocity
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetProjectileTeamID   = Spring.GetProjectileTeamID
local spValidUnitID           = Spring.ValidUnitID
local spGetProjectileVelocity = Spring.GetProjectileVelocity
local spSetProjectileVelocity = Spring.SetProjectileVelocity

local dist3D = Spring.Utilities.Vector.Dist3D

-- In elmos/frame
local projectileDefs = {
	[WeaponDefNames["bomberprec_bombsabot"].id] = {
		anchor = 4.5,
		pull = 0.62,
	},
}

function gadget:Initialize()
	for id, _ in pairs(projectileDefs) do
		Script.SetWatchProjectile(id, true)
	end
end

function gadget:GameFrame(n)
	if thereAreProjectiles then
		thereAreProjectiles = false
		for proID, data in pairs(projectiles) do
			thereAreProjectiles = true
			local vx, vy, vz, speed = Spring.GetProjectileVelocity(proID)
			local mult = math.max(0.1, 1 - (speed - data.anchor)/speed)
			vx, vy, vz = vx*mult, (vy - data.pull)*mult, vz*mult
			Spring.SetProjectileVelocity (proID, vx, vy, vz)
		end
	end
end

local function AddProjectile(proID, def, proOwnerID)
	projectiles[proID] = def
	thereAreProjectiles = true
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if projectileDefs[weaponID] then
		AddProjectile(proID, projectileDefs[weaponID], proOwnerID)
	end
end

function gadget:ProjectileDestroyed(proID)
	if projectiles and projectiles[proID] then
		projectiles[proID] = nil
	end
end
