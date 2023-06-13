
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

function gadget:GetInfo()
  return {
    name      = "Torpedo Stay Underwater",
    desc      = "Makes relevant torpedoes stay underwater.",
    author    = "GoogleFrog",
    date      = "27 Feb 2019",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

local tobool = Spring.Utilities.tobool

local projectileDefs = {}

for i = 1, #WeaponDefs do
	local wd = WeaponDefs[i]

	if tobool(wd.customParams.stays_underwater) then
		projectileDefs[i] = true
	end
end

-------------------------------------------------------------
-------------------------------------------------------------

local projectiles = {}
local projectileIndex = {}

local killProjs = {}
local killProjIndex = {}
local killProjIter = 1

local projectileKillHeight = -500

local function RemoveProjectile(proID)
	local index = projectileIndex[proID]
	if not index then
		return
	end
	local lastIndex = #projectiles
	local lastID = projectiles[lastIndex]
	projectiles[index] = lastID
	projectileIndex[lastID] = index
	projectiles[lastIndex] = nil
	projectileIndex[proID] = nil
end

local function RemoveKillProjectile(proID)
	local index = killProjIndex[proID]
	if not index then
		return
	end
	local lastIndex = #killProjs
	local lastID = killProjs[lastIndex]
	killProjs[index] = lastID
	killProjIndex[lastID] = index
	killProjs[lastIndex] = nil
	killProjIndex[proID] = nil
end

local function AddKillProjectile(proID)
	local index = #killProjs + 1
	killProjs[index] = proID
	killProjIndex[proID] = index
end

-------------------------------------------------------------
-------------------------------------------------------------

local spSetProjectileGravity = Spring.SetProjectileGravity
function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)
	if not projectileDefs[weaponDefID] then
		return
	end
	local _, py = Spring.GetProjectilePosition(proID)
	if not py then
		return
	end
	if py > 0 then
		local index = #projectiles + 1
		projectiles[index] = proID
		projectileIndex[proID] = index
		return
	end
	spSetProjectileGravity(proID, -1)
	AddKillProjectile(proID)
end

local function KeepProjectilesBelowWaterSurface(n)
	if n%3 ~= 0 then
		return
	end

	local cnt = #projectiles
	local i = 1
	while i <= cnt do
		local proID = projectiles[i]
		if proID then
			local _, py = Spring.GetProjectilePosition(proID)
			if (not py) or py < 0 then
				if py then
					spSetProjectileGravity(proID, -1)
					AddKillProjectile(proID)
				end
				RemoveProjectile(proID)
				i = i - 1
				cnt = cnt - 1
			end
		end
		i = i + 1
	end
end

local function KeepProjectilesAboveSeaFloor(n)
	if n%6 ~= 5 then
		return
	end

	local count = #killProjs
	killProjIter = killProjIter + 1
	if killProjIter > count then
		killProjIter = 1
	end
	
	local proID = killProjs[killProjIter]
	if proID then
		local _, py = Spring.GetProjectilePosition(proID)
		if (not py) or py < projectileKillHeight then
			--local px, py, pz = Spring.GetProjectilePosition(proID)
			--Spring.MarkerAddPoint(px, py, pz, "")
			if py then
				Spring.DeleteProjectile(proID)
			end
			RemoveKillProjectile(proID)
		end
	end
end

function gadget:GameFrame(n)
	KeepProjectilesBelowWaterSurface(n)
	KeepProjectilesAboveSeaFloor(n)
end

function gadget:ProjectileDestroyed(proID)
	RemoveProjectile(proID)
	RemoveKillProjectile(proID)
end

function gadget:Initialize()
	for id,_ in pairs(projectileDefs) do
		Script.SetWatchProjectile(id, true)
	end
	local minHeight = Spring.GetGroundExtremes()
	projectileKillHeight = math.min(projectileKillHeight, minHeight - 200)
end
