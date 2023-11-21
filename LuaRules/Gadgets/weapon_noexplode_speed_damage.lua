if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name = "Noexplode Speed Damage",
		desc = "Reduces speed for unusually slow noexplode projectiles so they deal consistent damage",
		author = "GoogleFrog",
		date = "21 November 2023",
		license  = "GNU GPL, v2 or later",
		layer = -1,
		enabled = true
	}
end

local dgunDefs = {}
local removeDamageDefs = {}
local alreadyTakenDamage = false -- Noexplode weapons can deal damage twice in one frame
local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local activeProjectiles = IterableMap.New()

for i = 1,#WeaponDefs do
	local wcp = WeaponDefs[i].customParams
	if wcp and wcp.noexplode_speed_damage then
		dgunDefs[i] = {
			maxSpeed = WeaponDefs[i].projectilespeed,
		}
	end
	if wcp and wcp.remove_damage then
		removeDamageDefs[i] = true
	end
end

local totalDamage = 0
function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)
	if not (weaponDefID and dgunDefs[weaponDefID]) then
		return
	end
	local def = dgunDefs[weaponDefID]
	local px, py, pz = Spring.GetProjectilePosition(proID)
	local proData = {
		px = px,
		py = py,
		pz = pz,
		def = def,
		damageMod = 1,
	}
	IterableMap.Add(activeProjectiles, proID, proData)
	totalDamage = 0
end

function gadget:ProjectileDestroyed(proID, proOwnerID)
	if not (weaponDefID and dgunDefs[weaponDefID]) then
		return
	end
	IterableMap.Remove(activeProjectiles, proID)
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam, projectileID)
	if (weaponDefID and removeDamageDefs[weaponDefID]) then
		return 0
	end
	if (not projectileID) or not (weaponDefID and dgunDefs[weaponDefID]) then
		return damage
	end
	local proData = IterableMap.Get(activeProjectiles, projectileID)
	if not proData then
		return damage
	end
	alreadyTakenDamage = alreadyTakenDamage or {}
	alreadyTakenDamage[unitID] = alreadyTakenDamage[unitID] or {}
	if alreadyTakenDamage[unitID][projectileID] then
		return 0
	end
	alreadyTakenDamage[unitID][projectileID] = true
	totalDamage = totalDamage + damage * proData.damageMod
	return damage * proData.damageMod
end

local function UpdateProjectile(proID, proData)
	local px, py, pz = Spring.GetProjectilePosition(proID)
	if not px then
		return true
	end
	local travelled = math.sqrt((px - proData.px)^2 + (py - proData.py)^2 + (pz - proData.pz)^2)
	proData.damageMod = math.min(1, travelled / proData.def.maxSpeed)
	proData.px = px
	proData.py = py
	proData.pz = pz
end

function gadget:GameFrame(n)
	IterableMap.Apply(activeProjectiles, UpdateProjectile)
	if alreadyTakenDamage then
		alreadyTakenDamage = false
	end
end

function gadget:Initialize()
	for weaponDefID, _ in pairs(dgunDefs) do
		Script.SetWatchWeapon(weaponDefID, true)
	end
end
