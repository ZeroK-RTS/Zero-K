include "constants.lua"

local base, front, bigwheel, rear = piece('base', 'front', 'bigwheel', 'rear')
local turret, arm_1, arm_2, arm_3, dish, panel_a1, panel_b1, panel_a2, panel_b2 = piece('turret', 'arm_1', 'arm_2', 'arm_3', 'dish', 'panel_a1', 'panel_b1', 'panel_a2', 'panel_b2')
local tracks1, tracks2, tracks3, tracks4, wheels1, wheels2, wheels3, wheels4 = piece('tracks1', 'tracks2', 'tracks3', 'tracks4', 'wheels1', 'wheels2', 'wheels3', 'wheels4')
		
local tracks = 1

-- Signal definitions
local SIG_ACTIVATE = 2
local SIG_MOVE = 4
local SIG_AIM = 1
local SIG_IDLE = 8

local WHEEL_SPIN_SPEED_S = math.rad(540)
local WHEEL_SPIN_SPEED_M = math.rad(360)
local WHEEL_SPIN_SPEED_L = math.rad(180)
local WHEEL_SPIN_ACCEL_S = math.rad(15)
local WHEEL_SPIN_ACCEL_M = math.rad(10)
local WHEEL_SPIN_ACCEL_L = math.rad(5)
local WHEEL_SPIN_DECEL_S = math.rad(45)
local WHEEL_SPIN_DECEL_M = math.rad(30)
local WHEEL_SPIN_DECEL_L = math.rad(15)

local DEPLOY_SPEED = math.rad(90)
local TURRET_SPEED = math.rad(60)
local TURRET_ACCEL = math.rad(2)

local ANIM_PERIOD = 50
local PIVOT_MOD = 11 --appox. equal to MAX_PIVOT / turnrate
local MAX_PIVOT = math.rad(14)
local MIN_PIVOT = math.rad(-14)
local PIVOT_SPEED = math.rad(60)

smokePiece = {base, turret}

local function ImpactTilt(x,z)
	Turn( base , z_axis, math.rad(-z), math.rad(105) )
	Turn( base , x_axis, math.rad(x), math.rad(105) )
	WaitForTurn(base, z_axis)
	WaitForTurn(base, x_axis)
	Turn( base , z_axis, 0, math.rad(30) )
	Turn( base , x_axis, 0, math.rad(300) )
end
function script.HitByWeapon(x, z)
	StartThread(ImpactTilt, x, z)
end

local function AnimControl() 
	local lastHeading, currHeading, diffHeading, pivotAngle
	lastHeading = GetUnitValue(COB.HEADING)
	while true do
		tracks = tracks + 1
		if tracks == 2 then 
			Hide( tracks1)
			Show( tracks2)
		elseif tracks == 3 then 
			Hide( tracks2)
			Show( tracks3)
		elseif tracks == 4 then 
			Hide( tracks3)
			Show( tracks4)
		else 
			tracks = 1
			Hide( tracks4)
			Show( tracks1)
		end
		--pivot
		currHeading = GetUnitValue(COB.HEADING)
		diffHeading = currHeading - lastHeading
		--hexadecimal wtf?
		--if diffHeading > 0x7fff then diffHeading = diffHeading - 0x10000
		--if diffHeading < -0x8000 then diffHeading = diffHeading + 0x10000
		pivotAngle = diffHeading * PIVOT_MOD
		if pivotAngle > MAX_PIVOT then pivotAngle = MAX_PIVOT end
		if pivotAngle < MIN_PIVOT then pivotAngle = MIN_PIVOT end
		Turn( front , y_axis, pivotAngle, PIVOT_SPEED )
		Turn( rear , y_axis, (0 - pivotAngle ),PIVOT_SPEED )
		
		lastHeading = currHeading
		Sleep( ANIM_PERIOD)
	end
end

local function IdleAnim()
	Signal(SIG_IDLE)
	SetSignalMask(SIG_IDLE)
	while true do
		local angle = math.random(0,360)
		Turn(turret, y_axis, math.rad(angle), TURRET_SPEED)
		Sleep(4000)
	end
