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
local updaterate = 5

local spSetUnitTarget = Spring.SetUnitTarget
local spGetUnitWeaponTestTarget = Spring.GetUnitWeaponTestTarget
local spGetCommandQueue = Spring.GetCommandQueue
local spGetGroundHeight = Spring.GetGroundHeight
local spGetGroundOrigHeight = Spring.GetGroundOrigHeight
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local EMPTY = {}

for i = 1, #UnitDefs do
	local weapons = UnitDefs[i].weapons
	if #weapons > 0 then
		for w = 1, #weapons do
			local WeaponDefID = weapons[w].weaponDef
			local WeaponDef = WeaponDefs[WeaponDefID]
			local cp = WeaponDef.customParams
			if cp and cp.overshoot then
				if overshootdefs[i] then
					overshootdefs[i][w] = {aoe = WeaponDef.damageAreaOfEffect, bonus = tonumber(cp.overshoot), range = WeaponDef.range}
				else
					overshootdefs[i] = {}
					overshootdefs[i][w] = {aoe = WeaponDef.damageAreaOfEffect, bonus = tonumber(cp.overshoot), range = WeaponDef.range}
				end
			end
		end
	end
end

local function GetDistance(x, z, x2, z2)
	return math.sqrt(((x2 - x) * (x2 - x)) + ((z2 - z) * (z2 - z)))
end

local function GetLowestHeightOnCircle(x, z, radius, points)
	local anglepercheck = math.rad((2 * math.pi) / points + 1)
	local currentangle = 0
	local lowest = math.huge
	for i = 1, points + 1 do
		local cx = x + radius * math.sin(currentangle)
		local cz = z + radius * math.cos(currentangle)
		currentangle = currentangle + anglepercheck
		local groundy = spGetGroundHeight(cx, cz)
		if groundy < lowest  then
			lowest = groundy
		end
	end
	if lowest < 0 then -- don't bother with UW stuff.
		lowest = 0
	end
	return lowest
end


local function GetFirePoint(radius, x, z, targetx, targetz)
	local angle = math.atan2((z - targetz), (x - targetx))
	angle = -angle + math.rad(270) -- I hate trig in spring. Don't ask me how this works, it just does.
	--local angle = Spring.Utilities.Vector.Angle(x - targetx, z - targetz) -- this doesn't seem to work, gives wrong angle.
	local tx = x + (radius * math.sin(angle))
	local tz = z + (radius * math.cos(angle))
	return tx, tz
end

local function AttackPosition(unitID, x, y, z, weaponID)
	local testresult = spGetUnitWeaponTestTarget(unitID, weaponID, x, y, z)
	if spGetUnitWeaponTestTarget(unitID, weaponID, x, y, z) then -- probably needs some friendly fire test
		spSetUnitTarget(unitID, x, y, z, false, true, weaponID)
		overwatch[unitID].engaged = true
	end
end

local function ClearAttack(unitID) -- this probably needs some changing. I couldn't figure out how to clear targets without issuing a command and didn't want stardusts to sit shooting at a spot indefinitely
	spSetUnitTarget(unitID, nil)
	overwatch[unitID].engaged = false
	spGiveOrderToUnit(unitID, CMD.STOP, EMPTY, EMPTY)
end

local function UpdateUnitTarget(unitID, unitDefID, weaponID)
	local x2, y2, z2 = spGetUnitPosition(unitID)
	local overshootdef = overshootdefs[unitDefID][weaponID]
	local originalrange = overshootdef.range
	local oy = math.min(spGetGroundOrigHeight(x2, z2), GetLowestHeightOnCircle(x2, z2, originalrange, 9)) -- rudimentary check for cliffs and stuff.
	local truerange = Spring.Utilities.GetEffectiveWeaponRange(unitDefID, y2 - oy, weaponID)
	local effectiverange = truerange + (overshootdef.aoe * overshootdef.bonus)
	local enemy = spGetUnitNearestEnemy(unitID, effectiverange, true)
	if enemy then
		local x, y, z = spGetUnitPosition(enemy)
		if GetDistance(x, z, x2, z2) > truerange then -- only attack when there's nothing in our actual range.
			local tx, tz = GetFirePoint(truerange, x2, z2, x, z)
			AttackPosition(unitID, tx, y, tz, weaponID)
		elseif overwatch[unitID].engaged then -- when there's things in our range, we want to clear our overshot target and start blasting whatever's in our range instead
			ClearAttack(unitID)
		end
	elseif overwatch[unitID].engaged then
		ClearAttack(unitID)
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if overshootdefs[unitDefID] then
		overwatch[unitID] = {def = unitDefID, engaged = false}
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
		for id, data in pairs(overwatch) do
			local unitdefID = data.def
			if #spGetCommandQueue(id, 1) == 0 then -- has no active command, so feel free to engage. Note this check is mostly so that users can override the AI.
				for weapon, _ in pairs(overshootdefs[unitdefID]) do
					UpdateUnitTarget(id, unitdefID, weapon)
				end
			end
		end
	end
end
