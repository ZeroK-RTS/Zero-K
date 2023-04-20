include "constants.lua"

local base = piece "base"
local gen1 = piece "gen1"
local gen2 = piece "gen2"

local smokePiece = {gen1}

local tau = 2*math.pi

local teleRadius = 400
local teleMaxTries = 30

local spTestMoveOrder = Spring.TestMoveOrder

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.Activate ()
	Spin(gen1, y_axis, 1, 0.01)
	Spin(gen2, y_axis, -1, 0.01)
end

function script.Deactivate ()
	StopSpin(gen1, y_axis, 0.1)
	StopSpin(gen2, y_axis, 0.1)
end

local oldBlocking = {}
local sizeCache = {}

local function SizeCacheSort(a, b)
	return sizeCache[a] > sizeCache[b]
end

local function FilterOutUnitAndUnblock(unitList, toFilterOut)
	for i = 1, #unitList do
		if unitList[i] == toFilterOut then
			unitList[i] = unitList[#unitList]
			unitList[#unitList] = nil
			break
		end
	end
	for i = 1, #unitList do
		local b1, b2, b3, b4, b5, b6, b7 = Spring.GetUnitBlocking(unitList[i])
		oldBlocking[unitList[i]] = {b1, b2, b3, b4, b5, b6, b7}
		Spring.SetUnitBlocking(unitList[i], false, false, false, false, false, false, false)
		
		local udid = Spring.GetUnitDefID(unitList[i])
		if Spring.Utilities.GetMovetypeUnitDefID(udid) then
			sizeCache[unitList[i]] = Spring.GetUnitMass(unitList[i])
		else
			local ud = UnitDefs[udid]
			sizeCache[unitList[i]] = math.max(ud.xsize, ud.zsize) + 100000
		end
	end
	table.sort(unitList, SizeCacheSort)
	return unitList
end

local function RandomPointInCircle(cx, cz, radius)
	local r = radius*math.sqrt(math.random())
	local angle = math.random()*tau
	local rx, rz = cx + r*math.cos(angle), cz + r*math.sin(angle)
	return rx, rz
end

local function FindStaticUnitLocation(uID, udid, tx, tz, radius)
	local facing = Spring.GetUnitBuildFacing(uID)
	local tries = 1
	local dx, dz
	while tries <= teleMaxTries do
		dx, dz = RandomPointInCircle(tx, tz, radius - 8 + ((tries > teleMaxTries*0.5 and (radius * 3 * (tries/teleMaxTries - 0.5))) or 0))
		dx, dz = Spring.Utilities.ClampPosition(dx, dz)
		dx, dz = Spring.Utilities.SnapToBuildGrid(udid, facing, dx, dz)
		local place, feature = Spring.TestBuildOrder(udid, dx, 0, dz, facing)
		if ((place == 2) or (tries > teleMaxTries*0.7 and place == 1)) and (feature == nil or tries > teleMaxTries*0.3) then
			break
		end
		tries = tries + 1
	end
	return dx, dz
end

local function FindMobileUnitLocation(uID, udid, tx, tz, radius)
	local tries = 1
	local dx, dz
	while tries <= teleMaxTries do
		dx, dz = RandomPointInCircle(tx, tz, radius)
		dx, dz = Spring.Utilities.ClampPosition(dx, dz)
		if spTestMoveOrder(udid, dx, 0, dz, 0, 0, 0, true, true, tries > teleMaxTries*0.5) then
			break
		end
		tries = tries + 1
	end
	Spring.Utilities.UnitEcho(uID, tries)
	return dx, dz
end

local function TeleportUnit(uID, tx, tz, radius)
	if not oldBlocking[uID] then
		return
	end
	local udid = Spring.GetUnitDefID(uID)
	local dx, dz
	if Spring.Utilities.GetMovetypeUnitDefID(udid) then
		dx, dz = FindMobileUnitLocation(uID, udid, tx, tz, radius)
	else
		dx, dz = FindStaticUnitLocation(uID, udid, tx, tz, radius)
	end
	
	local size = UnitDefs[udid].xsize
	local _, _, _, ax, ay, az = Spring.GetUnitPosition(uID, true)
	Spring.SpawnCEG("teleport_out", ax, ay, az, 0, 0, 0, size)
	Spring.SetUnitPosition(uID, dx, dz)
	_, _, _, ax, ay, az = Spring.GetUnitPosition(uID, true)
	Spring.SpawnCEG("teleport_in", dx, ay, dz, 0, 0, 0, size)
	
	local blocking = oldBlocking[uID]
	Spring.SetUnitBlocking(uID, blocking[1], blocking[2], blocking[3], blocking[4], blocking[5], blocking[6], blocking[7])
	oldBlocking[uID] = nil
end

local function DoTeleport(tx, tz)
	local ux, _, uz = Spring.GetUnitPosition(unitID)
	
	local unitsNearTarget = Spring.GetUnitsInCylinder(tx, tz, teleRadius)
	local unitsNearMe = Spring.GetUnitsInCylinder(ux, uz, teleRadius)
	unitsNearTarget = FilterOutUnitAndUnblock(unitsNearTarget, unitID)
	unitsNearMe = FilterOutUnitAndUnblock(unitsNearMe, unitID)
	
	for i = 1, #unitsNearMe do
		TeleportUnit(unitsNearMe[i], tx, tz, teleRadius)
	end
	for i = 1, #unitsNearTarget do
		TeleportUnit(unitsNearTarget[i], ux, uz, teleRadius)
	end
end

local function FireTeleporter()
	local cmdID, _, cmdTag, cmdParam1, cmdParam2, cmdParam3 = Spring.GetUnitCurrentCommand(unitID)
	local tx, ty, tz
	if cmdID == CMD.ATTACK then
		if cmdParam3 then
			tx, ty, tz = cmdParam1, cmdParam2, cmdParam3
		elseif not cmdParam2 then
			targetID = cmdParam1
			tx, ty, tz = Spring.GetUnitPosition(targetID)
		end
	end
	if not tx then
		return
	end
	Spring.GiveOrderToUnit(unitID, CMD.REMOVE, cmdTag, 0)
	DoTeleport(tx, tz)
end

function script.QueryWeapon(num)
	return base
end

function script.AimWeapon(num, heading, pitch)
	return true
end

function script.BlockShot(num, targetID)
	FireTeleporter()
	return true
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(base, SFX.NONE)
		Explode(gen1, SFX.NONE)
		Explode(gen2, SFX.NONE)
		return 1
	else
		Explode(base, SFX.SHATTER)
		Explode(gen1, SFX.SHATTER)
		Explode(gen2, SFX.SHATTER)
		return 2
	end
end
