include "constants.lua"

dyncomm = include('dynamicCommander.lua')

local AntennaTip = piece('AntennaTip')
local ArmLeft = piece('ArmLeft')
local ArmRight = piece('ArmRight')
local AssLeft = piece('AssLeft')
local AssRight = piece('AssRight')
local Breast = piece('Breast')
local CalfLeft = piece('CalfLeft')
local CalfRight = piece('CalfRight')
local FingerA = piece('FingerA')
local FingerB = piece('FingerB')
local FingerC = piece('FingerC')
local FootLeft = piece('FootLeft')
local FootRight = piece('FootRight')
local Gun = piece('Gun')
local HandRight = piece('HandRight')
local Head = piece('Head')
local HipLeft = piece('HipLeft')
local HipRight = piece('HipRight')
local Muzzle = piece('Muzzle')
local Palm = piece('Palm')
local Stomach = piece('Stomach')
local Base = piece('Base')
local Nano = piece('Nano')
local UnderGun = piece('UnderGun')
local UnderMuzzle = piece('UnderMuzzle')
local Eye = piece('Eye')
local Shield = piece('Shield')
local FingerTipA = piece('FingerTipA')
local FingerTipB = piece('FingerTipB')
local FingerTipC = piece('FingerTipC')

local TORSO_SPEED_YAW = math.rad(300)
local ARM_SPEED_PITCH = math.rad(180)

local smokePiece = {Breast, Head}
local nanoPieces = {Nano}
local nanoing = false
local aiming = false

local FINGER_ANGLE_IN = math.rad(10)
local FINGER_ANGLE_OUT = math.rad(-25)
local FINGER_SPEED = math.rad(60)

local SIG_RIGHT = 1
local SIG_RESTORE_RIGHT = 2
local SIG_LEFT = 4
local SIG_RESTORE_LEFT = 8
local SIG_RESTORE_TORSO = 16
local SIG_WALK = 32
local SIG_NANO = 64

local RESTORE_DELAY = 2500

---------------------------------------------------------------------
---------------------------------------------------------------------
-- Walking

local PACE = 3.6
local BASE_VELOCITY = UnitDefNames.benzcom1.speed or 1.25*30
local VELOCITY = UnitDefs[unitDefID].speed or BASE_VELOCITY
local PACE = PACE * VELOCITY/BASE_VELOCITY

local walkCycle = 1 -- Alternate between 1 and 2

local walkAngle = {
	{ -- Moving forwards
		wait = HipLeft,
		{
			hip = {math.rad(-12), math.rad(40) * PACE},
			leg = {math.rad(80), math.rad(100) * PACE},
			foot = {math.rad(15), math.rad(150) * PACE},
			arm = {math.rad(5), math.rad(20) * PACE},
			hand = {math.rad(0), math.rad(20) * PACE},
		},
		{
			hip = {math.rad(-32), math.rad(30) * PACE},
			leg = {math.rad(16), math.rad(90) * PACE},
			foot = {math.rad(-30), math.rad(160) * PACE},
		},
	},
	{ -- Moving backwards
		wait = HipRight,
		{
			hip = {math.rad(8), math.rad(35) * PACE},
			leg = {math.rad(2), math.rad(50) * PACE},
			foot = {math.rad(10), math.rad(40) * PACE},
			arm = {math.rad(-20), math.rad(20) * PACE},
			hand = {math.rad(-25), math.rad(20) * PACE},
		},
		{
			hip = {math.rad(20), math.rad(35) * PACE},
			leg = {math.rad(15), math.rad(25) * PACE},
			foot = {math.rad(60), math.rad(30) * PACE},
		}
		
	},
}

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	local speedMult = 1
	
	while true do
		walkCycle = 3 - walkCycle
		speedMult = (Spring.GetUnitRulesParam(unitID,"totalMoveSpeedChange") or 1)*dyncomm.GetPace()
		
		local left = walkAngle[walkCycle] 
		local right = walkAngle[3 - walkCycle] 
		-----------------------------------------------------------------------------------
		
		Turn(HipLeft, x_axis,  left[1].hip[1],  left[1].hip[2] * speedMult)
		Turn(CalfLeft, x_axis, left[1].leg[1],  left[1].leg[2] * speedMult)
		Turn(FootLeft, x_axis, left[1].foot[1], left[1].foot[2] * speedMult)
		
		Turn(HipRight, x_axis,  right[1].hip[1],  right[1].hip[2] * speedMult)
		Turn(CalfRight, x_axis, right[1].leg[1],  right[1].leg[2] * speedMult)
		Turn(FootRight, x_axis,  right[1].foot[1], right[1].foot[2] * speedMult)
		
		if not aiming then
			Turn(ArmLeft, x_axis, left[1].arm[1],  left[1].arm[2] * speedMult)
			Turn(Gun, x_axis, left[1].hand[1], left[1].hand[2] * speedMult)
			
			Turn(ArmRight, x_axis, right[1].arm[1],  right[1].arm[2] * speedMult)
			Turn(HandRight, x_axis, right[1].hand[1], right[1].hand[2] * speedMult)
		end
		
		Move(Base, z_axis, 1, 2 * speedMult)
		
		WaitForTurn(left.wait, x_axis)
		-----------------------------------------------------------------------------------
		
		Turn(HipLeft, x_axis,  left[2].hip[1],  left[2].hip[2] * speedMult)
		Turn(CalfLeft, x_axis, left[2].leg[1],  left[2].leg[2] * speedMult)
		Turn(FootLeft, x_axis, left[2].foot[1], left[2].foot[2] * speedMult)
		
		Turn(HipRight, x_axis,  right[2].hip[1],  right[2].hip[2] * speedMult)
		Turn(CalfRight, x_axis, right[2].leg[1],  right[2].leg[2] * speedMult)
		Turn(FootRight, x_axis,  right[2].foot[1], right[2].foot[2] * speedMult)
		
		if not aiming then
			Turn(Stomach, z_axis, -0.3*(walkCycle - 1.5), speedMult)
		end
		
		Move(Base, z_axis, 0, 2 * speedMult)
		
		WaitForTurn(left.wait, x_axis)
	end
