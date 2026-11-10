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
-- Lingering damage zones (napalm burn, Zeno slow cloud, Placeholder pull) are
-- told to widgets and to skirmish AIs when the receiver can see them: at
-- creation if the zone is in LOS or belongs to its allyteam, or later, once,
-- when the zone centre comes into LOS before the zone ends. Fullview
-- spectators get every zone at creation.
--
-- Widget callin (cawidgets.lua):
--   widget:VisibleAreaDamage(px, py, pz, radius, endFrame, weaponDefID, strength)
-- Skirmish AI message (Spring.SendSkirmishAIMessage, AIs hosted by this client):
--   "AREA_DAMAGE:<weaponDefName>:x,y,z,radius,endFrame,strength"
-- weaponDefID tells the kind (customParams area_damage_*). strength is 1, or
-- the scale that area_damage_height_max applies to damage and time falloff.
-- Damage stops at the first damage update at or after endFrame.

if gadgetHandler:IsSyncedCode() then
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

local frameNum
local DAMAGE_PERIOD, weaponInfo = VFS.Include("LuaRules/Configs/area_damage_defs.lua", nil, VFS.GAME)

local explosionList = {}
local explosionCount = 0

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
	local mult = 1
	if heightMax then
		local heightInt = weaponInfo[weaponID].heightInt or heightMax
		local height = (py - math.max(0, Spring.Utilities.GetGroundHeightMinusOffmap(px, pz) or 0))
		if height > heightMax then
			return false
		elseif height > heightMax - heightInt then
			mult = ((heightMax - height)/heightInt)
			weaponDamage = weaponDamage*mult
			timeLoss     = timeLoss*mult
			local heightReduce = weaponInfo[weaponID].heightReduce
			if heightReduce then
				py = py - (1 - mult)*heightReduce
			end
		end
	end
	
	local expiry = frameNum + weaponInfo[weaponID].duration
	explosionCount = explosionCount + 1
	explosionList[explosionCount] = {
		radius = weaponInfo[weaponID].radius,
		plateauRadius = weaponInfo[weaponID].plateauRadius,
		plateauFall = weaponInfo[weaponID].plateauFall,
		dragFactor = weaponInfo[weaponID].dragFactor,
		damage = weaponDamage,
		teamID = teamID,
		impulse = weaponInfo[weaponID].impulse,
		expiry = expiry,
		rangeFall = weaponInfo[weaponID].rangeFall,
		timeLoss = timeLoss,
		damageUpdateRate = weaponInfo[weaponID].damageUpdateRate,
		id = weaponID,
		pos = {x = px, y = py, z = pz},
		owner = ownerID,
	}
	SendToUnsynced("areaDamage_zone", px, py, pz, weaponInfo[weaponID].radius, expiry, weaponID, teamID, mult)
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
					local drag = data.impulse and damage*(data.dragFactor or 1)
					if data.plateauFall and data.plateauFall ~= 0 and distance < data.plateauRadius then
						damage = damage - damage*data.plateauFall*(data.plateauRadius - distance)/data.plateauRadius
					end
					if data.impulse then
						GG.AddGadgetImpulse(u, pos.x - ux, pos.y - uy, pos.z - uz, damage, false, true, false, {0.22,0.7,1})
						GG.SetUnitFallDamageImmunity(u, f + 10)
						GG.DoAirDrag(u, drag)
					elseif data.slow then
						GG.addSlowDamage(u, damage, false, data.teamID)
					else
						Spring.AddUnitDamageByTeam(u, damage, 0, data.owner, data.id, data.teamID)
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

--------------------------------------------------------------------------------
else -- UNSYNCED
--------------------------------------------------------------------------------

local spIsPosInLos = Spring.IsPosInLos

local CHECK_PERIOD = 15

local myPlayerID = Spring.GetLocalPlayerID()
local myAllyTeamID = Spring.GetLocalAllyTeamID()
local fullView = select(2, Spring.GetSpectatingState())

local aiTeamsByAllyTeam = {} -- [allyTeamID] = {teamID, ...} of native skirmish AIs hosted by this client
local haveLocalAI = false

