
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

function gadget:GetInfo()
	return {
		name = "Unit Explosion Spawner",
		desc = "Spawns units using an explosion as a trigger.",
		author = "KDR_11k (David Becker), lurker",
		date = "2007-11-18",
		license = "None",
		layer = 50,
		enabled = true
	}
end

local spCreateFeature         = Spring.CreateFeature
local spCreateUnit            = Spring.CreateUnit
local spDestroyUnit           = Spring.DestroyUnit
local spGetGameFrame          = Spring.GetGameFrame
local spGetProjectileDefID    = Spring.GetProjectileDefID
local spGetProjectileTeamID   = Spring.GetProjectileTeamID
local spGetUnitShieldState    = Spring.GetUnitShieldState
local spGiveOrderToUnit       = Spring.GiveOrderToUnit
local spSetFeatureDirection   = Spring.SetFeatureDirection
local spSetUnitRulesParam     = Spring.SetUnitRulesParam

local random = math.random
local sin    = math.sin
local cos    = math.cos

local GAME_SPEED = Game.gameSpeed
local TAU = 2 * math.pi
local PRIVATE = { private = true }
local CMD_WAIT = CMD.WAIT

local noCreate = false

local spawnDefs = {}
local shieldCollide = {}
local wantedList = {}

-- using a bunch of ([index] = number) tables instead of one ([index] = {number, number}) to reduce subtable allocations
local expireList = {} -- [index] = frame
local expireID = {} -- [index] = unitID
local expireByID = {} -- [unitID] = index
local expireCount = 0

local spawnList = {} -- [index] = {.spawnDef, .teamID, .x, .y, .z, .ownerID}, subtables reused
local spawnCount = 0

for weaponDefID = 1, #WeaponDefs do
	local wdcp = WeaponDefs[weaponDefID].customParams
	if wdcp.spawns_name then
		spawnDefs[weaponDefID] = {
			name = wdcp.spawns_name,
			expire = wdcp.spawns_expire and (tonumber(wdcp.spawns_expire) * GAME_SPEED),
			feature = wdcp.spawns_feature,
		}
		if wdcp.spawn_blocked_by_shield then
			shieldCollide[weaponDefID] = WeaponDefs[weaponDefID].damages[Game.armorTypes.shield]
		end
		wantedList[#wantedList + 1] = weaponDefID
	end
end

function gadget:Explosion_GetWantedWeaponDef()
	return wantedList
end

local function SpawnUnit(spawnData)
	local spawnDef = spawnData.spawnDef
	if spawnDef.feature then
		local featureID = spCreateFeature(spawnDef.name, spawnData.x, spawnData.y, spawnData.z, 0, spawnData.teamID)
		if not featureID then
			return
		end

		local rot = random() * TAU
		spSetFeatureDirection(featureID, cos(rot), 0, sin(rot))
	else
		local unitID = spCreateUnit(spawnDef.name, spawnData.x, spawnData.y, spawnData.z, 0, spawnData.teamID)
		if not unitID then
			-- unit limit hit
			return
		end

		local ownerID = spawnData.ownerID
		if ownerID then
			spSetUnitRulesParam(unitID, "parent_unit_id", ownerID, PRIVATE)
		end

		if spawnDef.expire then
			expireCount = expireCount + 1
			expireByID[unitID] = expireCount
			expireID[expireCount] = unitID
			expireList[expireCount] = spGetGameFrame() + spawnDef.expire
		end

		-- force a slowupdate to make the unit act immediately
		spGiveOrderToUnit(unitID, CMD_WAIT, 0, 0)
		spGiveOrderToUnit(unitID, CMD_WAIT, 0, 0)
	end
end

function gadget:Initialize()
	for i = 1, #wantedList do
		Script.SetWatchExplosion(wantedList[i], true)
	end
end

function gadget:Explosion(weaponDefID, x, y, z, ownerID, proID)
	if noCreate then
		noCreate = false
		return
	end

	local spawnDef = spawnDefs[weaponDefID] -- guaranteed not nil by Explosion_GetWantedWeaponDef
	local teamID = spGetProjectileTeamID(proID)

	-- Don't let awakening children embrace the glory of their birthright
	-- i.e. relegate spawn to GameFrame not to be damaged by the very explosion that bore them
	spawnCount = spawnCount + 1
	local spawnData = spawnList[spawnCount] or {}
	spawnData.spawnDef = spawnDef
	spawnData.x = x
	spawnData.y = y
	spawnData.z = z
	spawnData.ownerID = ownerID
	spawnData.teamID = teamID
	spawnList[spawnCount] = spawnData
end

function gadget:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile)
	if not proID or proID < 0 then -- beamlasers; nil in older engines and -1 in more recent
		return
	end

	local proDefID = spGetProjectileDefID(proID)
	local shieldDmg = shieldCollide[proDefID]
	if not shieldDmg then
		return
	end

	local shieldOn, shieldCharge = spGetUnitShieldState(shieldCarrierUnitID)
	if shieldCharge < shieldDmg then
		return true
	end

	noCreate = true -- not a per-projectile map because Explosion() is guaranteed to follow
end

function gadget:UnitDestroyed(unitID)
	local index = expireByID[unitID]
	if not index then
		return
	end

	local lastUnitID = expireID[expireCount]

	expireList[index] = expireList[expireCount]
	expireID[index] = lastUnitID
	expireByID[lastUnitID] = index
	expireByID[unitID] = nil
	expireCount = expireCount - 1

	-- last element not nil'd on purpose
	-- no point wasting time doing that as the array won't shrink anyway
end

function gadget:GameFrame(f)
	if spawnCount > 0 then
		for i = 1, spawnCount do
			SpawnUnit(spawnList[i])
			-- NB: no subtable deallocation, they are reused to avoid having to alloc them again anyway
		end
		spawnCount = 0
	end

	if f % GAME_SPEED ~= 0 then
		return
	end

	local i = 1
	while i <= expireCount do -- not for-loop because Destroy decrements count
		if expireList[i] < f then
			spDestroyUnit(expireID[i], true)
		else
			i = i + 1 -- conditional because Destroy replaces current element with last
		end
	end
end
