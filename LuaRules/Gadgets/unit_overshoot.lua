function gadget:GetInfo()
	return {
		name      = "Overshoot AI",
		desc      = "Shoot at things beyond a unit's range using AOE",
		author    = "Shaman",
		date      = "10-22-2020",
		license   = "PD",
		layer     = 5,
		enabled   = true,
	}
end

if not (gadgetHandler:IsSyncedCode()) then
	return
end

local overshootdefs = {} -- unitdefs to watch
local overwatch = {} -- units that have the ai enabled.
local unitstocheck = {}
local updaterate = 5 -- the rate we update units.
local terrainupdaterate = 12 -- update range checks every 12 updates. EG: update rate of 5 means we update ranges every 60 frames.

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
				overshootdefs[i][c] = {id = w, aoe = WeaponDef.damageAreaOfEffect, bonus = bonus, range = WeaponDef.range, velocity = WeaponDef.projectilespeed}
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

local function RemoveUnitFromList(unitID)
	if overwatch[unitID] == nil then
		return
	end
	local index = overwatch[unitID].index
	if index == #unitstocheck then
		unitstocheck[index] = nil
	else
		table.remove(unitstocheck, index)
	end
	overwatch[unitID] = nil
end

local function GetFirePoint(radius, x, z, targetx, targetz)
	local dx = targetx - x
	local dz = targetz - z
	local mag = 1 / math.sqrt((dx * dx) + (dz * dz))
	local tx = x + (radius * dx * mag)
	local tz = z + (radius * dz * mag)
	return tx, tz
end

local function AttackPosition(unitID, x, y, z, weaponID)
	GG.SetTemporaryPosTarget(unitID, x, y, z, false, updaterate + 1)
	overwatch[unitID].engaged = true
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

local function UpdateWeaponRange(unitID, unitDefID, weaponID) -- updates weapon range every 60 frames. Note: Not all units get their range update on the same update tick. This is by design.
	local x, y, z = spGetUnitPosition(unitID)
	local overshootdef = overshootdefs[unitDefID][weaponID]
	local originalrange = overwatch[unitID].weapons[weaponID].effectiverange or overshootdef.range
	local weaponNum = overshootdef.id
	local oy = GetLowestHeightOnCircle(x, z, originalrange, 19) -- tests 20 equidistant points on the unit's edge of range. This is a crude way of detecting cliffs and stuff.
	local newrange = spUtilitiesGetEffectiveWeaponRange(unitDefID, y - oy, weaponNum)
	local effectiverange = newrange + overshootdef.bonus + overshootdef.aoe
	overwatch[unitID]["weapons"][weaponID].effectiverange = effectiverange
	--Spring.Echo("New range: " .. effectiverange .. "(Bonus: " .. overshootdef.bonus .. ")")
end

local function UpdateUnitTarget(unitID, unitDefID, weaponID)
	local myX, myY, myZ = spGetUnitPosition(unitID)
	local weapon = overwatch[unitID].weapons[weaponID]
	local weaponNum = weapon.id
	local theoreticalEffectiveRange = weapon.effectiverange -- our theoretical effective range
	-- look slightly beyond our theoretical range. This tries to help compensate for how coarse the theoretical range finder is when it's looking at terrain.
	local enemy = spGetUnitNearestEnemy(unitID, theoreticalEffectiveRange, true)
	local distance, actualRange, actualEffectiveRange
	if enemy then
		local _, enemybaseY, _, _, _, _, enemyX, enemyY, enemyZ = spGetUnitPosition(enemy, true, true)
		distance = spGetUnitSeparation(unitID, enemy)
		local groundUnderEnemy = math.max(spGetGroundHeight(enemyX, enemyZ), 0)
		local overshootdef = overshootdefs[unitDefID][weaponID]
		local miny = - (overshootdef.aoe / 2) -- because attacking SUBMERGED is just lol
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
		--Spring.Echo("Actual range: " .. actualEffectiveRange .. "(" .. actualRange .. ", " ..  distance .. ")" .. "\n")
		if distance > actualRange and enemybaseY - groundUnderEnemy < 5 and enemyY >= miny and wantedRange <= actualEffectiveRange and (overshootdef.maxvel == nil or enemyvel <= overshootdef.maxvel) then -- only attack when there's nothing in our actual range that isn't flying
			local targetX, targetZ = GetFirePoint(wantedRange, myX, myZ, wantedX, wantedZ)
			local targetY
			targetX, targetY, targetZ = WeaponCorrection(unitID, weaponNum, targetX, groundUnderEnemy, targetZ, actualRange, enemyX, enemyZ, myX, myZ)
			--Spring.MarkerAddPoint(targetX, 0, targetZ, "Targeting " .. targetX .. "," .. targetZ, true)
			AttackPosition(unitID, targetX, targetY, targetZ, weaponNum)
		end
	end
	if overwatch[unitID].engaged and (not enemy or distance <= actualRange or (enemy and distance > actualEffectiveRange)) then
		--Spring.Echo("STOP")
		spGiveOrderToUnit(unitID, CMD.STOP, EMPTY, 0)
		overwatch[unitID].engaged = false
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if overshootdefs[unitDefID] then
		overwatch[unitID] = {def = unitDefID, engaged = false, weapons = {}, updatecount = 0, index = #unitstocheck + 1}
		for i = 1, #overshootdefs[unitDefID] do
			overwatch[unitID].weapons[i] = {effectiverange = 0, id = overshootdefs[unitDefID][i].id}
			UpdateWeaponRange(unitID, unitDefID, i)
		end
		unitstocheck[#unitstocheck + 1] = unitID
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
		for i = 1, #unitstocheck do
			local unitID = unitstocheck[i]
			local data = overwatch[unitID]
			if data then
				local unitDefID = data.def
				local weapons = data.weapons
				if #spGetCommandQueue(unitID, 1) == 0 then
					for w = 1, #weapons do
						UpdateUnitTarget(unitID, unitDefID, w)
						if data.updatecount == terrainupdaterate then
							UpdateWeaponRange(unitID, unitDefID, w)
						end
					end
				end
				if data.updatecount == terrainupdaterate then
					overwatch[unitID].updatecount = 0
				else
					overwatch[unitID].updatecount = overwatch[unitID].updatecount + 1
				end
			end
		end
	end
end
