include "constants.lua"

dyncomm = include('dynamicCommander.lua')

local spSetUnitShieldState = Spring.SetUnitShieldState

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local pieceMap = Spring.GetUnitPieceMap(unitID)
local HAS_GATTLING = pieceMap.rgattlingflare and true or false
local HAS_BONUS_CANNON = pieceMap.bonuscannonflare and true or false

local torso = piece 'torso' 

local rcannon_flare= HAS_GATTLING and piece('rgattlingflare') or piece('rcannon_flare') 
local barrels = HAS_GATTLING and piece 'barrels' or nil
local lcannon_flare = HAS_BONUS_CANNON and piece('bonuscannonflare') or piece('lnanoflare')
local lnanoflare = piece 'lnanoflare' 
local lnanohand = piece 'lnanohand' 
local larm = piece 'larm' 
local rarm = piece 'rarm' 
local pelvis = piece 'pelvis' 
local rupleg = piece 'rupleg' 
local lupleg = piece 'lupleg' 
local rhand = piece 'rhand' 
local lleg = piece 'lleg' 
local lfoot = piece 'lfoot' 
local rleg = piece 'rleg' 
local rfoot = piece 'rfoot' 

local smokePiece = {torso}
local nanoPieces = {lnanoflare}
--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
local SIG_MOVE = 1
local SIG_LASER = 2
local SIG_DGUN = 4
local SIG_RESTORE_LASER = 8
local SIG_RESTORE_DGUN = 16
local SIG_RESTORE_TORSO = 32

local TORSO_SPEED_YAW = math.rad(300)
local ARM_SPEED_PITCH = math.rad(180)

local PACE = 1.8
local BASE_VELOCITY = UnitDefNames.benzcom1.speed or 1.25*30
local VELOCITY = UnitDefs[unitDefID].speed or BASE_VELOCITY
PACE = PACE * VELOCITY/BASE_VELOCITY

local THIGH_FRONT_ANGLE = -math.rad(45)
local THIGH_FRONT_SPEED = math.rad(42) * PACE
local THIGH_BACK_ANGLE = math.rad(30)
local THIGH_BACK_SPEED = math.rad(40) * PACE
local SHIN_FRONT_ANGLE = math.rad(40)
local SHIN_FRONT_SPEED = math.rad(60) * PACE
local SHIN_BACK_ANGLE = math.rad(15)
local SHIN_BACK_SPEED = math.rad(60) * PACE

local ARM_FRONT_ANGLE = -math.rad(15)
local ARM_FRONT_SPEED = math.rad(14.5) * PACE
local ARM_BACK_ANGLE = math.rad(5)
local ARM_BACK_SPEED = math.rad(14.5) * PACE
local ARM_PERPENDICULAR = math.rad(90)
--[[
local FOREARM_FRONT_ANGLE = -math.rad(15)
local FOREARM_FRONT_SPEED = math.rad(40) * PACE
local FOREARM_BACK_ANGLE = -math.rad(10)
local FOREARM_BACK_SPEED = math.rad(40) * PACE
]]--

local TORSO_ANGLE_MOTION = math.rad(8)
local TORSO_SPEED_MOTION = math.rad(7)*PACE

local RESTORE_DELAY = 2500

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local isMoving, isLasering, isDgunning, gunLockOut = false, false, false, false
local restoreHeading, restorePitch = 0, 0

local starBLaunchers = {}
local wepTable = UnitDefs[unitDefID].weapons
wepTable.n = nil
for index, weapon in pairs(wepTable) do
	local weaponDef = WeaponDefs[weapon.weaponDef]
	if weaponDef.type == "StarburstLauncher" then
		starBLaunchers[index] = true
		--Spring.Echo("sbl found")
	end
end
wepTable = nil

--------------------------------------------------------------------------------
-- Walking
--------------------------------------------------------------------------------
local PACE_MULT = 0.7
local PACE = 2*PACE_MULT
local BASE_VELOCITY = UnitDefNames.benzcom1.speed or 1.25*30
local VELOCITY = UnitDefs[unitDefID].speed or BASE_VELOCITY
local PACE = PACE * VELOCITY/BASE_VELOCITY

local SLEEP_TIME = 360/PACE_MULT

local walkCycle = 1 -- Alternate between 1 and 2