end

local function RestoreAfterDelay()
	Sleep(7000)
	--Turn(arm_1, x_axis, math.rad(90), math.rad(45))
	StartThread(IdleAnim)
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_IDLE)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(turret, y_axis, heading, math.rad(180))
	--Turn(arm_1, x_axis, math.rad(90) - pitch, math.rad(60))
	--WaitForTurn(arm_1, x_axis)
	WaitForTurn(turret, y_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.AimFromWeapon(num) return dish end
function script.QueryWeapon(num) return dish end

function script.Create()
	StartThread(SmokeUnit)
	script.Activate()
end

function script.Activate()
	Signal( SIG_ACTIVATE)
	SetSignalMask( SIG_ACTIVATE)
	Turn( arm_1 , x_axis, math.rad(-90), DEPLOY_SPEED )
	WaitForTurn(arm_1, x_axis)
	
	Turn( arm_2 , x_axis, math.rad(30), DEPLOY_SPEED  )
	Turn( arm_3 , x_axis, math.rad(-40), DEPLOY_SPEED  )
	WaitForTurn(arm_2, x_axis)
	WaitForTurn(arm_3, x_axis)
	
	Turn( panel_a1 , z_axis, math.rad(-(30)), DEPLOY_SPEED  )
	Turn( panel_a2 , z_axis, math.rad(-(-30)), DEPLOY_SPEED  )
	Turn( panel_b1 , z_axis, math.rad(-(-30)), DEPLOY_SPEED  )
	Turn( panel_b2 , z_axis, math.rad(-(30)), DEPLOY_SPEED  )
	WaitForTurn(panel_a1, z_axis)
	WaitForTurn(panel_a2, z_axis)
	WaitForTurn(panel_b1, z_axis)
	WaitForTurn(panel_b2, z_axis)
	
	StartThread(IdleAnim)
end

function script.Deactivate()
	Signal( SIG_ACTIVATE)
	SetSignalMask( SIG_ACTIVATE)
	Turn( turret , y_axis, math.rad(0 ), math.rad(TURRET_SPEED) )
	WaitForTurn(turret, y_axis)
	
	Turn( panel_a1 , z_axis, math.rad(-(0 )), DEPLOY_SPEED  )
	Turn( panel_a2 , z_axis, math.rad(-(0 )), DEPLOY_SPEED  )
	Turn( panel_b1 , z_axis, math.rad(-(0 )), DEPLOY_SPEED  )
	Turn( panel_b2 , z_axis, math.rad(-(0 )), DEPLOY_SPEED  )
	WaitForTurn(panel_a1, z_axis)
	WaitForTurn(panel_a2, z_axis)
	WaitForTurn(panel_b1, z_axis)
	WaitForTurn(panel_b2, z_axis)
	
	Turn( arm_2 , x_axis, math.rad(0 ), DEPLOY_SPEED )
	Turn( arm_3 , x_axis, math.rad(0 ), DEPLOY_SPEED )
	WaitForTurn(arm_2, x_axis)
	WaitForTurn(arm_3, x_axis)
	
	Turn( arm_1 , x_axis, math.rad(0 ), DEPLOY_SPEED )
end

function script.StartMoving() 
	StartThread(AnimControl)
end

function script.StopMoving() 
	StopSpin(bigwheel, x_axis, WHEEL_SPIN_DECEL_L)

	StopSpin(wheels1, x_axis, WHEEL_SPIN_DECEL_M)
	StopSpin(wheels4, x_axis, WHEEL_SPIN_DECEL_M)
	
	StopSpin(wheels2, x_axis, WHEEL_SPIN_DECEL_S)
	StopSpin(wheels3, x_axis, WHEEL_SPIN_DECEL_S)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(front, sfxNone)
		Explode(rear, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(front, sfxNone)
		Explode(rear, sfxNone)
		return 1
	elseif  severity <= .99  then
		Explode(front, sfxShatter)
		Explode(rear, sfxFall + sfxSmoke + sfxFire)
		return 2
	else
		Explode(front, sfxShatter)
		Explode(rear, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 3
	end
end
