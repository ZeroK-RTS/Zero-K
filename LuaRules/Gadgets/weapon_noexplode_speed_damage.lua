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

local shieldPieceByUnitDef  = {}
local shieldRadiusByUnitDef = {}
local shieldPieceByUnit  = {}
local shieldRadiusByUnit = {}

local SHIELD_PUSH_VERT_FACTOR = 3

local g_CHAR = string.byte('g')
local u_CHAR = string.byte('u')
local f_CHAR = string.byte('f')

for i = 1,#WeaponDefs do
	local wcp = WeaponDefs[i].customParams
	if wcp and (wcp.noexplode_speed_damage or wcp.thermite_frames) then
		handledDefs[i] = {
			maxSpeed = wcp.noexplode_speed_damage and WeaponDefs[i].projectilespeed,
			thermiteFrames = wcp.thermite_frames,
			ceg = wcp.thermite_ceg,
			sound = wcp.thermite_sound,
			hitSound = wcp.thermite_sound_hit,
		}
		if wcp.thermite_dps_start and wcp.thermite_dps_end then
			local damage = WeaponDefs[i].damages[1]
			handledDefs[i].initDamageMod = wcp.thermite_dps_start / damage / 30
			handledDefs[i].damageModPerFrame = (wcp.thermite_dps_end - wcp.thermite_dps_start) / wcp.thermite_frames / damage / 30
			handledDefs[i].baseDamage = damage
		end
	end
	if wcp and wcp.remove_damage then
		removeDamageDefs[i] = true
	end
end