local walkAngle = {
	{ -- Moving forwards
		{
			hip = {math.rad(-12), math.rad(35) * PACE},
			leg = {math.rad(80), math.rad(100) * PACE},
			foot = {math.rad(5), math.rad(40) * PACE},
			arm = {math.rad(-10), math.rad(10) * PACE},
		},
		{
			hip = {math.rad(-40), math.rad(50) * PACE},
			leg = {math.rad(10), math.rad(100) * PACE},
			foot = {math.rad(-5), math.rad(140) * PACE},
		},
	},
	{ -- Moving backwards
		{
			hip = {math.rad(2), math.rad(50) * PACE},
			leg = {math.rad(2), math.rad(40) * PACE},
			foot = {math.rad(8), math.rad(20) * PACE},
			arm = {math.rad(10), math.rad(15) * PACE},
		},
		{
			hip = {math.rad(20), math.rad(25) * PACE},
			leg = {math.rad(35), math.rad(35) * PACE},
			foot = {math.rad(-10), math.rad(80) * PACE},
		}
		
	},
}

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	local speedMult = 1
	local scaleMult = dyncomm.GetScale()
	
	while true do
		walkCycle = 3 - walkCycle
		local speedMult = (Spring.GetUnitRulesParam(unitID,"totalMoveSpeedChange") or 1)*dyncomm.GetPace()
		
		local left = walkAngle[walkCycle] 
		local right = walkAngle[3 - walkCycle] 
		-----------------------------------------------------------------------------------
		
		Turn(lupleg, x_axis,  left[1].hip[1],  left[1].hip[2] * speedMult)
		Turn(lleg, x_axis, left[1].leg[1],  left[1].leg[2] * speedMult)
		Turn(lfoot, x_axis, left[1].foot[1], left[1].foot[2] * speedMult)
		
		Turn(rupleg, x_axis,  right[1].hip[1],  right[1].hip[2] * speedMult)
		Turn(rleg, x_axis, right[1].leg[1],  right[1].leg[2] * speedMult)
		Turn(rfoot, x_axis,  right[1].foot[1], right[1].foot[2] * speedMult)
		
		if not (isLasering or isDgunning) then
			Turn(larm, x_axis, left[1].arm[1],  left[1].arm[2] * speedMult)
			Turn(rarm, x_axis, right[1].arm[1],  right[1].arm[2] * speedMult)
		end
		
		Sleep(SLEEP_TIME / speedMult)
		-----------------------------------------------------------------------------------
		
		Turn(lupleg, x_axis,  left[2].hip[1],  left[2].hip[2] * speedMult)
		Turn(lleg, x_axis, left[2].leg[1],  left[2].leg[2] * speedMult)
		Turn(lfoot, x_axis, left[2].foot[1], left[2].foot[2] * speedMult)
		
		Turn(rupleg, x_axis,  right[2].hip[1],  right[2].hip[2] * speedMult)
		Turn(rleg, x_axis, right[2].leg[1],  right[2].leg[2] * speedMult)
		Turn(rfoot, x_axis,  right[2].foot[1], right[2].foot[2] * speedMult)
		
		if not (isLasering or isDgunning) then
			Turn(torso, z_axis, -0.1*(walkCycle - 1.5), 0.12 * speedMult)
		end
		
		Sleep(SLEEP_TIME / speedMult)
	end
end

local function RestoreLegs()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Move(pelvis, y_axis, 0, 1)
	Turn(lupleg, x_axis, 0, math.rad(200))
	Turn(lleg, x_axis, 0, math.rad(200))
	Turn(lfoot, x_axis, 0, math.rad(200))
	Turn(rupleg, x_axis, 0, math.rad(200))
	Turn(rleg, x_axis, 0, math.rad(200))
	Turn(rfoot, x_axis, 0, math.rad(200))
	Turn(torso, y_axis, 0, math.rad(200))
	if not (isLasering or isDgunning) then
		Turn(larm, x_axis, 0, math.rad(200))
		Turn(rarm, x_axis, 0, math.rad(200))
		Turn(torso, z_axis, 0, math.rad(200))
	end
end


function script.Create()
	dyncomm.Create()
	Hide(rcannon_flare)
	Hide(lnanoflare)
	