end

local function RestoreLegs()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Turn(HipLeft,  x_axis, 0, 1)
	Turn(CalfLeft, x_axis, 0, 3)
	Turn(FootLeft, x_axis, 0, 2.5)
	
	Turn(HipRight,  x_axis, 0, 1)
	Turn(CalfRight, x_axis, 0, 3)
	Turn(FootRight, x_axis, 0, 2.5)
	
	if not aiming then
		Turn(ArmLeft, x_axis, 0, 2)
		Turn(Gun, x_axis, 0, 2)
		
		Turn(ArmRight, x_axis, 0, 2)
		Turn(HandRight, x_axis, 0, 2)
	
		Turn(Stomach, z_axis, 0, 1)
	end
	Move(Base, z_axis, 0, 4)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(RestoreLegs)
end

---------------------------------------------------------------------
---------------------------------------------------------------------
-- Aiming and Firing

function script.AimFromWeapon(num)
	if dyncomm.IsManualFire(num) then
		if dyncomm.GetWeapon(num) == 1 then 
			return Palm
		elseif dyncomm.GetWeapon(num) == 2 then 
			return UnderMuzzle
		end
	end
	return Shield
end

function script.QueryWeapon(num)
	if dyncomm.GetWeapon(num) == 1 then 
		return Muzzle
	elseif dyncomm.GetWeapon(num) == 2 then 
		return UnderMuzzle
	end
	return Shield
end

local function RestoreTorsoAim(sleepTime)
	Signal(SIG_RESTORE_TORSO)
	SetSignalMask(SIG_RESTORE_TORSO)
	Sleep(sleepTime or RESTORE_DELAY)
	if not nanoing then
		Turn(Stomach, z_axis, 0, TORSO_SPEED_YAW)
		aiming = false
	end
end

local function RestoreRightAim(sleepTime)
	StartThread(RestoreTorsoAim, sleepTime)
	Signal(SIG_RESTORE_RIGHT)
	SetSignalMask(SIG_RESTORE_RIGHT)
	Sleep(sleepTime or RESTORE_DELAY)
	if not nanoing then
		Turn(ArmRight, x_axis, 0, ARM_SPEED_PITCH)
		Turn(HandRight, x_axis, 0, ARM_SPEED_PITCH)
	end
end

