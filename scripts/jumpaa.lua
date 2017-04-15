include "constants.lua"

local base, pelvis, torso, mgturret, aimpoint = piece('base', 'pelvis', 'torso', 'mgturret', 'aimpoint')
local thigh_r, calf_r, foot_r, thigh_l, calf_l, foot_l = piece('thigh_r', 'calf_r', 'foot_r', 'thigh_l', 'calf_l', 'foot_l')
local arm_r, laser_r, laserflare_r, arm_l, laser_l, laserflare_l = piece('arm_r', 'laser_r', 'laserflare_r', 'arm_l', 'laser_l', 'laserflare_l')
local mgpivot, mg_l, mgflare_l, mgeject_l, mg_r, mgflare_r, mgeject_r = piece( 'mgpivot', 'mg_l', 'mgflare_l', 'mgeject_l', 'mg_r', 'mgflare_r', 'mgeject_r')

local aimpoints = { aimpoint, mgpivot }
local firepoints = { {laserflare_l, laserflare_r}, {mgflare_l, mgflare_r} }
local gunIndex = {1, 1}
local eject = { mgeject_l, mgeject_r }

local smokePiece = {torso}
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local PACE = 2

local THIGH_FRONT_ANGLE = math.rad(-50)
local THIGH_FRONT_SPEED = math.rad(60) * PACE
local THIGH_BACK_ANGLE = math.rad(10)
local THIGH_BACK_SPEED = math.rad(60) * PACE
local CALF_RETRACT_ANGLE = math.rad(0)
local CALF_RETRACT_SPEED = math.rad(90) * PACE
local CALF_STRAIGHTEN_ANGLE = math.rad(70)
local CALF_STRAIGHTEN_SPEED = math.rad(90) * PACE
local FOOT_FRONT_ANGLE = -THIGH_FRONT_ANGLE - math.rad(10)
local FOOT_FRONT_SPEED = 2*THIGH_FRONT_SPEED
local FOOT_BACK_ANGLE = -(THIGH_BACK_ANGLE + CALF_STRAIGHTEN_ANGLE)
local FOOT_BACK_SPEED = THIGH_BACK_SPEED + CALF_STRAIGHTEN_SPEED
local BODY_TILT_ANGLE = math.rad(5)
local BODY_TILT_SPEED = math.rad(10)
local BODY_RISE_HEIGHT = 4
local BODY_RISE_SPEED = 6*PACE

local ARM_FRONT_ANGLE = -math.rad(20)
local ARM_FRONT_SPEED = math.rad(22.5) * PACE
local ARM_BACK_ANGLE = math.rad(10)
local ARM_BACK_SPEED = math.rad(22.5) * PACE
local FOREARM_FRONT_ANGLE = -math.rad(40)
local FOREARM_FRONT_SPEED = math.rad(45) * PACE
local FOREARM_BACK_ANGLE = math.rad(10)
local FOREARM_BACK_SPEED = math.rad(45) * PACE

local SIG_WALK = 1
local SIG_AIM1 = 2
local SIG_AIM2 = 4
local SIG_RESTORE = 8

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- jump functions
local bJumping = false

function beginJump() 
	Signal(SIG_WALK)
    --Turn( base, y_axis, 0, turnSpeed)
	bJumping = true
	
	Turn( thigh_l , x_axis, math.rad(-20),math.rad(300) )
	Turn( calf_l , x_axis, math.rad(45), math.rad(400) )	
	Turn( foot_l , x_axis, math.rad(30), math.rad(80) )		

	Turn( thigh_r , x_axis, math.rad(-20),math.rad(300) )
	Turn( calf_r , x_axis, math.rad(45), math.rad(400) )	
	Turn( foot_r , x_axis, math.rad(30), math.rad(80) )	
	
	--StartThread(JumpExhaust)
end

function jumping()
end

function halfJump()
	--Turn( torso, x_axis, math.rad(0), math.rad(80))
	Move( base, y_axis, 0, 18)
	
	Turn( thigh_l , x_axis, math.rad(-30),math.rad(200) )
	Turn( calf_l , x_axis, math.rad(30), math.rad(120) )	
	Turn( foot_l , x_axis, math.rad(-10), math.rad(60) )	
	
	Turn( thigh_l , x_axis, math.rad(-30),math.rad(200) )
	Turn( calf_r , x_axis, math.rad(30), math.rad(120) )	
	Turn( foot_r , x_axis, math.rad(-10), math.rad(60) )	
end

function endJump() 
	bJumping = false
	Turn( thigh_l , x_axis, 0, math.rad(300) )
	Turn( calf_l , x_axis, 0, math.rad(200) )	
	Turn( foot_l , x_axis, 0, math.rad(80) )	
	
	Turn( thigh_l , x_axis, 0, math.rad(300) )
	Turn( calf_r , x_axis, 0, math.rad(200) )	
	Turn( foot_r , x_axis, 0, math.rad(80) )	
