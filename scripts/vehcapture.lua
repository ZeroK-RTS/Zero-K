include "constants.lua"

local spGetUnitRulesParam 	= Spring.GetUnitRulesParam

local base, front, bigwheel, rear = piece('base', 'front', 'bigwheel', 'rear')
local turret, arm_1, arm_2, arm_3, dish, panel_a1, panel_b1, panel_a2, panel_b2, flare = piece('turret', 'arm_1', 'arm_2', 'arm_3', 'dish', 'panel_a1', 'panel_b1', 'panel_a2', 'panel_b2', 'flare')
local tracks1, tracks2, tracks3, tracks4 = piece('tracks1', 'tracks2', 'tracks3', 'tracks4')

local wheels_s = { piece('wheels2', 'wheels3') }
local wheels_m = { piece('wheels1', 'wheels4') }
		
local tracks = 1

-- Signal definitions
local SIG_ACTIVATE = 2
local SIG_ANIM = 4
local SIG_AIM = 1
local SIG_IDLE = 8

local WHEEL_SPIN_SPEED_S = math.rad(540)
local WHEEL_SPIN_SPEED_M = math.rad(360)
local WHEEL_SPIN_SPEED_L = math.rad(180)
local WHEEL_SPIN_ACCEL_S = math.rad(15)
local WHEEL_SPIN_ACCEL_M = math.rad(10)
local WHEEL_SPIN_ACCEL_L = math.rad(5)
local WHEEL_SPIN_DECEL_S = math.rad(25)
local WHEEL_SPIN_DECEL_M = math.rad(25)
local WHEEL_SPIN_DECEL_L = math.rad(15)

local DEPLOY_SPEED = math.rad(90)
local TURRET_SPEED = math.rad(60)
local TURRET_ACCEL = math.rad(2)

local ANIM_PERIOD = 66
local PIVOT_MOD = 1.6 --appox. equal to MAX_PIVOT / turnrate
local MAX_PIVOT = math.rad(20)
local MIN_PIVOT = math.rad(-20)
local PIVOT_SPEED = math.rad(60)
local MIN_DIFF = math.rad(0.01)

local smokePiece = {base, turret}

local function ImpactTilt(x,z)
	Turn(base, z_axis, math.rad(-z), math.rad(105))
	Turn(base, x_axis, math.rad(x), math.rad(105))
	WaitForTurn(base, z_axis)
	WaitForTurn(base, x_axis)
	Turn(base, z_axis, 0, math.rad(30))
	Turn(base, x_axis, 0, math.rad(300))
end

--[[
function script.HitByWeapon(x, z)
	StartThread(ImpactTilt, x, z)
end
]]

local function AnimControl() 
	Signal(SIG_ANIM)
	SetSignalMask(SIG_ANIM)
	
	local lastHeading, currHeading, diffHeading, pivotAngle
	lastHeading = GetUnitValue(COB.HEADING)*GG.Script.headingToRad
	while true do
		tracks = tracks + 1
		if tracks == 2 then 
			Hide(tracks1)
			Show(tracks2)
		elseif tracks == 3 then 
			Hide(tracks2)
			Show(tracks3)
		elseif tracks == 4 then 
			Hide(tracks3)
			Show(tracks4)
		else 
			tracks = 1
			Hide(tracks4)
			Show(tracks1)
		end

		for i=1,#wheels_s do
			Spin(wheels_s[i], x_axis, WHEEL_SPIN_SPEED_S, WHEEL_SPIN_ACCEL_S)
		end
		for i=1,#wheels_m do
			Spin(wheels_m[i], x_axis, WHEEL_SPIN_SPEED_M, WHEEL_SPIN_ACCEL_M)
		end

		Spin(bigwheel, x_axis, WHEEL_SPIN_SPEED_L, WHEEL_SPIN_ACCEL_L)
		
		--pivot
		currHeading = GetUnitValue(COB.HEADING)*GG.Script.headingToRad
		diffHeading = (currHeading - lastHeading)
		if (diffHeading > 0 and diffHeading < MIN_DIFF) or (diffHeading < 0 and diffHeading > -MIN_DIFF) then 
			diffHeading = MIN_DIFF -- to prevent segfaulting perfect alignment
		end	
		
		-- Fix wrap location
		if diffHeading > math.pi then
			diffHeading = diffHeading - 2*math.pi
		end
		if diffHeading < -math.pi then
			diffHeading = diffHeading + 2*math.pi
		end
		
		-- Bound maximun pivot
		pivotAngle = diffHeading * PIVOT_MOD
		if pivotAngle > MAX_PIVOT then 
			pivotAngle = MAX_PIVOT 
		end
		if pivotAngle < MIN_PIVOT then 
			pivotAngle = MIN_PIVOT 
		end
		
		-- Turn slowly for small course corrections
		if math.abs(diffHeading) < 0.05 then
			Turn(front, y_axis, pivotAngle, PIVOT_SPEED*0.2)
			Turn(rear, y_axis, (0 - pivotAngle), PIVOT_SPEED*0.2)
		else
			Turn(front, y_axis, pivotAngle, PIVOT_SPEED)
			Turn(rear, y_axis, (0 - pivotAngle), PIVOT_SPEED)
		end
		
		lastHeading = currHeading
		Sleep(ANIM_PERIOD)
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
	Turn(turret, y_axis, heading, math.rad(240))
	--Turn(arm_1, x_axis, math.rad(90) - pitch, math.rad(60))
	--WaitForTurn(arm_1, x_axis)
	WaitForTurn(turret, y_axis)
	StartThread(RestoreAfterDelay)
	return (spGetUnitRulesParam(unitID, "cantfire") == 0)	--checks for max capture
