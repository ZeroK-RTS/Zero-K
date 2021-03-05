function gadget:GetInfo()
	return {
		name      = "Glancefire AI",
		desc      = "Shoot at things beyond a unit's range using AOE",
		author    = "Shaman",
		date      = "November 9, 2020",
		license   = "PD",
		layer     = 5,
		enabled   = true,
	}
end

if not (gadgetHandler:IsSyncedCode()) then
	return
end

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local overshootdefs = {} -- unitdefs to watch
local unitstocheck = IterableMap.New()
local updaterate = 3 -- the rate we update units.
local terrainupdaterate = 20 -- update range checks every 12 updates. EG: update rate of 5 means we update ranges every 60 frames.

local spGetUnitWeaponTarget = Spring.GetUnitWeaponTarget
local spSetUnitTarget = Spring.SetUnitTarget
local spGetCommandQueue = Spring.GetCommandQueue
local spGetGroundHeight = Spring.GetGroundHeight
local spGetGroundOrigHeight = Spring.GetGroundOrigHeight
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetUnitDefID = Spring.GetUnitDefID
local spGetTeamList = Spring.GetTeamList
local spGetTeamUnitsByDefs = Spring.GetTeamUnitsByDefs
local spUtilitiesGetEffectiveWeaponRange = Spring.Utilities.GetEffectiveWeaponRange
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetUnitSeparation = Spring.GetUnitSeparation
local spGetUnitWeaponTestRange = Spring.GetUnitWeaponTestRange
local EMPTY = {}

for i = 1, #UnitDefs do
	local weapons = UnitDefs[i].weapons
	if #weapons > 0 then
		local c = 0
		for w = 1, #weapons do
			local WeaponDefID = weapons[w].weaponDef
			local WeaponDef = WeaponDefs[WeaponDefID]
			local cp = WeaponDef.customParams
			if cp and cp.overshoot then
				c = c + 1
				if overshootdefs[i] == nil then
					overshootdefs[i] = {}
				end
				local bonus = 0
				if WeaponDef.selfExplode then
					bonus = WeaponDef.projectilespeed * 2 -- this is an attempt at computing the max travel of a bullet. This is the travel distance within 4 frames.
				end
				if cp.overshoot_override then
					bonus = tonumber(cp.overshoot_override)
				end
				overshootdefs[i][c] = {id = w, aoe = WeaponDef.damageAreaOfEffect, bonus = bonus, range = WeaponDef.range, velocity = WeaponDef.projectilespeed, attackuw = cp.attempt_underwater ~= nil}
				if cp.attempt_underwater then
					overshootdefs[i].attacksubmerged = true
				end
				if cp.overshoot_maxvel then
					overshootdefs[i][c].maxvel = tonumber(cp.overshoot_maxvel)
				end
			end
		end
	end
end

local function GetLowestHeightOnCircle(x, z, radius, points)
	local anglepercheck = math.rad(360 / (points + 1))
	local currentangle = 0
	local lowest = math.huge
	for i = 1, points + 1 do
		local cx = x + radius * math.cos(currentangle)
		local cz = z + radius * math.sin(currentangle)
		currentangle = currentangle + anglepercheck
		local groundy = spGetGroundHeight(cx, cz)
		if groundy < lowest then
			lowest = groundy
		end
	end
	if lowest < 0 then -- don't bother with UW stuff.
		lowest = 0
	end
	return lowest
end

local function GetFirePoint(radius, x, z, targetx, targetz)
	local dx = targetx - x
	local dz = targetz - z
	local mag = 1 / math.sqrt((dx * dx) + (dz * dz))
	local tx = x + (radius * dx * mag)
	local tz = z + (radius * dz * mag)
	return tx, tz
end

local function AttackPosition(unitID, x, y, z, weaponID, data)
	GG.SetTemporaryPosTarget(unitID, x, y, z, false, updaterate + 1)
	data.engaged = true
end

local function Distance(x, z, x2, z2)
	return math.sqrt(((x - x2) * (x - x2)) + ((z2 - z) * (z2 - z)))
end