end
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- four-stroke bipedal (reverse-jointed) walkscript
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		local speed =  1 - (Spring.GetUnitRulesParam(unitID,"slowState") or 0)
		--straighten left leg and draw it back, raise body, center right leg
		Move(pelvis, y_axis, BODY_RISE_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, BODY_TILT_ANGLE, BODY_TILT_SPEED*speed)
		Turn(thigh_l, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED*speed)
		Turn(calf_l, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
		Turn(foot_l, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED*speed)		
		Turn(thigh_r, x_axis, 0, THIGH_FRONT_SPEED*speed)
		Turn(calf_r, x_axis, 0, CALF_RETRACT_SPEED*speed)
		Turn(foot_r, x_axis, 0, FOOT_FRONT_SPEED*speed)
		WaitForTurn(thigh_l, x_axis)
		Sleep(0)
		
		-- lower body, draw right leg forwards
		Move(pelvis, y_axis, 0, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, 0, BODY_TILT_SPEED*speed)
		--Turn(calf_l, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
		Turn(thigh_r, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED*speed)
		Turn(foot_r, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED*speed)	
		WaitForMove(pelvis, y_axis)
		Sleep(0)
		
		--straighten right leg and draw it back, raise body, center left leg
		Move(pelvis, y_axis, BODY_RISE_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, -BODY_TILT_ANGLE, BODY_TILT_SPEED*speed)
		Turn(thigh_l, x_axis, 0, THIGH_FRONT_SPEED*speed)
		Turn(calf_l, x_axis, 0, CALF_RETRACT_SPEED*speed)
		Turn(foot_l, x_axis, 0, FOOT_FRONT_SPEED*speed)		
		Turn(thigh_r, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED*speed)
		Turn(calf_r, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
		Turn(foot_r, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED*speed)		
		WaitForTurn(thigh_r, x_axis)
		Sleep(0)
		
		-- lower body, draw left leg forwards
		Move(pelvis, y_axis, 0, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, 0, BODY_TILT_SPEED*speed)
		Turn(thigh_l, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED*speed)
		Turn(foot_l, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED*speed)			
		--Turn(calf_r, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
		WaitForMove(pelvis, y_axis)
		Sleep(0)
	end
end

local function Stopping()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Turn( thigh_r , x_axis, 0, math.rad(80)*PACE  )
	Turn( calf_r , x_axis, 0, math.rad(120)*PACE  )
	Turn( foot_r , x_axis, 0, math.rad(80)*PACE  )
	Turn( thigh_l , x_axis, 0, math.rad(80)*PACE  )
	Turn( calf_l , x_axis, 0, math.rad(80)*PACE  )
	Turn( foot_l , x_axis, 0, math.rad(80)*PACE  )
	Turn( pelvis , z_axis, 0, math.rad(20)*PACE  )
	Move( pelvis , y_axis, 0, 12*PACE )
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_START_FLOAT)
	StartThread(Stopping)
	GG.Floating_StopMoving(unitID)
end

function script.Create()
	Turn(mgeject_l, y_axis, math.rad(-90))
	Turn(mgeject_r, y_axis, math.rad(90))
	StartThread(SmokeUnit, smokePiece)	
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(5000)
	Turn( torso, y_axis, 0, math.rad(65) )
	Turn( arm_l, x_axis, 0, math.rad(100) )
	Turn( arm_r, x_axis, 0, math.rad(100) )
	Turn( mgpivot, x_axis, 0, math.rad(120) )
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		Signal(SIG_AIM1)
		SetSignalMask(SIG_AIM1)
		Turn( torso, y_axis, heading, math.rad(480) )
		Turn( arm_l, x_axis, -pitch, math.rad(200) )
		Turn( arm_r, x_axis, -pitch, math.rad(200) )
		WaitForTurn(torso, y_axis)
		WaitForTurn(arm_l, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 2 then
		Signal(SIG_AIM2)
		SetSignalMask(SIG_AIM2)
		Turn( torso, y_axis, heading, math.rad(480) )
		Turn( mgpivot, x_axis, -pitch, math.rad(240) )
		WaitForTurn(torso, y_axis)
		WaitForTurn(mgpivot, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	end
end

function script.AimFromWeapon(num)
	return aimpoints[num]
end

function script.QueryWeapon(num)
	return firepoints[num][gunIndex[num]]
end

function script.Shot(num)
	gunIndex[num] = gunIndex[num] + 1
	if gunIndex[num] > #firepoints[num] then
	    gunIndex[num] = 1
	end
	if num == 2 then
	    EmitSfx(firepoints[2][gunIndex[2]], 1024)
	    EmitSfx(eject[gunIndex[2]], 1025)
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(foot_l, sfxNone)
		Explode(calf_l, sfxNone)
		Explode(thigh_l, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(foot_r, sfxNone)
		Explode(calf_r, sfxNone)
		Explode(thigh_r, sfxNone)
		Explode(torso, sfxNone)
		return 1
	elseif severity <= .50  then
		Explode(foot_l, sfxFall)
		Explode(calf_l, sfxFall)
		Explode(thigh_l, sfxFall)
		Explode(pelvis, sfxFall)
		Explode(foot_r, sfxFall)
		Explode(calf_r, sfxFall)
		Explode(thigh_r, sfxFall)
		Explode(torso, sfxShatter)
		return 1
	elseif severity <= .99  then
		Explode(foot_l, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(calf_l, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(thigh_l, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(pelvis, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(foot_r, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(calf_r, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(thigh_r, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(torso, sfxShatter)
		return 2
	else
		Explode(foot_l, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(calf_l, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(thigh_l, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(pelvis, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(foot_r, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(calf_r, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(thigh_r, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(torso, sfxShatter + sfxExplode )
		return 2
	end
end