--linear constant 65536

include "constants.lua"

local base, pelvis, body = piece('base', 'pelvis', 'body')
local rthigh, rshin, rfoot, lthigh, lshin, lfoot = piece('rthigh', 'rshin', 'rfoot', 'lthigh', 'lshin', 'lfoot')
local holder, sphere = piece('holder', 'sphere') 

smokePiece = {pelvis}
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local PACE = 1.5

local THIGH_FRONT_ANGLE = math.rad(-50)
local THIGH_FRONT_SPEED = math.rad(60) * PACE
local THIGH_BACK_ANGLE = math.rad(10)
local THIGH_BACK_SPEED = math.rad(60) * PACE
local CALF_RETRACT_ANGLE = math.rad(0)
local CALF_RETRACT_SPEED = math.rad(90) * PACE
local CALF_STRAIGHTEN_ANGLE = math.rad(70)
local CALF_STRAIGHTEN_SPEED = math.rad(90) * PACE
local FOOT_FRONT_ANGLE = -THIGH_FRONT_ANGLE - math.rad(20)
local FOOT_FRONT_SPEED = 2*THIGH_FRONT_SPEED
local FOOT_BACK_ANGLE = -(THIGH_BACK_ANGLE + CALF_STRAIGHTEN_ANGLE)
local FOOT_BACK_SPEED = THIGH_BACK_SPEED + CALF_STRAIGHTEN_SPEED
local BODY_TILT_ANGLE = math.rad(5)
local BODY_TILT_SPEED = math.rad(10)
local BODY_RISE_HEIGHT = 4
local BODY_LOWER_HEIGHT = 2
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
		Turn(lthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED*speed)
		Turn(lshin, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
		Turn(lfoot, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED*speed)		
		Turn(rthigh, x_axis, 0, THIGH_FRONT_SPEED*speed)
		Turn(rshin, x_axis, 0, CALF_RETRACT_SPEED*speed)
		Turn(rfoot, x_axis, 0, FOOT_FRONT_SPEED*speed)
		WaitForTurn(lthigh, x_axis)
		Sleep(0)
		
		-- lower body, draw right leg forwards
		Move(pelvis, y_axis, BODY_LOWER_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, 0, BODY_TILT_SPEED*speed)
		--Turn(lshin, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
		Turn(rthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED*speed)
		Turn(rfoot, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED*speed)	
		WaitForMove(pelvis, y_axis)
		Sleep(0)
		
		--straighten right leg and draw it back, raise body, center left leg
		Move(pelvis, y_axis, BODY_RISE_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, -BODY_TILT_ANGLE, BODY_TILT_SPEED*speed)
		Turn(lthigh, x_axis, 0, THIGH_FRONT_SPEED*speed)
		Turn(lshin, x_axis, 0, CALF_RETRACT_SPEED*speed)
		Turn(lfoot, x_axis, 0, FOOT_FRONT_SPEED*speed)		
		Turn(rthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED*speed)
		Turn(rshin, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
		Turn(rfoot, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED*speed)		
		WaitForTurn(rthigh, x_axis)
		Sleep(0)
		
		-- lower body, draw left leg forwards
		Move(pelvis, y_axis, BODY_LOWER_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, 0, BODY_TILT_SPEED*speed)
		Turn(lthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED*speed)
		Turn(lfoot, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED*speed)			
		--Turn(rshin, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
		WaitForMove(pelvis, y_axis)
		Sleep(0)
	end
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_WALK)
	Turn( rthigh , x_axis, 0, math.rad(80)*PACE  )
	Turn( rshin , x_axis, 0, math.rad(120)*PACE  )
	Turn( rfoot , x_axis, 0, math.rad(80)*PACE  )
	Turn( lthigh , x_axis, 0, math.rad(80)*PACE  )
	Turn( lshin , x_axis, 0, math.rad(80)*PACE  )
	Turn( lfoot , x_axis, 0, math.rad(80)*PACE  )
	Turn( pelvis , z_axis, 0, math.rad(20)*PACE  )
	Move( pelvis , y_axis, 0, 12*PACE )
end

function script.Create()
	StartThread(SmokeUnit)
        --StartThread(Walk)
        Spin(holder, z_axis, math.rad(math.random(-90,90)) )
        Spin(sphere, x_axis, math.rad(math.random(-150,150)))
        Spin(sphere, y_axis, math.rad(math.random(-150,150)))
        Spin(sphere, z_axis, math.rad(math.random(-150,150)))
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
    if severity <= 50 then
		Explode(lfoot, sfxNone)
		Explode(lshin, sfxNone)
		Explode(lthigh, sfxNone)
		Explode(rfoot, sfxNone)
		Explode(rshin, sfxNone)
		Explode(rthigh, sfxNone)
		Explode(body, sfxNone)
		return 1
	elseif severity <= 99 then
		Explode(lfoot, sfxFall)
		Explode(lshin, sfxFall)
		Explode(lthigh, sfxFall)
		Explode(rfoot, sfxFall)
		Explode(rshin, sfxFall)
		Explode(rthigh, sfxFall)
		Explode(body, sfxShatter)
		return 2
	else
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lshin, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rshin, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(body, sfxShatter + sfxExplode )
		return 2
	end
end