local function GetShieldRadius(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
end

local function CacheShieldPieceAndRadius(unitID, unitDefID)
	if shieldPieceByUnitDef[unitDefID] then
		shieldPieceByUnit[unitID]  = shieldPieceByUnitDef[unitDefID]
		shieldRadiusByUnit[unitID] = shieldRadiusByUnitDef[unitDefID]
		return
	end
	local ud = UnitDefs[unitDefID]
	local shieldWeaponDefID, shieldNum
	if ud.customParams.dynamic_comm then
		if GG.Upgrades_UnitShieldDef then
			shieldWeaponDefID, shieldNum = GG.Upgrades_UnitShieldDef(unitID)
		end
	else
		shieldWeaponDefID = ud.shieldWeaponDef
		for i = 1, #ud.weapons do
			if ud.weapons[i].weaponDef == shieldWeaponDefID then
				shieldNum = i
				break
			end
		end
	end
	
	if shieldWeaponDefID then
		local shieldWep = WeaponDefs[shieldWeaponDefID]
		shieldRadiusByUnit[unitID] = shieldWep.shieldRadius
	else
		shieldRadiusByUnit[unitID] = 80
	end
	if shieldNum then
		local env = Spring.UnitScript.GetScriptEnv(unitID)
		if env.script.QueryWeapon then
			shieldPieceByUnit[unitID] = env.script.QueryWeapon(shieldNum)
		end
	end
	
	if not ud.customParams.dynamic_comm then -- Comms are dynamic
		shieldPieceByUnitDef[unitDefID]  = shieldPieceByUnit[unitID]
		shieldRadiusByUnitDef[unitDefID] = shieldRadiusByUnit[unitID]
	end
end

local function GetShieldParameters(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	if not shieldRadiusByUnit[unitID] then
		CacheShieldPieceAndRadius(unitID, unitDefID)
	end
	local shieldPiece = shieldPieceByUnit[unitID]
	local sx, sy, sz
	if shieldPiece then
		sx, sy, sz = Spring.GetUnitPiecePosDir(unitID, shieldPiece)
	else
		sx, sy, sz = Spring.GetUnitPosition(unitID)
	end
	return sx, sy, sz, shieldRadiusByUnit[unitID]
end

local function SnapToShieldHeight(shieldCarrierUnitID, px, py, pz, vx, vy, vz, targetYpos)
	if not Spring.ValidUnitID(shieldCarrierUnitID) then
		return px, py, pz, vx, vy, vz
	end
	local sx, sy, sz, radius = GetShieldParameters(shieldCarrierUnitID)
	if not sx then
		return px, py, pz, vx, vy, vz
	end
	local dx, dy, dz = sx - px, sy - py, sz - pz
	if dy > 0 then
		-- Don't bother handling shields that smother thermite
		return px, py, pz, vx, vy, vz
	end
	local delta = 0.2
	local ox, oy, oz = px, py, pz
	while math.sqrt(dx*dx + dy*dy + dz*dz) < radius + 1 do
		px = px + delta*vx/vy
		py = py + delta * SHIELD_PUSH_VERT_FACTOR
		pz = pz + delta*vz/vy
		dx, dy, dz = sx - px, sy - py, sz - pz
	end
	
	if oy ~= py then
		-- The assumption here is that by pushing the projectile upwards we have increased
		-- flight time, so horizontal velocity should be reduced by an appropriate factor
		-- to keep the projectile on target.
		targetYpos = targetYpos or (Spring.GetGroundHeight(px, pz) or py)
		local heightFactor = math.max(50, py - targetYpos)
		local factor = heightFactor / ((py - oy) / SHIELD_PUSH_VERT_FACTOR + heightFactor)
		vx = vx*factor
		vz = vz*factor
	end
	return px, py, pz, vx, vy, vz
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)
	if not (weaponDefID and handledDefs[weaponDefID]) then
		return
	end
	local def = handledDefs[weaponDefID]
	local px, py, pz = Spring.GetProjectilePosition(proID)
	
	local targetType, target = Spring.GetProjectileTarget(proID)
	local targetYpos
	if targetType == u_CHAR then
		local tx, ty, tz = Spring.GetUnitPosition(target)
		targetYpos = ty
	elseif targetType == g_CHAR then
		targetYpos = target[2]
	elseif targetType == f_CHAR then
		local tx, ty, tz = Spring.GetFeaturePosition(target)
		targetYpos = ty
	end
	
	local proData = {
		px = px,
		py = py,
		pz = pz,
		def = def,
		targetYpos = targetYpos,
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
	if proData.resetNextFrameShield then
		proData.resetNextFrameShield = {proData.resetNextFrameShield}
		proData.resetNextFrameShield[#proData.resetNextFrameShield + 1] = shieldCarrierUnitID
	else
		proData.resetNextFrameShield = shieldCarrierUnitID
	end
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
		local height = Spring.GetGroundHeight(px, pz) or py
		local vx, vy, vz, speed = Spring.GetProjectileVelocity(proID)
		if proData.resetNextFrame then
			if def.hitSound and not proData.playedHitAlready then
				Spring.PlaySoundFile(def.hitSound, 14, px, py, pz, 'sfx')
				proData.playedHitAlready = true
			end
			px, py, pz = proData.px, proData.py, proData.pz
			if proData.resetNextFrameShield then
				if type(proData.resetNextFrameShield) == "table" then
					for i = 1, #proData.resetNextFrameShield do
						px, py, pz, vx, vy, vz = SnapToShieldHeight(proData.resetNextFrameShield[i], px, py, pz, vx, vy, vz, proData.targetYpos)
					end
				else
					px, py, pz, vx, vy, vz = SnapToShieldHeight(proData.resetNextFrameShield, px, py, pz, vx, vy, vz, proData.targetYpos)
				end
				proData.resetNextFrameShield = false
			end
			if py < height + 4 then
				Spring.SetProjectileVelocity(proID, 0, 0, 0)
			else
				-- Counteract gravity
				Spring.SetProjectileVelocity(proID, vx, vy + 0.08, vz)
			end
			Spring.SetProjectilePosition(proID, px, py, pz)
			proData.resetNextFrame = false
			if def.sound then
				if (not proData.nextSoundFrame) or proData.nextSoundFrame < frame then
					Spring.PlaySoundFile(def.sound, 4.5*(math.random()*0.5 + 0.5) + 0.3*proData.damageMod, px, py, pz, 'sfx')
					proData.nextSoundFrame = frame + 28 + math.random()*5 - 0.2*proData.damageMod
				end
			end
		end
		if def.damageModPerFrame then
			proData.damageMod = proData.damageMod + def.damageModPerFrame
		end
		if def.ceg then
			local height = Spring.GetGroundHeight(px, pz) or py
			Spring.SpawnCEG(def.ceg, px, math.max(height, py), pz, vx, vy, vz, 10, proData.damageMod) 
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

function gadget:UnitDestroyed(unitID)
	shieldPieceByUnit[unitID]  = nil
	shieldRadiusByUnit[unitID] = nil
end

function gadget:Initialize()
	for weaponDefID, _ in pairs(handledDefs) do
		Script.SetWatchWeapon(weaponDefID, true)
	end
end
