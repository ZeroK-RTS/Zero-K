include "constants.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------

local ground = piece 'ground' 
local pelvis = piece 'pelvis' 
local lthigh = piece 'lthigh' 
local llegtwister = piece 'llegtwister' 
local lleg = piece 'lleg' 
local lfoot = piece 'lfoot' 
local rthigh = piece 'rthigh' 
local rlegtwister = piece 'rlegtwister' 
local rleg = piece 'rleg' 
local rfoot = piece 'rfoot' 
local torso = piece 'torso' 
local head = piece 'head' 
local luparm = piece 'luparm' 
local lshaftarm = piece 'lshaftarm' 
local lloarm = piece 'lloarm' 
local ruparm = piece 'ruparm' 
local rshaftarm = piece 'rshaftarm' 
local rloarm = piece 'rloarm' 
local nanospray = piece 'nanospray' 
local turret = piece 'turret' 
local laserblade = piece 'laserblade' 
local jump = piece 'jump' 

local firepoints = {[0] = nanospray, [1] = laserblade}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
local PACE = 3.2

local THIGH_FRONT_ANGLE = -math.rad(50)
local THIGH_FRONT_SPEED = math.rad(60) * PACE
local THIGH_BACK_ANGLE = math.rad(30)
local THIGH_BACK_SPEED = math.rad(60) * PACE
local SHIN_FRONT_ANGLE = math.rad(45)
local SHIN_FRONT_SPEED = math.rad(90) * PACE
local SHIN_BACK_ANGLE = math.rad(10)
local SHIN_BACK_SPEED = math.rad(90) * PACE

local ARM_FRONT_ANGLE = -math.rad(40)
local ARM_FRONT_SPEED = math.rad(40) * PACE
local ARM_BACK_ANGLE = math.rad(30)
local ARM_BACK_SPEED = math.rad(40) * PACE

local FOREARM_FRONT_ANGLE = -math.rad(90)
local FOREARM_FRONT_SPEED = math.rad(20) * PACE
local FOREARM_BACK_ANGLE = -math.rad(70)
local FOREARM_BACK_SPEED = math.rad(20) * PACE

local TORSO_ANGLE_MOTION = math.rad(20)
local TORSO_SPEED_MOTION = math.rad(30)*PACE


local RESTORE_DELAY_LASER = 4000
local RESTORE_DELAY_DGUN = 2500

-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_RESTORE = 4

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local bAiming, bJumping, bReloading = false, false, false
local gun_1 = 0
local lastHeading, lastPitch = 0, 0