local function WeaponCorrection(unitID, weaponNum, x, y, z, range, tx, tz, sx, sz)
	local trys = 0
	local result = spGetUnitWeaponTestRange(unitID, weaponNum, x, y, z)
	if not result then
		repeat
			trys = trys + 1
			range = range - (2 * trys)
			x, z = GetFirePoint(range, sx, sz, tx, tz)
			y = spGetGroundHeight(x, z)
			result = spGetUnitWeaponTestRange(unitID, weaponNum, x, y, z)
		until trys == 10 or result
		if result then
			trys = 0
			local lastx, lastz, lasty
			repeat
				lastx = x
				lasty = y
				lastz = z
				trys = trys + 1
				range = range + 1
				x, z = GetFirePoint(range, sx, sz, tx, tz)
				y = spGetGroundHeight(x, z)
				result = spGetUnitWeaponTestRange(unitID, weaponNum, x, y, z)
			until not result or trys == 10
			x = lastx
			y = lasty
			z = lastz
		end
		--Spring.Echo("Tries: " .. trys)
		return x, y, z 
	else
		return x, y, z
	end
end

local function UpdateWeaponRange(unitID, unitDefID, weaponID, init) -- updates weapon range every 60 frames. Note: Not all units get their range update on the same update tick. This is by design.
	local x, y, z = spGetUnitPosition(unitID)
	local overshootdef = overshootdefs[unitDefID][weaponID]
	if init then
		local originalrange = overshootdef.range
		local weaponNum = overshootdef.id
		local oy = GetLowestHeightOnCircle(x, z, originalrange, 9)
		--Spring.Echo("Range: " .. spUtilitiesGetEffectiveWeaponRange(unitDefID, y - oy, weaponNum) + overshootdef.bonus + overshootdef.aoe)
		return spUtilitiesGetEffectiveWeaponRange(unitDefID, y - oy, weaponNum) + overshootdef.bonus + overshootdef.aoe
	else
		local data = IterableMap.Get(unitstocheck, unitID)
		local originalrange = data.weapons[weaponID].effectiverange
		local oy = GetLowestHeightOnCircle(x, z, originalrange, 9)
		data.weapons[weaponID].effectiverange = spUtilitiesGetEffectiveWeaponRange(unitDefID, y - oy, weaponNum) + overshootdef.bonus + overshootdef.aoe
		--Spring.Echo("New range: " .. data.weapons[weaponID].effectiverange)
	end
end

local function GetWeaponIsFiringAtSomething(unitID, weaponID)
	return spGetUnitWeaponTarget(unitID, weaponID) == 1
end

local function UpdateUnitTarget(unitID, unitDefID, weaponID)
	local myX, myY, myZ = spGetUnitPosition(unitID)
	local data = IterableMap.Get(unitstocheck, unitID)
	local weapon = data.weapons[weaponID]
	local weaponNum = weapon.id
	local theoreticalEffectiveRange = weapon.effectiverange -- our theoretical effective range
	-- look slightly beyond our theoretical range. This tries to help compensate for how coarse the theoretical range finder is when it's looking at terrain.
	local enemy = spGetUnitNearestEnemy(unitID, theoreticalEffectiveRange, true)
	local distance, actualRange, actualEffectiveRange
	local attacking = false
	if enemy then
		local _, enemybaseY, _, _, _, _, enemyX, enemyY, enemyZ = spGetUnitPosition(enemy, true, true)
		distance = spGetUnitSeparation(unitID, enemy)
		local groundUnderEnemy = math.max(spGetGroundHeight(enemyX, enemyZ), 0)
		local overshootdef = overshootdefs[unitDefID][weaponID]
		local miny = -15 -- because attacking SUBMERGED is just lol
		if weapon.canattackuw then
			miny = - overshootdef.aoe
		end
		--actualRange = math.floor(spUtilitiesGetEffectiveWeaponRange(unitDefID, myY - enemyY, weaponNum)) -- the actual range we have against the unit. Needed to be able to set the target reliably.
		actualRange = math.floor(Spring.Utilities.GetEffectiveWeaponRange(unitDefID, myY - enemyY, weaponNum))
		local pvelocity = overshootdef.velocity
		local traveltime = distance / pvelocity
		local velx, vely, velz, enemyvel = spGetUnitVelocity(enemy)
		local wantedX, wantedZ
		wantedX = enemyX + (traveltime * velx) -- crude leader (surprisingly effective)
		wantedZ = enemyZ + (traveltime * velz)
		local wantedRange = Distance(myX, myZ, wantedX, wantedZ)
		actualEffectiveRange = actualRange + overshootdef.bonus + overshootdef.aoe -- this is the range after weapon inaccuracy range gain takes effect.
		--Spring.Echo("Can attack UW: " .. tostring(weapon.canattackuw))
		--Spring.Echo("Actual range: " .. actualEffectiveRange .. "(" .. actualRange .. ", " ..  distance .. ")" .. "\n")
		if (distance > actualRange or (enemybaseY < -5 and weapon.canattackuw and weapon.notbeingused == 2)) and enemybaseY - groundUnderEnemy < 5 and enemyY >= miny and wantedRange <= actualEffectiveRange and (overshootdef.maxvel == nil or enemyvel <= overshootdef.maxvel) then -- only attack when there's nothing in our actual range that isn't flying
			local targetX, targetZ = GetFirePoint(wantedRange, myX, myZ, wantedX, wantedZ)
			local targetY
			targetX, targetY, targetZ = WeaponCorrection(unitID, weaponNum, targetX, groundUnderEnemy, targetZ, actualRange, enemyX, enemyZ, myX, myZ)
			--Spring.MarkerAddPoint(targetX, 0, targetZ, "Targeting " .. targetX .. "," .. targetZ, true)
			AttackPosition(unitID, targetX, targetY, targetZ, weaponNum, data)
			attacking = true
		end
	end
	if data.engaged and not attacking then
		--Spring.Echo("STOP")
		spGiveOrderToUnit(unitID, CMD.STOP, EMPTY, 0)
		data.engaged = false
	end