local function RestoreLeftAim(sleepTime)
	StartThread(RestoreTorsoAim, sleepTime)
	Signal(SIG_RESTORE_LEFT)
	SetSignalMask(SIG_RESTORE_LEFT)
	Sleep(sleepTime or RESTORE_DELAY)
	Turn(ArmLeft, x_axis, 0, ARM_SPEED_PITCH)
	Turn(Gun, x_axis, 0, ARM_SPEED_PITCH)
end

local function AimArm(heading, pitch, arm, hand, wait)
	aiming = true
	Turn(arm, x_axis, -pitch/2 - 0.7, ARM_SPEED_PITCH)
	Turn(Stomach, z_axis, heading, TORSO_SPEED_YAW)
	Turn(hand, x_axis, -pitch/2 - 0.85, ARM_SPEED_PITCH)
	if wait then
		WaitForTurn(Stomach, y_axis)
		WaitForTurn(arm, x_axis)
	end
end

function script.AimWeapon(num, heading, pitch)
	local weaponNum = dyncomm.GetWeapon(num)
	
	if weaponNum == 1 then
		Signal(SIG_LEFT)
		SetSignalMask(SIG_LEFT)
		Signal(SIG_RESTORE_LEFT)
		Signal(SIG_RESTORE_TORSO)
		AimArm(heading, pitch, ArmLeft, Gun, true)
		StartThread(RestoreLeftAim)
		return true
	elseif weaponNum == 2 then
		Signal(SIG_RIGHT)
		SetSignalMask(SIG_RIGHT)
		Signal(SIG_RESTORE_RIGHT)
		Signal(SIG_RESTORE_TORSO)
		AimArm(heading, pitch, ArmRight, HandRight, true)
		StartThread(RestoreRightAim)
		return true
	end
	return (weaponNum and true) or false
end

function script.FireWeapon(num)
	local weaponNum = dyncomm.GetWeapon(num)
	if weaponNum == 1 then
		dyncomm.EmitWeaponFireSfx(Muzzle, num)
	elseif weaponNum == 2 then
		dyncomm.EmitWeaponFireSfx(UnderMuzzle, num)
	end
end

function script.Shot(num)
	local weaponNum = dyncomm.GetWeapon(num)
	if weaponNum == 1 then
		dyncomm.EmitWeaponShotSfx(Muzzle, num)
	elseif weaponNum == 2 then
		dyncomm.EmitWeaponShotSfx(UnderMuzzle, num)
	end
end

local function NanoAnimation()
	Signal(SIG_NANO)
	SetSignalMask(SIG_NANO)
	while true do
		Turn(FingerA, x_axis, FINGER_ANGLE_OUT, FINGER_SPEED)
		Sleep(200)
		Turn(FingerB, x_axis, FINGER_ANGLE_IN, FINGER_SPEED)
		Sleep(200)
		Turn(FingerC, x_axis, FINGER_ANGLE_OUT, FINGER_SPEED)
		Sleep(200)
		Turn(FingerA, x_axis, FINGER_ANGLE_IN, FINGER_SPEED)
		Sleep(200)
		Turn(FingerB, x_axis, FINGER_ANGLE_OUT, FINGER_SPEED)
		Sleep(200)
		Turn(FingerC, x_axis, FINGER_ANGLE_IN, FINGER_SPEED)
		Sleep(200)
	end
end

local function NanoRestore()
	Signal(SIG_NANO)
	SetSignalMask(SIG_NANO)
	Sleep(500)
	Turn(FingerA, x_axis, 0, FINGER_SPEED)
	Turn(FingerB, x_axis, 0, FINGER_SPEED)
	Turn(FingerC, x_axis, 0, FINGER_SPEED)
end
	
function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	StartThread(RestoreRightAim, 200)
	StartThread(NanoRestore)
	nanoing = false
end

function script.StartBuilding(heading, pitch)
	AimArm(heading, pitch, ArmRight, HandRight, false)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	StartThread(NanoAnimation)
	nanoing = true
end

---------------------------------------------------------------------
---------------------------------------------------------------------
-- Creation and Death

function script.Create()
	dyncomm.Create()
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	StartThread(SmokeUnit, smokePiece)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 or true then
		
		dyncomm.SpawnModuleWrecks(1)
		dyncomm.SpawnWreck(1)
	else
		
		dyncomm.SpawnModuleWrecks(2)
		dyncomm.SpawnWreck(2)
	end
end