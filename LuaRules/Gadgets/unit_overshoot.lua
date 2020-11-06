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
local watchlist = {} -- list of all the unitdefs this has
local updaterate = 5
local terrainupdaterate = 45/updaterate

local spSetUnitTarget = Spring.SetUnitTarget
local spGetUnitWeaponTestTarget = Spring.GetUnitWeaponTestTarget
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
local EMPTY = {}

for i = 1, #UnitDefs do
	local weapons = UnitDefs[i].weapons
	if #weapons > 0 then
		local c = 0
		for w = 1, #weapons do
			local WeaponDefID = weapons[w].weaponDef
			local WeaponDef = WeaponDefs[WeaponDefID]
			local cp = WeaponDef.customParams
			if cp and cp.overshoot then -- NOTE: overshoot field is a multiplier to unit range. Use 1 for things that aren't like stardust. 
				c = c + 1
				if overshootdefs[i] == nil then
					overshootdefs[i] = {}
					watchlist[#watchlist + 1] = i
				end
				overshootdefs[i][c] = {id = w, aoe = WeaponDef.damageAreaOfEffect, bonus = tonumber(cp.overshoot), range = WeaponDef.range}
			end
		end
	end
end

local function GetDistance(x, z, x2, z2)
	return math.sqrt(((x2 - x) * (x2 - x)) + ((z2 - z) * (z2 - z)))
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
	local angle = Spring.Utilities.Vector.Angle(targetx - x, targetz - z)
	local tx = x + (radius * math.cos(angle))
	local tz = z + (radius * math.sin(angle))
	return tx, tz
end

local function AttackPosition(unitID, x, y, z, weaponID)
	GG.SetTemporaryPosTarget(unitID, x, y, z, false, updaterate + 1)
	overwatch[unitID].engaged = true
end

local function UpdateWeaponRange(unitID, unitDefID, weaponID) -- updates weapon range every 45 frames. Note: Not all units get their range update on the same update tick.
	local x, y, z = spGetUnitPosition(unitID, true, false) -- use midpoint.
	local overshootdef = overshootdefs[unitDefID][weaponID]
	local originalrange = overshootdef.range
	local oy = math.min(spGetGroundOrigHeight(x, z), GetLowestHeightOnCircle(x, z, originalrange, 9)) -- tests 10 equidistant points on the unit's edge of range. This is a crude way of detecting cliffs and stuff.
	local newrange = spUtilitiesGetEffectiveWeaponRange(unitDefID, y - oy, weaponID)
	local effectiverange = ((newrange + 1) * overshootdef.bonus) + overshootdef.aoe
	overwatch[unitID]["weapons"][weaponID].effectiverange = effectiverange
end

local function UpdateUnitTarget(unitID, unitDefID, weaponID)
	local myX, myY, myZ = spGetUnitPosition(unitID, true) -- midpoint
	local weapon = overwatch[unitID]["weapons"][weaponID]
	local theoreticalEffectiveRange = weapon.effectiverange -- our theoretical effective range
	local enemy = spGetUnitNearestEnemy(unitID, theoreticalEffectiveRange, true)
	local distance, actualRange
	if enemy then
		local enemyX, enemyY, enemyZ = spGetUnitPosition(enemy)
		distance = GetDistance(myX, myZ, enemyX, enemyZ)
		local groundUnderEnemy = spGetGroundHeight(enemyX, enemyZ)
		actualRange = spUtilitiesGetEffectiveWeaponRange(unitDefID, myY - enemyY, weaponID) -- the actual range we have against the unit. Needed to be able to set the target.
		if distance > actualRange and enemyY - groundUnderEnemy < 5 then -- only attack when there's nothing in our actual range that isn't flying
			local targetX, targetZ = GetFirePoint(actualRange, myX, myZ, enemyX, enemyZ)
			AttackPosition(unitID, targetX, groundUnderEnemy, targetZ, weaponID)
		end
	end
	if overwatch[unitID].engaged and (not enemy or distance <= actualRange) then
		spGiveOrderToUnit(unitID, CMD.STOP, EMPTY, 0)
		overwatch[unitID].engaged = false
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if overshootdefs[unitDefID] then
		overwatch[unitID] = {def = unitDefID, engaged = false, weapons = {}, updatecount = 0}
		for i = 1, #overshootdefs[unitDefID] do
			overwatch[unitID].weapons[i] = {effectiverange = 0, id = overshootdefs[unitDefID][i].id}
			UpdateWeaponRange(unitID, unitDefID, i)
		end
	end
end

function gadget:UnitReverseBuilt(unitID, unitDefID, unitTeam)
	overwatch[unitID] = nil
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	overwatch[unitID] = nil
end

function gadget:GameFrame(f)
	if f%updaterate == 0 then
		local teamlist = spGetTeamList()
		for t = 1, #teamlist do
			local teamID = teamlist[t]
			for d = 1, #watchlist do
				local unitDefID = watchlist[d]
				local units = spGetTeamUnitsByDefs(teamID, watchlist[d])
				if #units ~= 0 then
					for u = 1, #units do
						local unitID = units[u]
						local data = overwatch[unitID]
						if data and #spGetCommandQueue(unitID, 1) == 0 then
							local weapons = data.weapons
							for w = 1, #weapons do
								local weaponID = weapons[w].id
								UpdateUnitTarget(unitID, unitDefID, weaponID)
								if data.updatecount == terrainupdaterate then
									UpdateWeaponRange(unitID, unitDefID, w)
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
		end
	end
end
