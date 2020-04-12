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

-------------------------------------------------------------
-------------------------------------------------------------
if not (gadgetHandler:IsSyncedCode()) then
	return false
end
-------------------------------------------------------------
-------------------------------------------------------------

local projectileDefs = {
	[WeaponDefNames["subraider_torpedo"].id] = true,
	[WeaponDefNames["amphriot_torpedo"].id] = true,
}

-------------------------------------------------------------
-------------------------------------------------------------

local projectiles = {}
local projectileIndex = {}

local function RemoveProjectile(proID)
	if not projectileIndex[proID] then
		return
	end
	local index = projectileIndex[proID]
	projectiles[index] = projectiles[#projectiles]
	projectileIndex[projectiles[index]] = index
	projectiles[#projectiles] = nil
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
		projectiles[#projectiles + 1] = proID
		projectileIndex[proID] = #projectiles
		return
	end
	spSetProjectileGravity(proID, -1)
end

function gadget:GameFrame(n)
	if n%3 ~= 0 then
		return
	end
	
	for i = 1, #projectiles do
		local proID = projectiles[i]
		if proID then
			local _, py = Spring.GetProjectilePosition(proID)
			if (not py) or py > 0 then
				if py then
					spSetProjectileGravity(proID, -1)
				end
				RemoveProjectile(proID)
				i = i - 1
			end
		end
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