end

local function AddUnitToList(unitID, unitDefID)
	local data = {def = unitDefID, engaged = false, weapons = {}, updatecount = 0, index = #unitstocheck + 1, attacksubmerged = overshootdefs[unitDefID].attacksubmerged}
	for i = 1, #overshootdefs[unitDefID] do
		data.weapons[i] = {id = overshootdefs[unitDefID][i].id, canattackuw = overshootdefs[unitDefID][i].attackuw, notbeingused = 0, effectiverange = UpdateWeaponRange(unitID, unitDefID, overshootdefs[unitDefID][i].id, true)}
	end
	IterableMap.Add(unitstocheck, unitID, data)
end

local function RemoveUnitFromList(unitID)
	if not IterableMap.InMap(unitstocheck, unitID) then
		return
	end
	IterableMap.Remove(unitstocheck, unitID)
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if overshootdefs[unitDefID] then
		AddUnitToList(unitID, unitDefID)
	end
end

function gadget:UnitReverseBuilt(unitID, unitDefID, unitTeam)
	RemoveUnitFromList(unitID)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	RemoveUnitFromList(unitID)
end

function gadget:GameFrame(f)
	if f%updaterate == 0 then
		local total = IterableMap.GetIndexMax(unitstocheck)
		--Spring.Echo("Updating " .. total)
		for i = 1, total do
			local unitID, data = IterableMap.Next(unitstocheck)
			if data then
				local unitDefID = data.def
				local weapons = data.weapons
				local queuesize = spGetCommandQueue(unitID, 0)
				if not queuesize or queuesize == 0 then
					for w = 1, #weapons do
						local weaponID = weapons[w].id
						UpdateUnitTarget(unitID, unitDefID, weaponID)
						if data.updatecount == terrainupdaterate then
							UpdateWeaponRange(unitID, unitDefID, weaponID, false)
						end
					end
				end
				if data.updatecount == terrainupdaterate then
					data.updatecount = 0
				else
					data.updatecount = data.updatecount + 1
				end
			end
		end
	end
	if f%updaterate == updaterate - 1 then
		local total = IterableMap.GetIndexMax(unitstocheck)
		for i = 1, total do
			local unitID, data = IterableMap.Next(unitstocheck)
			if data and data.attacksubmerged then
				local weapons = data.weapons
				for w = 1, #weapons do
					local weaponID = weapons[w].id
					local isusefultargeting = GetWeaponIsFiringAtSomething(unitID, weaponID)
					if isusefultargeting or weapons[w].notbeingused > 2 then
						data.weapons[w].notbeingused = 0
					else
						data.weapons[w].notbeingused = data.weapons[w].notbeingused + 1
					end
				end
			end
		end
	end
end