--	Turn(larm, x_axis, math.rad(30))
--	Turn(rarm, x_axis, math.rad(-10))
--	Turn(rhand, x_axis, math.rad(41))
--	Turn(lnanohand, x_axis, math.rad(36))
	
	StartThread(GG.Script.SmokeUnit, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.StartMoving() 
	isMoving = true
	StartThread(Walk)
end

function script.StopMoving() 
	isMoving = false
	StartThread(RestoreLegs)
end

--------------------------------------------------------------------------------
-- Aiming
--------------------------------------------------------------------------------

local function RestoreTorsoAim()
	Signal(SIG_RESTORE_TORSO)
	SetSignalMask(SIG_RESTORE_TORSO)
	Sleep(RESTORE_DELAY)
	Turn(torso, y_axis, restoreHeading, TORSO_SPEED_YAW)
end

local function RestoreLaser()
	StartThread(RestoreTorsoAim)
	Signal(SIG_RESTORE_LASER)
	SetSignalMask(SIG_RESTORE_LASER)
	Sleep(RESTORE_DELAY)
	isLasering = false
	Turn(rarm, x_axis, restorePitch, ARM_SPEED_PITCH)
	Turn(rhand, x_axis, 0, ARM_SPEED_PITCH)
	
	if HAS_GATTLING then
		Spin(barrels, z_axis, 100)
		Sleep(200)
		Turn(barrels, z_axis, 0, ARM_SPEED_PITCH)
	end
end

local function RestoreDGun()
	StartThread(RestoreTorsoAim)
	Signal(SIG_RESTORE_DGUN)
	SetSignalMask(SIG_RESTORE_DGUN)
	Sleep(RESTORE_DELAY)
	isDgunning = false
	Turn(larm, x_axis, 0, ARM_SPEED_PITCH)
	Turn(lnanohand, x_axis, 0, ARM_SPEED_PITCH)
end

function script.AimWeapon(num, heading, pitch)
	local weaponNum = dyncomm.GetWeapon(num)

	if weaponNum == 1 then
		Signal(SIG_LASER)
		SetSignalMask(SIG_LASER)
		isLasering = true
		Turn(rarm, x_axis, math.rad(0) -pitch, ARM_SPEED_PITCH)
		Turn(torso, y_axis, heading, TORSO_SPEED_YAW)
		Turn(rhand, x_axis, math.rad(0), ARM_SPEED_PITCH)
		WaitForTurn(torso, y_axis)
		WaitForTurn(rarm, x_axis)
		StartThread(RestoreLaser)
		return true
	elseif weaponNum == 2 then
		if starBLaunchers[num] then
			pitch = ARM_PERPENDICULAR
		end
		Signal(SIG_DGUN)
		SetSignalMask(SIG_DGUN)
		isDgunning = true
		Turn(larm, x_axis, math.rad(0) -pitch, ARM_SPEED_PITCH)
		Turn(torso, y_axis, heading, TORSO_SPEED_YAW)
		Turn(lnanohand, x_axis, math.rad(0), ARM_SPEED_PITCH)
		WaitForTurn(torso, y_axis)
		WaitForTurn(rarm, x_axis)
		StartThread(RestoreDGun)
		return true
	elseif weaponNum == 3 then
		return true
	end
	return false
end

function script.FireWeapon(num)
	local weaponNum = dyncomm.GetWeapon(num)
	if weaponNum == 1 then
		dyncomm.EmitWeaponFireSfx(rcannon_flare, num)
	elseif weaponNum == 2 then
		dyncomm.EmitWeaponFireSfx(lcannon_flare, num)
	end
end

function script.Shot(num)
	local weaponNum = dyncomm.GetWeapon(num)
	if weaponNum == 1 then
		dyncomm.EmitWeaponShotSfx(rcannon_flare, num)
	elseif weaponNum == 2 then
		dyncomm.EmitWeaponShotSfx(lcannon_flare, num)
	end
end

function script.AimFromWeapon(num)
	if dyncomm.IsManualFire(num) then
		if dyncomm.GetWeapon(num) == 1 then 
			return rcannon_flare
		elseif dyncomm.GetWeapon(num) == 2 then 
			return lcannon_flare
		end
	end
	return pelvis
end

function script.QueryWeapon(num)
	if dyncomm.GetWeapon(num) == 1 then 
		return rcannon_flare
	elseif dyncomm.GetWeapon(num) == 2 then 
		return lcannon_flare
	end
	return pelvis
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	Turn(larm, x_axis, 0, ARM_SPEED_PITCH)
	restoreHeading, restorePitch = 0, 0
	StartThread(RestoreDGun)
end

function script.StartBuilding(heading, pitch)
	restoreHeading, restorePitch = heading, pitch
	Turn(larm, x_axis, math.rad(-30) - pitch, ARM_SPEED_PITCH)
	if not (isDgunning) then Turn(torso, y_axis, heading, TORSO_SPEED_YAW) end
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),lnanoflare)
	return lnanoflare
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(torso, SFX.NONE)
		Explode(larm, SFX.NONE)
		Explode(rarm, SFX.NONE)
		Explode(pelvis, SFX.NONE)
		Explode(lupleg, SFX.NONE)
		Explode(rupleg, SFX.NONE)
		Explode(lnanoflare, SFX.NONE)
		Explode(rhand, SFX.NONE)
		Explode(lleg, SFX.NONE)
		Explode(rleg, SFX.NONE)
		dyncomm.SpawnModuleWrecks(1)
		dyncomm.SpawnWreck(1)
	else
		Explode(torso, SFX.SHATTER)
		Explode(larm, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rarm, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(pelvis, SFX.SHATTER)
		Explode(lupleg, SFX.SHATTER)
		Explode(rupleg, SFX.SHATTER)
		Explode(lnanoflare, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rhand, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lleg, SFX.SHATTER)
		Explode(rleg, SFX.SHATTER)
		dyncomm.SpawnModuleWrecks(2)
		dyncomm.SpawnWreck(2)
	end
end
