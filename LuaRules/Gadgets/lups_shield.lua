--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name    = "Lups Shield",
		desc    = "Draws variable shields for shielded units",
		author  = "GoogleFrog",
		date    = "14 November 2017",
		license = "GNU GPL, v2 or later",
		layer   = 1500, -- Call ShieldPreDamaged after gadgets which change whether interception occurs
		enabled = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GAMESPEED = Game.gameSpeed
local SHIELDARMORID = 4
local SHIELDARMORIDALT = 0

if gadgetHandler:IsSyncedCode() then
	local spSetUnitRulesParam = Spring.SetUnitRulesParam
	local INLOS_ACCESS = {inlos = true}
	local gameFrame = 0

	function gadget:GameFrame(n)
		gameFrame = n
	end

	function gadget:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile, beamEmitterWeaponNum, beamEmitterUnitID, startX, startY, startZ, hitX, hitY, hitZ)
		local wd = nil
		local dmgMod = 1
		if proID and proID ~= -1 then
			local proDefID = Spring.GetProjectileDefID(proID)
			wd = WeaponDefs[proDefID]
		elseif beamEmitterUnitID then --hitscan weapons
			local unitDefID = Spring.GetUnitDefID(beamEmitterUnitID)
			local weaponDefID = UnitDefs[unitDefID].weapons[beamEmitterWeaponNum].weaponDef
			wd = WeaponDefs[weaponDefID]
			if wd.type ~= "LightningCannon" then
				dmgMod = 1 / (wd.beamtime * GAMESPEED)
			end
		end

		if wd then
			local dmg = wd.damages[SHIELDARMORID]
			if dmg <= 0.1 then --some stupidity here: llt has 0.0001 dmg in wd.damages[SHIELDARMORID]
				dmg = wd.damages[SHIELDARMORIDALT]
			end
			--GG.TableEcho(wd.damages)
			--Spring.Echo("dmg=", dmg, dmg * dmgMod)
			local x, y, z = Spring.GetUnitPosition(shieldCarrierUnitID)
			local dx, dy, dz = hitX - x, hitY - y, hitZ - z
			SendToUnsynced("AddShieldHitDataHandler", gameFrame, shieldCarrierUnitID, dmg * dmgMod, dx, dy, dz)
		end

		spSetUnitRulesParam(shieldCarrierUnitID, "shieldHitFrame", gameFrame, INLOS_ACCESS)
		return false
	end

	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetMyAllyTeamID     = Spring.GetMyAllyTeamID
local spGetSpectatingState  = Spring.GetSpectatingState

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local shieldUnitDefs

local Lups
local LupsAddParticles
local LOS_UPDATE_PERIOD = 10
local HIT_UPDATE_PERIOD = 2

local highEnoughQuality = false

local hitUpdateNeeded = false

local myAllyTeamID = spGetMyAllyTeamID()

local shieldUnits = IterableMap.New()

local function GetVisibleSearch(x, z, search)
	if not x then
		return false
	end
	for i = 1, #search do
		if Spring.IsPosInAirLos(x + search[i][1], 0, z + search[i][2], myAllyTeamID) then
			return true
		end
	end
	return false
end

local function UpdateVisibility(unitID, unitData, unitVisible, forceUpdate)
	unitVisible = unitVisible or (myAllyTeamID == unitData.allyTeamID)
	if not unitVisible then
		local ux,_,uz = Spring.GetUnitPosition(unitID)
		unitVisible = GetVisibleSearch(ux, uz, unitData.search)
	end

	if unitVisible == unitData.unitVisible and not forceUpdate then
		return
	end
	unitData.unitVisible = unitVisible

	for i = 1, #unitData.fxTable do
		local fxID = unitData.fxTable[i]
		local fx = Lups.GetParticles(fxID)
		fx.visibleToMyAllyTeam = unitVisible
	end
end

