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

local handledDefs = {}
local removeDamageDefs = {}
local alreadyTakenDamage = false -- Noexplode weapons can deal damage twice in one frame
local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local activeProjectiles = IterableMap.New()
local inGameFrameLoop = false

for i = 1,#WeaponDefs do
	local wcp = WeaponDefs[i].customParams
	if wcp and (wcp.noexplode_speed_damage or wcp.thermite_frames) then
		handledDefs[i] = {
			maxSpeed = wcp.noexplode_speed_damage and WeaponDefs[i].projectilespeed,
			thermiteFrames = wcp.thermite_frames,
			ceg = wcp.thermite_ceg,
			sound = wcp.thermite_sound,
		}
		if wcp.thermite_dps_start and wcp.thermite_dps_end then
			local damage = WeaponDefs[i].damages[0]
			handledDefs[i].initDamageMod = wcp.thermite_dps_start / damage / 30
			handledDefs[i].damageModPerFrame = (wcp.thermite_dps_end - wcp.thermite_dps_start) / wcp.thermite_frames / damage / 30
			handledDefs[i].baseDamage = damage
		end
	end
	if wcp and wcp.remove_damage then
		removeDamageDefs[i] = true
	end
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)
	if not (weaponDefID and handledDefs[weaponDefID]) then
		return
	end
	local def = handledDefs[weaponDefID]
	local px, py, pz = Spring.GetProjectilePosition(proID)
	local proData = {
		px = px,
		py = py,
		pz = pz,
		def = def,
		damageMod = def.initDamageMod or 1,
		killFrame = def.thermiteFrames and (def.thermiteFrames + Spring.GetGameFrame()),
	}
	IterableMap.Add(activeProjectiles, proID, proData)
end

function gadget:ProjectileDestroyed(proID, proOwnerID)
	if not (weaponDefID and handledDefs[weaponDefID]) or inGameFrameLoop then
		return
	end
	IterableMap.Remove(activeProjectiles, proID)
end

function gadget:ShieldPreDamaged(projectileID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile, beamEmitterWeaponNum, beamEmitterUnitID, startX, startY, startZ, hitX, hitY, hitZ)
	if (not projectileID) then
		return false
	end
	local proData = IterableMap.Get(activeProjectiles, projectileID)
	if not (proData and proData.def.baseDamage) then
		return false
	end
	local _, charge = Spring.GetUnitShieldState(shieldCarrierUnitID)
	local fullDamage = (proData.damageMod or 1)*proData.def.baseDamage
	if fullDamage > charge then
		return true -- Passes shield
	end
	Spring.SetUnitShieldState(shieldCarrierUnitID, -1, true, charge - fullDamage)
	proData.resetNextFrame = true
	if GG.Lups_DoShieldDamage then
		GG.Lups_DoShieldDamage(shieldCarrierUnitID, fullDamage, hitX, hitY, hitZ)
	end
	return true -- Passes shield anyway
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam, projectileID)
	if (weaponDefID and removeDamageDefs[weaponDefID]) then
		return 0
	end
	if (not projectileID) or not (weaponDefID and handledDefs[weaponDefID]) then
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
	return damage * (proData.damageMod or 1)
end

local function UpdateProjectile(proID, proData, index, frame)
	local px, py, pz = Spring.GetProjectilePosition(proID)
	if not px then
		return true
	end
	local def = proData.def
	if def.maxSpeed then
		local travelled = math.sqrt((px - proData.px)^2 + (py - proData.py)^2 + (pz - proData.pz)^2)
		proData.damageMod = math.min(1, travelled / def.maxSpeed)
	end
	if def.thermiteFrames then
		local height = Spring.GetGroundHeight(px, pz)
		local vx, vy, vz = Spring.GetProjectileVelocity(proID)
		if proData.resetNextFrame then
			if py < height + 4 then
				Spring.SetProjectileVelocity(proID, 0, 0, 0)
			else
				-- Counteract gravity
				Spring.SetProjectileVelocity(proID, vx, vy + 0.08, vz)
			end
			px, py, pz = proData.px, proData.py, proData.pz
			Spring.SetProjectilePosition(proID, px, py, pz)
			proData.resetNextFrame = false
			if def.sound then
				if (not proData.nextSoundFrame) or proData.nextSoundFrame < frame then
					Spring.PlaySoundFile(def.sound, 4*(math.random()*0.5 + 0.5), px, py, pz, 'sfx')
					proData.nextSoundFrame = frame + 28 + math.random()*5 - 0.2*proData.damageMod
				end
			end
		end
		if def.damageModPerFrame then
			proData.damageMod = proData.damageMod + def.damageModPerFrame
		end
		if def.ceg then
			Spring.SpawnCEG(def.ceg, px, py + 0.02, pz, vx, vy, vz, 10, proData.damageMod) 
		end
	end
	if proData.killFrame and frame >= proData.killFrame then
		Spring.DeleteProjectile(proID)
		return true
	end
	proData.px = px
	proData.py = py
	proData.pz = pz
end

function gadget:Explosion(weaponDefID, x, y, z, ownerID, proID)
	local proData = IterableMap.Get(activeProjectiles, proID)
	if not proData then
		return
	end
	proData.resetNextFrame = true
end

function gadget:GameFrame(n)
	inGameFrameLoop = true
	IterableMap.Apply(activeProjectiles, UpdateProjectile, n)
	inGameFrameLoop = false
	if alreadyTakenDamage then
		alreadyTakenDamage = false
	end
end

function gadget:Initialize()
	for weaponDefID, _ in pairs(handledDefs) do
		Script.SetWatchWeapon(weaponDefID, true)
	end
end
