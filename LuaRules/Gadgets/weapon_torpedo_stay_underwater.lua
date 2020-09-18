if not Script.GetSynced() then
	return
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

local projectileDefs = {
	[WeaponDefNames["subraider_torpedo"].id] = true,
	[WeaponDefNames["amphriot_torpedo"].id] = true,
}

-------------------------------------------------------------
-------------------------------------------------------------

local projectiles = {}
local projectileIndex = {}

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
end

function gadget:GameFrame(n)
	if n%3 ~= 0 then
		return
	end

	local cnt = #projectiles
	local i = 1
	while i <= cnt do
		local proID = projectiles[i]
		if proID then
			local _, py = Spring.GetProjectilePosition(proID)
			if (not py) or py > 0 then
				if py then
					spSetProjectileGravity(proID, -1)
				end
				RemoveProjectile(proID)
				i = i - 1
				cnt = cnt - 1
			end
		end
		i = i + 1
	end
end

function gadget:ProjectileDestroyed(proID)
	RemoveProjectile(proID)
end

function gadget:Initialize()
	for id,_ in pairs(projectileDefs) do
		Script.SetWatchProjectile(id, true)
	end
end
