function gadget:GetInfo()
  return {
    name      = "Projectile Hold",
    desc      = "Holds projectiles for specified time upon firing.",
    author    = "Google Frog",
    date      = "1 July 2017",
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

local depthcharge = {
	seaHold = 2*30,
	landHold = 4*30,
	maxHeight = 20,
}

local projectileDefs = {
	[WeaponDefNames["hoverdepthcharge_depthcharge"].id] = depthcharge,
	[WeaponDefNames["hoverdepthcharge_fake_depthcharge"].id] = depthcharge
}

local projectileSpeed = {
	[WeaponDefNames["hoverdepthcharge_depthcharge"].id] = 3, -- empirical
}

local projectileTimes = {}
local projectileMoveCtrl = {}

local function ReleaseProjectile(proID)
	if not projectileMoveCtrl[proID] then
		return
	end
	projectileMoveCtrl[proID] = nil
	
	local weaponDefID = Spring.GetProjectileDefID(proID)
	if not projectileDefs[weaponDefID] then
		return
	end
	Spring.SetProjectileMoveControl(proID, false)
	if projectileSpeed[weaponDefID] then
		GG.ProjectileRetarget_AddProjectile(proID, projectileSpeed[weaponDefID], true, true)
	end
end

function gadget:GameFrame(n)
	local projectiles = projectileTimes[n]
	if not projectiles then
		return
	end
	
	if type(projectiles) == "table" then
		for i = 1, #projectiles do
			ReleaseProjectile(projectiles[i])
		end
	else
		ReleaseProjectile(projectiles)
	end
	projectileTimes[n] = nil
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)
	if not projectileDefs[weaponDefID] then
		return
	end
	local def = projectileDefs[weaponDefID]
	local px, py, pz = Spring.GetProjectilePosition(proID)
	if not px then
		return
	end
	
	local height = math.max(Spring.GetGroundHeight(px, pz) or 0, 0)
	if py - height > def.maxHeight then
		-- Don't handle projectiles from flying Claymores
		return
	end
	local onLand = height > 0
	
	local frame = Spring.GetGameFrame()
	local releaseFrame = frame + ((onLand and def.landHold) or def.seaHold)
	
	projectileMoveCtrl[proID] = true
	Spring.SetProjectileMoveControl(proID, true)
	Spring.SetPieceProjectileParams (proID, 1000)
	
	if not projectileTimes[releaseFrame] then
		projectileTimes[releaseFrame] = proID
		return
	end
	
	local times = projectileTimes[releaseFrame]
	if type(times) == "table" then
		times[#times + 1] = proID
		return
	end
	
	projectileTimes[releaseFrame] = {
		times,
		proID
	}
end

function gadget:ProjectileDestroyed(proID)
	projectileMoveCtrl[proID] = nil
end

function gadget:Initialize()
	for id,_ in pairs(projectileDefs) do
		Script.SetWatchProjectile(id, true)
	end
end
