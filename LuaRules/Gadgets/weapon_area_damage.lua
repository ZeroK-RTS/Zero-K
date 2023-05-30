--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name = "Area Denial",
		desc = "Lets a weapon's damage persist in an area",
		author = "KDR_11k (David Becker), Google Frog",
		date = "2007-08-26",
		license = "Public domain",
		layer = 21,
		enabled = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local SAVE_FILE = "Gadgets/weapon_area_damage.lua"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

local frameNum
local DAMAGE_PERIOD, weaponInfo = VFS.Include("LuaRules/Configs/area_damage_defs.lua", nil, VFS.GAME)

local explosionList = {}
local explosionCount = 0

_G.explosionList = explosionList

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	local wantedWeaponList = {}
	for wdid = 1, #WeaponDefs do
		if weaponInfo[wdid] then
			wantedWeaponList[#wantedWeaponList + 1] = wdid
		end
	end
	return wantedWeaponList
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
	if weaponInfo[weaponDefID] and weaponInfo[weaponDefID].impulse then
		return 0
	end
	return damage
end

function gadget:Explosion_GetWantedWeaponDef()
	local wantedList = {}
	for wdid,_ in pairs(weaponInfo) do
		wantedList[#wantedList + 1] = wdid
	end
	return wantedList
end

local function RegisterLuaDamageArea(weaponID, px, py, pz, ownerID, teamID)
	local weaponDamage = weaponInfo[weaponID].damage
	local timeLoss     = weaponInfo[weaponID].timeLoss
	local heightMax    = weaponInfo[weaponID].heightMax
	if heightMax then
		local heightInt = weaponInfo[weaponID].heightInt or heightMax
		local height = (py - math.max(0, Spring.Utilities.GetGroundHeightMinusOffmap(px, pz) or 0))
		if height > heightMax then
			return false
		elseif height > heightMax - heightInt then
			local mult = ((heightMax - height)/heightInt)
			weaponDamage = weaponDamage*mult
			timeLoss     = timeLoss*mult
			local heightReduce = weaponInfo[weaponID].heightReduce
			if heightReduce then
				py = py - (1 - mult)*heightReduce
			end
		end
	end
	
	explosionCount = explosionCount + 1
	explosionList[explosionCount] = {
		radius = weaponInfo[weaponID].radius,
		plateauRadius = weaponInfo[weaponID].plateauRadius,
		damage = weaponDamage,
		impulse = weaponInfo[weaponID].impulse,
		expiry = frameNum + weaponInfo[weaponID].duration,
		rangeFall = weaponInfo[weaponID].rangeFall,
		timeLoss = timeLoss,
		damageUpdateRate = weaponInfo[weaponID].damageUpdateRate,
		id = weaponID,
		pos = {x = px, y = py, z = pz},
		owner = ownerID,
	}
end

local function RegisterSpawnedDamageArea(weaponID, px, py, pz, ownerID, teamID)
	explosionCount = explosionCount + 1
	explosionList[explosionCount] = {
		spawnWeaponDefID = weaponInfo[weaponID].spawnWeaponDefID,
		teamID = teamID,
		period = weaponInfo[weaponID].period,
		periodIncrease = weaponInfo[weaponID].periodIncrease,
		timeToNextSpawn = weaponInfo[weaponID].period,
		spawnsRemaining = weaponInfo[weaponID].repeats,
		id = weaponID,
		pos = {px, py, pz},
		owner = ownerID,
	}
	if weaponInfo[weaponID].instantSpawn then
		data = explosionList[explosionCount]
		local proID = Spring.SpawnProjectile(data.spawnWeaponDefID, {pos = data.pos, team = data.teamID})
		Spring.SetProjectileCollision(proID)
		data.spawnsRemaining = data.spawnsRemaining - 1
	end
end

function gadget:Explosion(weaponID, px, py, pz, ownerID, proID)
	if (weaponInfo[weaponID]) then
		local teamID = Spring.GetProjectileTeamID(proID)
		if weaponInfo[weaponID].spawnWeaponDefID then
			RegisterSpawnedDamageArea(weaponID, px, py, pz, ownerID, teamID)
		elseif weaponInfo[weaponID].damage then
			RegisterLuaDamageArea(weaponID, px, py, pz, ownerID, teamID)
		end
	end
	return false
end

local function HandleDamageArea(data, f)
	local pos = data.pos
	if data.radius then
		if (not data.damageUpdateRate) or (f%data.damageUpdateRate == 0) then
			local ulist = Spring.GetUnitsInSphere(pos.x, pos.y, pos.z, data.radius)
			if (ulist) then
				for j = 1, #ulist do
					local u = ulist[j]
					local ux, uy, uz = Spring.GetUnitPosition(u)
					local damage = data.damage
					local distance = math.sqrt((ux-pos.x)^2 + (uy-pos.y)^2 + (uz-pos.z)^2)
					if data.rangeFall ~= 0 and distance > data.plateauRadius then
						damage = damage - damage*data.rangeFall*(distance - data.plateauRadius)/(data.radius - data.plateauRadius)
					end
					if data.impulse then
						GG.AddGadgetImpulse(u, pos.x - ux, pos.y - uy, pos.z - uz, damage, false, true, false, {0.22,0.7,1})
						GG.SetUnitFallDamageImmunity(u, f + 10)
						GG.DoAirDrag(u, damage)
					elseif data.slow then
						GG.addSlowDamage(u, damage)
					else
						Spring.AddUnitDamage(u, damage, 0, data.owner, data.id, 0, 0, 0)
					end
				end
			end
			data.damage = data.damage - data.timeLoss
			if f >= data.expiry then
				return true -- remove
			end
		end
	elseif data.spawnWeaponDefID then
		if data.timeToNextSpawn <= 0 then
			local proID = Spring.SpawnProjectile(data.spawnWeaponDefID, {pos = data.pos, team = data.teamID})
			Spring.SetProjectileCollision(proID)
			data.period = data.period + data.periodIncrease
			data.timeToNextSpawn = data.timeToNextSpawn + data.period
			Spring.Echo("data.period", data.period)
			data.spawnsRemaining = data.spawnsRemaining - 1
			if data.spawnsRemaining <= 0 then
				return true -- remove
			end
		end
		data.timeToNextSpawn = data.timeToNextSpawn - DAMAGE_PERIOD
	end
end

function gadget:GameFrame(f)
	frameNum = f
	if (f%DAMAGE_PERIOD ~= 0) then
		return
	end
	local i = 1
	while i <= explosionCount do
		local data = explosionList[i]
		if HandleDamageArea(data, f) then
			explosionList[i] = explosionList[explosionCount]
			explosionList[explosionCount] = nil
			explosionCount = explosionCount - 1
		else
			i = i + 1
		end
	end
end

function gadget:Initialize()
	for w,_ in pairs(weaponInfo) do
		Script.SetWatchExplosion(w, true)
	end
end

function gadget:Load(zip)
	if not (GG.SaveLoad and GG.SaveLoad.ReadFile) then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Failed to access save/load API")
		return
	end
	
	local savedGameFrame = Spring.GetGameRulesParam("lastSaveGameFrame")
	local loadData = GG.SaveLoad.ReadFile(zip, "Weapon area damage", SAVE_FILE) or {}
	explosionList = loadData
	for i=1,#explosionList do
		local explo = explosionList[i]
		explo.owner = GG.SaveLoad.GetNewUnitID(explo.ownerID)
		explo.expiry = explo.expiry - savedGameFrame
	end
	
	_G.explosionList = explosionList
	explosionCount = #explosionList
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
-- unsynced
--------------------------------------------------------------------------------
function gadget:Save(zip)
	GG.SaveLoad.WriteSaveData(zip, SAVE_FILE, Spring.Utilities.MakeRealTable(SYNCED.explosionList, "Weapon area damage"))
end
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