local zones = {} -- zones that a receiver here may still see later
local zoneCount = 0

local function TellWidgets(zone)
	if Script.LuaUI("VisibleAreaDamage") then
		Script.LuaUI.VisibleAreaDamage(zone.x, zone.y, zone.z, zone.radius, zone.endFrame, zone.weaponDefID, zone.strength)
	end
end

local function TellAIs(zone, allyTeamID)
	zone.msg = zone.msg or string.format("AREA_DAMAGE:%s:%d,%d,%d,%d,%d,%.2f", WeaponDefs[zone.weaponDefID].name,
		math.floor(zone.x), math.floor(zone.y), math.floor(zone.z), zone.radius, zone.endFrame, zone.strength)
	local teams = aiTeamsByAllyTeam[allyTeamID]
	for i = 1, #teams do
		Spring.SendSkirmishAIMessage(teams[i], zone.msg)
	end
end

local function AddZone(_, px, py, pz, radius, endFrame, weaponDefID, teamID, strength)
	local widgetListens = Script.LuaUI("VisibleAreaDamage")
	if not (widgetListens or haveLocalAI) then
		return
	end
	local zone = {x = px, y = py, z = pz, radius = radius, endFrame = endFrame, weaponDefID = weaponDefID, strength = strength}
	local zoneAllyTeamID = teamID and Spring.GetTeamAllyTeamID(teamID)
	if widgetListens then
		if fullView or zoneAllyTeamID == myAllyTeamID or spIsPosInLos(px, py, pz, myAllyTeamID) then
			TellWidgets(zone)
		else
			zone.widgets = true
		end
	end
	for allyTeamID in pairs(aiTeamsByAllyTeam) do
		if allyTeamID == zoneAllyTeamID or spIsPosInLos(px, py, pz, allyTeamID) then
			TellAIs(zone, allyTeamID)
		else
			zone.ais = zone.ais or {}
			zone.ais[allyTeamID] = true
		end
	end
	if zone.widgets or zone.ais then
		zoneCount = zoneCount + 1
		zones[zoneCount] = zone
	end
end

local function UpdateZone(zone)
	if zone.widgets and (fullView or spIsPosInLos(zone.x, zone.y, zone.z, myAllyTeamID)) then
		zone.widgets = nil
		TellWidgets(zone)
	end
	if zone.ais then
		for allyTeamID in pairs(zone.ais) do
			if spIsPosInLos(zone.x, zone.y, zone.z, allyTeamID) then
				zone.ais[allyTeamID] = nil
				TellAIs(zone, allyTeamID)
			end
		end
		if not next(zone.ais) then
			zone.ais = nil
		end
	end
	return zone.widgets or zone.ais
end

function gadget:GameFrame(n)
	if zoneCount == 0 or n%CHECK_PERIOD ~= 0 then
		return
	end
	local i = 1
	while i <= zoneCount do
		local zone = zones[i]
		if n < zone.endFrame and UpdateZone(zone) then
			i = i + 1
		else
			zones[i] = zones[zoneCount]
			zones[zoneCount] = nil
			zoneCount = zoneCount - 1
		end
	end
end

function gadget:PlayerChanged(playerID)
	if playerID == myPlayerID then
		myAllyTeamID = Spring.GetLocalAllyTeamID()
		fullView = select(2, Spring.GetSpectatingState())
	end
end

function gadget:Initialize()
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local _, _, _, isAI, _, allyTeamID = Spring.GetTeamInfo(teamID, false)
		if isAI and select(3, Spring.GetAIInfo(teamID)) == myPlayerID and not Spring.GetTeamLuaAI(teamID) then
			aiTeamsByAllyTeam[allyTeamID] = aiTeamsByAllyTeam[allyTeamID] or {}
			local teams = aiTeamsByAllyTeam[allyTeamID]
			teams[#teams + 1] = teamID
			haveLocalAI = true
		end
	end
	gadgetHandler:AddSyncAction("areaDamage_zone", AddZone)
end

function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction("areaDamage_zone")
end

end