--[[
function beginJump()
	EmitSfx(jump, 2048 + 3)
	bJumping = 1
	Turn(luparm, x_axis, math.rad(30), math.rad(400))
	Turn(ruparm, x_axis, math.rad(30), math.rad(400))
	Turn(lthigh, x_axis, math.rad(30), math.rad(400))
	Turn(rthigh, x_axis, math.rad(30), math.rad(400))
	Sleep(1500)
	Turn(luparm, x_axis, math.rad(-90), math.rad(200))
	Turn(ruparm, x_axis, math.rad(-45), math.rad(200))
	Turn(rloarm, x_axis, math.rad(-90), math.rad(200))
	Turn(lthigh, x_axis, math.rad(-30), math.rad(200))
	Turn(lleg, x_axis, math.rad(110), math.rad(200))
	Turn(rthigh, z_axis, math.rad(-(-20)), math.rad(200))
	Turn(rthigh, x_axis, math.rad(-80), math.rad(200))
	Turn(rleg, x_axis, math.rad(-10), math.rad(200))
end

function EndJump()

	bJumping = 0
	Turn(luparm, x_axis, 0, math.rad(400))
	Turn(ruparm, x_axis, 0, math.rad(400))
	Turn(rloarm, x_axis, 0, math.rad(400))
	Turn(lthigh, x_axis, 0, math.rad(400))
	Turn(rthigh, x_axis, 0, math.rad(400))
	Turn(rthigh, z_axis, math.rad(-(0)), math.rad(400))
	Turn(rleg, x_axis, 0, math.rad(400))
	Turn(lleg, x_axis, 0, math.rad(400))
	Turn(ground, x_axis, 0, math.rad(4000))
	EmitSfx(jump, 2048 + 4)
end

JumpSmoke()

	while true do
	
		if bJumping then
		
			Sleep(1500)
		end
		Sleep(33)
	end
end


Bladestat()

	if gun_1 == 1 then
	
	end
	StartThread(Bladestat)
end
]]

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	Turn(ground, x_axis, math.rad(10), math.rad(30))
	while true do
		--left leg up, right leg back
		Turn(lthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(lleg, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
		Turn(rthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(rleg, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		if not(bAiming) then
			--left arm back, right arm front
			Turn(turret, y_axis, TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(luparm, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
			Turn(ruparm, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
			Turn(lloarm, x_axis, FOREARM_BACK_ANGLE, FOREARM_BACK_SPEED)
			Turn(rloarm, x_axis, FOREARM_FRONT_ANGLE, FOREARM_FRONT_SPEED)						
		end
		WaitForTurn(lthigh, x_axis)
		Sleep(0)
		
		--right leg up, left leg back
		Turn(lthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(lleg, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		Turn(rthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(rleg, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
		if not(bAiming) then
			--left arm front, right arm back
			Turn(turret, y_axis, -TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(luparm, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
			Turn(ruparm, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
						Turn(lloarm, x_axis, FOREARM_FRONT_ANGLE, FOREARM_FRONT_SPEED)
			Turn(rloarm, x_axis, FOREARM_BACK_ANGLE, FOREARM_BACK_SPEED)
		end
		WaitForTurn(rthigh, x_axis)		
		Sleep(0)
	end
end

local function RestorePose()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	Turn(ground, x_axis, 0, math.rad(60))
		Turn(turret, y_axis, 0, math.rad(60))
	Move(pelvis, y_axis, 0, 1)
	Turn(rthigh, x_axis, 0, math.rad(200))
	Turn(rleg, x_axis, 0, math.rad(200))
	Turn(lthigh, x_axis, 0, math.rad(200))
	Turn(lleg, x_axis, 0, math.rad(200))
	Turn(luparm, x_axis, 0, math.rad(120))
	Turn(ruparm, x_axis, 0, math.rad(120))
	Turn(lloarm, x_axis, 0, math.rad(120))
	Turn(rloarm, x_axis, 0, math.rad(120))		
end

function script.Create()
	Hide(nanospray)
	Hide(laserblade)
	Move(jump, y_axis, -10, 100)
	StartThread(GG.Script.SmokeUnit, {head})
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(RestorePose)
end

local function RestoreAfterDelay()
		Signal(SIG_RESTORE)
		SetSignalMask(SIG_RESTORE)
		Sleep(6000)
		Turn(luparm, z_axis, 0, math.rad(400))
		Turn(ruparm, z_axis, 0, math.rad(400))
		Turn(luparm, x_axis, 0, math.rad(400))
		Turn(ruparm, x_axis, 0, math.rad(400))
		Turn(luparm, y_axis, 0, math.rad(400))
		Turn(ruparm, y_axis, 0, math.rad(400))
		
		Turn(rloarm, x_axis, 0, math.rad(200))
		Turn(rloarm, y_axis, 0, math.rad(200))
		Turn(rloarm, z_axis, 0, math.rad(200))
		Turn(lloarm, x_axis, 0, math.rad(200))
		Turn(lloarm, y_axis, 0, math.rad(200))
		Turn(lloarm, z_axis, 0, math.rad(200))
		
		Turn(turret, y_axis, 0, math.rad(300))
		Turn(head, y_axis, 0, math.rad(300))
		bAiming = false
end

local function AssumeCombatPosition(heading, pitch)
	Turn(head, y_axis, 0, math.rad(160))
	Turn(turret, y_axis, heading, math.rad(240))
	Turn(luparm, x_axis, -pitch/4, math.rad(240))	
	Turn(lloarm, z_axis, math.rad(30), math.rad(300))
		Turn(lloarm, x_axis, math.rad(-60), math.rad(240))
		
		Turn(ruparm, x_axis, math.rad(-80) + lastPitch, math.rad(240))
	Turn(rloarm, x_axis, math.rad(-90), math.rad(300))
	Turn(rloarm, y_axis, math.rad(80), math.rad(240))
		Turn(rloarm, z_axis, 0, math.rad(300))		
end

function script.AimFromWeapon(num)
		return head
end

function script.QueryWeapon(num)
		return firepoints[gun_1]
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
		while (bReloading) do Sleep(33) end
	bAiming = true
	lastHeading = heading
	lastPitch = pitch
	AssumeCombatPosition(heading, pitch)
	WaitForTurn(turret, y_axis)
	WaitForTurn(ruparm, x_axis)
	WaitForTurn(rloarm, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

local function MuzzleFlash()
	for i=1,3 do
		EmitSfx(nanospray, 1024)
		Sleep(66)
	end
end

function script.FireWeapon(num)
	--gun_1 = 1 - gun_1
	--if gun_1 == 1 then
		--Turn(luparm, z_axis, math.rad(-45), math.rad(450))
		--Turn(luparm, x_axis, math.rad(-lastPitch), math.rad(250))	
		--Turn(lloarm, x_axis, math.rad(-20), math.rad(250))
				bReloading = true
				Turn(ruparm, x_axis, -lastPitch/4, math.rad(700))
				Turn(rloarm, z_axis, math.rad(-30), math.rad(700))		
				Turn(rloarm, x_axis, math.rad(-20), math.rad(700))
				Turn(rloarm, y_axis, 0, math.rad(700))
				Turn(lloarm, z_axis, math.rad(40), math.rad(300))
				
		Turn(turret, y_axis, math.rad(-10) + lastHeading, math.rad(300))
		Turn(head, y_axis, math.rad(10), math.rad(300))
		
				StartThread(MuzzleFlash)				
		Sleep(800)
		AssumeCombatPosition(lastHeading, lastPitch)
				bReloading = false
	--elseif gun_1 == 0 then
	--	Turn(ruparm, z_axis, math.rad(-45), math.rad(450))
	--	Turn(ruparm, x_axis, math.rad(-lastPitch), math.rad(250))	
	--	Turn(rloarm, x_axis, math.rad(-20), math.rad(250))
	--
	--	Turn(luparm, x_axis, math.rad(90), math.rad(700))
	--	Turn(lloarm, x_axis, math.rad(90), math.rad(700))
	--	Turn(lloarm, y_axis, math.rad(-90), math.rad(700))
	--	
	--	Turn(torso, y_axis, math.rad(10), math.rad(300))
	--	Turn(head, y_axis, math.rad(10), math.rad(300))
	--	Sleep(500)
	--	AssumeCombatPosition(lastHeading, lastPitch)
	--end	
	
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .5 then
		return 1
	else
		return 2
	end
end