local function AddUnit(unitID, unitDefID)
	local def = shieldUnitDefs[unitDefID]
	local defFx = def.fx
	local fxTable = {}
	for i = 1, #defFx do
		local fx = defFx[i]
		local options = Spring.Utilities.CopyTable(fx.options)
		options.unit = unitID
		options.shieldCapacity = def.shieldCapacity
		local fxID = LupsAddParticles(fx.class, options)
		if fxID ~= -1 then
			fxTable[#fxTable + 1] = fxID
		end
	end

	local unitData = {
		unitDefID   = unitDefID,
		search      = def.search,
		capacity    = def.damageMultShieldCapacity,
		decayFactor = def.decayFactor,
		radius      = def.shieldRadius,
		fxTable     = fxTable,
		allyTeamID  = Spring.GetUnitAllyTeam(unitID)
	}

	if highEnoughQuality then
		unitData.shieldPos  = def.shieldPos
		unitData.hitData = {}
		unitData.needsUpdate = false
	end

	shieldUnits.Add(unitID, unitData)

	local _, fullview = spGetSpectatingState()
	UpdateVisibility(unitID, unitData, fullview, true)
end

local function RemoveUnit(unitID)
	local unitData = shieldUnits.Get(unitID)
	if unitData then
		for i = 1, #unitData.fxTable do
			local fxID = unitData.fxTable[i]
			Lups.RemoveParticles(fxID)
		end
		shieldUnits.Remove(unitID)
	end
end

local PI = math.pi

local function cart2spherical(dx, dy, dz)
	local r = math.sqrt(dx*dx + dy*dy + dz*dz)
	local theta = math.acos(dz / r)
	local phi = math.atan2(dy, dx)
	return r, theta, phi
end

local function spherical2cart(r, theta, phi)
	local dx = r * math.sin(theta) * math.cos(phi)
	local dy = r * math.sin(theta) * math.sin(phi)
	local dz = r * math.cos(theta)
	return dx, dy, dz
end

local AOE_MIN = 0.04
local AOE_MAX = 0.15

local LOG10 = math.log(10)

local BIASLOG = 2.5
local LOGMUL = AOE_MAX / BIASLOG

local function GetMagAoE(dmg, capacity, first)
	local ratio = dmg / capacity
	local aoe = (BIASLOG + math.log(ratio)/LOG10) * LOGMUL
	aoe = math.max(0, aoe)

	local mag = 3.0

	return mag, aoe
end

local AOE_SAME_SPOT = (AOE_MIN + AOE_MAX) / 2

local function DoAddShieldHitData(unitData, hitFrame, dmg, theta, phi)
	local hitData = unitData.hitData
	local found = false
	--Spring.Echo(unitData.unitID, "#hitData", #hitData)
	--GG.TableEcho(hitData)
	for _, hitInfo in ipairs(hitData) do
		if hitInfo then
			local dist = math.sqrt( ((hitInfo.theta - theta)/PI)^2 + ((hitInfo.phi - phi)/PI)^2  )
			--Spring.Echo("dist", dist, AOE_SAME_SPOT)
			if dist <= AOE_SAME_SPOT then
				found = true
				hitInfo.theta = (theta * dmg + hitInfo.theta * hitInfo.dmg)/(dmg + hitInfo.dmg)
				hitInfo.phi = (phi * dmg + hitInfo.phi * hitInfo.dmg)/(dmg + hitInfo.dmg)
				hitInfo.dmg = dmg + hitInfo.dmg

				--Spring.Echo("AOE_SAME_SPOT", unitData.unitID, hitInfo.dmg)

				local mag, aoe = GetMagAoE(hitInfo.dmg, unitData.capacity)
				hitInfo.mag, hitInfo.aoe = mag, aoe

				local dx, dy, dz = spherical2cart(unitData.radius, hitInfo.theta, hitInfo.phi)
				hitInfo.dx, hitInfo.dy, hitInfo.dz = dx, dy, dz
				--break
			end
		end
	end

	if not found then
		local mag, aoe = GetMagAoE(dmg, unitData.capacity)
		--Spring.Echo("DoAddShieldHitData", dmg, aoe, mag)
		local dx, dy, dz = spherical2cart(unitData.radius, theta, phi)
		table.insert(hitData, {
			hitFrame = hitFrame,
			dmg = dmg,
			theta = theta,
			phi = phi,
			mag = mag,
			aoe = aoe,
			dx = dx,
			dy = dy,
			dz = dz,
		})
	end
	hitUpdateNeeded = true
	unitData.needsUpdate = true
end

local MIN_DAMAGE = 1

local function GetShieldHitPositions(unitID)
	local unitData = shieldUnits.Get(unitID)
	return (((unitData and unitData.hitData) and unitData.hitData) or nil)
end

local function ProcessHitTable(unitData, gameFrame)
	unitData.needsUpdate = false
	local hitData = unitData.hitData

	--apply decay over time first
	for i = #hitData, 1, -1 do
		local hitInfo = hitData[i]
		if hitInfo then
			local mult = math.exp(-unitData.decayFactor*(gameFrame - hitInfo.hitFrame))
			--Spring.Echo(gameFrame, hitInfo.dmg, mult, hitInfo.dmg * mult)
			hitInfo.dmg = hitInfo.dmg * mult
			hitInfo.hitFrame = gameFrame

			local mag, aoe = GetMagAoE(hitInfo.dmg, unitData.capacity)

			hitInfo.mag = mag
			hitInfo.aoe = aoe

			if hitInfo.dmg <= MIN_DAMAGE then
			--if hitInfo.aoe <= 0 then
				--Spring.Echo("MIN_DAMAGE", tostring(unitData), i, hitInfo.dmg)
				table.remove(hitData, i)
				hitInfo = nil
			else
				unitData.needsUpdate = true
			end
		end
	end
	if unitData.needsUpdate then
		hitUpdateNeeded = true
		table.sort(hitData, function(a, b) return (((a and b) and a.dmg > b.dmg) or false) end)
	end
	return unitData.needsUpdate
end

local function AddShieldHitData(_, hitFrame, unitID, dmg, dx, dy, dz)
	local unitData = shieldUnits.Get(unitID)
	if unitData and unitData.hitData then
		--Spring.Echo(hitFrame, unitID, dmg)
		local rdx, rdy, rdz = dx - unitData.shieldPos[1], dy - unitData.shieldPos[2], dz - unitData.shieldPos[3]
		local _, theta, phi = cart2spherical(rdx, rdy, rdz)
		DoAddShieldHitData(unitData, hitFrame, dmg, theta, phi)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	RemoveUnit(unitID)
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if shieldUnitDefs[unitDefID] then
		AddUnit(unitID, unitDefID)
	end
end

function gadget:UnitTaken(unitID, unitDefID, newTeam, oldTeam)
	local unitData = shieldUnits.Get(unitID)
	if unitData then
		unitData.allyTeamID = Spring.GetUnitAllyTeam(unitID)
	end
end

function gadget:PlayerChanged()
	myAllyTeamID = spGetMyAllyTeamID()
end

function gadget:GameFrame(n)
	if highEnoughQuality and hitUpdateNeeded and (n % HIT_UPDATE_PERIOD == 0) then
		hitUpdateNeeded = false
		for unitID, unitData in shieldUnits.Iterator() do
			if unitData and unitData.hitData then
				--Spring.Echo(n, unitID, unitData.unitID)
				local phtRes = ProcessHitTable(unitData, n)
				hitUpdateNeeded = hitUpdateNeeded or phtRes
			end
		end
	end

	if n % LOS_UPDATE_PERIOD == 0 then
		local _, fullview = spGetSpectatingState()
		for unitID, unitData in shieldUnits.Iterator() do
			UpdateVisibility(unitID, unitData, fullview)
		end
	end
end

function gadget:Initialize(n)
	if (not Lups) then
		Lups = GG.Lups
		LupsAddParticles = Lups.AddParticles
	end

	shieldUnitDefs = include("LuaRules/Configs/lups_shield_fxs.lua")
	highEnoughQuality = (Lups.Config.quality or 2) >= 3 --Require High(or Ultra?) quality to render hit positions
	--highEnoughQuality = false

	if highEnoughQuality then
		gadgetHandler:AddSyncAction("AddShieldHitDataHandler", AddShieldHitData)
		GG.GetShieldHitPositions = GetShieldHitPositions
	end

	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		local unitID = allUnits[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end

function gadget:Shutdown()
	if highEnoughQuality then
		gadgetHandler:RemoveSyncAction("AddShieldHitDataHandler", AddShieldHitData)
		GG.GetShieldHitPositions = nil
	end

	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		local unitID = allUnits[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitDestroyed(unitID, unitDefID)
	end
end
