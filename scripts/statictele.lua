include "constants.lua"

local base = piece "base"
local gen1 = piece "gen1"
local gen2 = piece "gen2"

local smokePiece = {gen1}

local teleRadius = 400
local teleMaxTries = 30

local spTestMoveOrder = Spring.TestMoveOrder
local spGetGroundHeight = Spring.GetGroundHeight
local spSetHeightMapFunc = Spring.SetHeightMapFunc
local spSetHeightMap = Spring.SetHeightMap

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	script.Activate()
end

function script.Activate()
	Spin(gen1, y_axis, 1, 0.01)
	Spin(gen2, y_axis, -1, 0.01)
end

function script.Deactivate()
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
	local angle = math.random() * math.tau
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
	
	GG.MoveGeneralUnit(uID, dx, false, dz)
	
	_, _, _, ax, ay, az = Spring.GetUnitPosition(uID, true)
	Spring.SpawnCEG("teleport_in", dx, ay, dz, 0, 0, 0, size)
	
	local blocking = oldBlocking[uID]
	Spring.SetUnitBlocking(uID, blocking[1], blocking[2], blocking[3], blocking[4], blocking[5], blocking[6], blocking[7])
	oldBlocking[uID] = nil
end

local function GetMedianEdgeHeight(ox, oz, radius, samples)
	local heights = {}
	local sampleToRad = 2 * math.pi / samples
	for i = 1, samples do
		local x = math.cos(i*sampleToRad)*radius
		local z = math.sin(i*sampleToRad)*radius
		heights[#heights + 1] = spGetGroundHeight(x + ox, z + oz)
	end
	table.sort(heights)
	return heights[math.ceil(#heights / 2)]
end

local function SwapTerrain(ox, oz, tx, tz, radius)
	local rightBound = math.ceil(radius/8)*8
	local botBound = math.ceil(radius/8)*8
	local radSq = radius*radius
	
	local oEdgeHeight = GetMedianEdgeHeight(ox, oz, radius - 8, 72)
	local tEdgeHeight = GetMedianEdgeHeight(tx, tz, radius - 8, 72)
	
	spSetHeightMapFunc(function ()
		for x = math.floor(-radius/8)*8, rightBound, 8 do
			for z = math.floor(-radius/8)*8, botBound, 8 do
				if x*x + z*z <= radSq then
					local oHeight = spGetGroundHeight(x + ox, z + oz)
					local tHeight = spGetGroundHeight(x + tx, z + tz)
					spSetHeightMap(x + ox, z + oz, tHeight + oEdgeHeight - tEdgeHeight)
					spSetHeightMap(x + tx, z + tz, oHeight + tEdgeHeight - oEdgeHeight)
				end
			end
		end
	end)
	Spring.ForceTesselationUpdate(true, true)
end

local function DoTeleport(tx, tz)
	local ux, _, uz = Spring.GetUnitPosition(unitID)
	ux, uz = math.floor((ux + 4)/8)*8, math.floor((uz + 4)/8)*8
	tx, tz = math.floor((tx + 4)/8)*8, math.floor((tz + 4)/8)*8
	
	local unitsNearTarget = Spring.GetUnitsInCylinder(tx, tz, teleRadius)
	local unitsNearMe = Spring.GetUnitsInCylinder(ux, uz, teleRadius)
	unitsNearTarget = FilterOutUnitAndUnblock(unitsNearTarget, unitID)
	unitsNearMe = FilterOutUnitAndUnblock(unitsNearMe, unitID)
	
	SwapTerrain(ux, uz, tx, tz, teleRadius)
	
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
	return gen1
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
