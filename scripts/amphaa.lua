--linear constant 65536

include "constants.lua"

local base, pelvis, torso, aimpoint = piece('base', 'pelvis', 'torso')
local rthigh, rcalf, rfoot, lthigh, lcalf, lfoot = piece('rthigh', 'rcalf', 'rfoot', 'lthigh', 'lcalf', 'lfoot')
local lgun, lbarrel1, lbarrel2, rgun, rbarrel1, rbarrel2 = piece('lgun', 'lbarrel1', 'lbarrel2', 'rgun', 'rbarrel1', 'rbarrel2')

local firepoints = {lbarrel1, rbarrel1, lbarrel2, rbarrel2}

smokePiece = {torso}
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local PACE = 2

local THIGH_FRONT_ANGLE = -math.rad(50)
local THIGH_FRONT_SPEED = math.rad(60) * PACE
local THIGH_BACK_ANGLE = math.rad(30)
local THIGH_BACK_SPEED = math.rad(60) * PACE
local calf_FRONT_ANGLE = math.rad(45)
local calf_FRONT_SPEED = math.rad(90) * PACE
local calf_BACK_ANGLE = math.rad(10)
local calf_BACK_SPEED = math.rad(90) * PACE

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
local gun_1 = 1
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		--left leg up, right leg back
		Turn(lthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(lcalf, x_axis, calf_FRONT_ANGLE, calf_FRONT_SPEED)
		Turn(rthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(rcalf, x_axis, calf_BACK_ANGLE, calf_BACK_SPEED)
		WaitForTurn(lthigh, x_axis)
		Sleep(0)
		
		--right leg up, left leg back
		Turn(lthigh, x_axis,  THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(lcalf, x_axis, calf_BACK_ANGLE, calf_BACK_SPEED)
		Turn(rthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(rcalf, x_axis, calf_FRONT_ANGLE, calf_FRONT_SPEED)
		WaitForTurn(rthigh, x_axis)		
		Sleep(0)
	end
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_WALK)
	Turn( rthigh , x_axis, 0, math.rad(80)*PACE  )
	Turn( rcalf , x_axis, 0, math.rad(120)*PACE  )
	Turn( rfoot , x_axis, 0, math.rad(80)*PACE  )
	Turn( lthigh , x_axis, 0, math.rad(80)*PACE  )
	Turn( lcalf , x_axis, 0, math.rad(80)*PACE  )
	Turn( lfoot , x_axis, 0, math.rad(80)*PACE  )
	Turn( pelvis , z_axis, 0, math.rad(20)*PACE  )
	Move( pelvis , y_axis, 0, 12*PACE )
end

function script.Create()
	StartThread(SmokeUnit)	
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(5000)
	Turn( torso, y_axis, 0, math.rad(65) )
	Turn( lgun, x_axis, 0, math.rad(47.5) )
        Turn( rgun, x_axis, 0, math.rad(47.5) )
end


function script.AimFromWeapon()
	return torso
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM1)
	SetSignalMask(SIG_AIM1)
	Turn( torso, y_axis, heading, math.rad(360) )
	Turn( lgun, x_axis, -pitch, math.rad(180) )
	Turn( rgun, x_axis, -pitch, math.rad(180) )
	WaitForTurn(torso, y_axis)
	WaitForTurn(lgun, x_axis)
        WaitForTurn(rgun, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.QueryWeapon(num)
    return firepoints[gun_1]
end

function script.FireWeapon(num)
end

function script.Shot(num)
        EmitSfx(firepoints[gun_1], 1024)
	if num == 1 then
		gun_1 = gun_1 + 1
		if gun_1 > 4 then gun_1 = 1 end
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity >= .25  then
		Explode(lfoot, sfxNone)
		Explode(lcalf, sfxNone)
		Explode(lthigh, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(rfoot, sfxNone)
		Explode(rcalf, sfxNone)
		Explode(rthigh, sfxNone)
		Explode(torso, sfxNone)
		return 1
	elseif severity >= .50  then
		Explode(lfoot, sfxFall)
		Explode(lcalf, sfxFall)
		Explode(lthigh, sfxFall)
		Explode(pelvis, sfxFall)
		Explode(rfoot, sfxFall)
		Explode(rcalf, sfxFall)
		Explode(rthigh, sfxFall)
		Explode(torso, sfxShatter)
		return 1
	elseif severity >= .99  then
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lcalf, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(pelvis, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rcalf, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(torso, sfxShatter)
		return 2
	else
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lcalf, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(pelvis, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rcalf, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(torso, sfxShatter + sfxExplode )
		return 2
	end
end