end

function script.AimFromWeapon(num) return flare end
function script.QueryWeapon(num) return flare end

function script.Create()
	StartThread(GG.Script.SmokeUnit, smokePiece)
	Turn(rear, y_axis, 0.01, PIVOT_SPEED)
	while (select(5, Spring.GetUnitHealth(unitID)) < 1) do
		Sleep (1000)
	end
	script.Activate()
end

function script.Activate()
	Signal(SIG_ACTIVATE)
	SetSignalMask(SIG_ACTIVATE)
	Turn(arm_1, x_axis, math.rad(-90), DEPLOY_SPEED)
	WaitForTurn(arm_1, x_axis)
	
	Turn(arm_2, x_axis, math.rad(30), DEPLOY_SPEED)
	Turn(arm_3, x_axis, math.rad(-40), DEPLOY_SPEED)
	WaitForTurn(arm_2, x_axis)
	WaitForTurn(arm_3, x_axis)
	
	Turn(panel_a1, z_axis, math.rad(-(30)), DEPLOY_SPEED)
	Turn(panel_a2, z_axis, math.rad(-(-30)), DEPLOY_SPEED)
	Turn(panel_b1, z_axis, math.rad(-(-30)), DEPLOY_SPEED)
	Turn(panel_b2, z_axis, math.rad(-(30)), DEPLOY_SPEED)
	WaitForTurn(panel_a1, z_axis)
	WaitForTurn(panel_a2, z_axis)
	WaitForTurn(panel_b1, z_axis)
	WaitForTurn(panel_b2, z_axis)
	
	StartThread(IdleAnim)
end

function script.Deactivate()
	Signal(SIG_ACTIVATE)
	SetSignalMask(SIG_ACTIVATE)
	Turn(turret, y_axis, 0, math.rad(TURRET_SPEED))
	WaitForTurn(turret, y_axis)
	
	Turn(panel_a1, z_axis, 0, DEPLOY_SPEED)
	Turn(panel_a2, z_axis, 0, DEPLOY_SPEED)
	Turn(panel_b1, z_axis, 0, DEPLOY_SPEED)
	Turn(panel_b2, z_axis, 0, DEPLOY_SPEED)
	WaitForTurn(panel_a1, z_axis)
	WaitForTurn(panel_a2, z_axis)
	WaitForTurn(panel_b1, z_axis)
	WaitForTurn(panel_b2, z_axis)
	
	Turn(arm_2, x_axis, 0, DEPLOY_SPEED)
	Turn(arm_3, x_axis, 0, DEPLOY_SPEED)
	WaitForTurn(arm_2, x_axis)
	WaitForTurn(arm_3, x_axis)
	
	Turn(arm_1, x_axis, 0, DEPLOY_SPEED)
end

local function Stopping()
	Signal(SIG_ANIM)
	SetSignalMask(SIG_ANIM)
	
	StopSpin(bigwheel, x_axis, WHEEL_SPIN_DECEL_L)
	for i=1,#wheels_s do
		StopSpin(wheels_s[i], x_axis, WHEEL_SPIN_DECEL_M)
	end
	for i=1,#wheels_m do
		StopSpin(wheels_m[i], x_axis, WHEEL_SPIN_DECEL_M)
	end
end

function script.StartMoving() 
	StartThread(AnimControl)
end

function script.StopMoving() 
	StartThread(Stopping)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(front, SFX.NONE)
		Explode(rear, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(front, SFX.NONE)
		Explode(rear, SFX.NONE)
		return 1
	elseif severity <= .99 then
		Explode(front, SFX.SHATTER)
		Explode(rear, SFX.SMOKE + SFX.FIRE)
		return 2
	else
		Explode(front, SFX.SHATTER)
		Explode(rear, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	end
end
