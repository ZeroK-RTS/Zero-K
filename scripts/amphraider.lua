--linear constant 65536

include "constants.lua"

local base, pelvis, body, countertilt, aimpoint = piece('base', 'pelvis', 'body', 'countertilt', 'aimpoint')
local rthigh, rshin, rfoot, lthigh, lshin, lfoot = piece('rthigh', 'rshin', 'rfoot', 'lthigh', 'lshin', 'lfoot')
local disks = {
	{piece('f1disk', 'b1disk')},
	{piece('f2disk', 'b2disk')},
	{piece('f3disk', 'b3disk')},
}
local firepoints = {piece('fp1l', 'fp1r', 'fp2l', 'fp2r', 'fp3l', 'fp3r')}

smokePiece = {body}
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local PACE = 2

local THIGH_FRONT_ANGLE = -math.rad(50)
local THIGH_FRONT_SPEED = math.rad(60) * PACE
local THIGH_BACK_ANGLE = math.rad(30)
local THIGH_BACK_SPEED = math.rad(60) * PACE
local SHIN_FRONT_ANGLE = math.rad(45)
local SHIN_FRONT_SPEED = math.rad(90) * PACE
local SHIN_BACK_ANGLE = math.rad(10)
local SHIN_BACK_SPEED = math.rad(90) * PACE

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
		Turn(lshin, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
		Turn(rthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(rshin, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		WaitForTurn(lthigh, x_axis)
		Sleep(0)
		
		--right leg up, left leg back
		Turn(lthigh, x_axis,  THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(lshin, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		Turn(rthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(rshin, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
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
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(5000)
	Turn( body, y_axis, 0, math.rad(65) )
	Turn( pelvis, x_axis, 0, math.rad(47.5) )
	Turn( countertilt, x_axis, 0, math.rad(47.5) )
end

local function ReloadDisks(index)

end

function script.AimFromWeapon()
	return aimpoint
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		Signal(SIG_AIM1)
		SetSignalMask(SIG_AIM1)
		Turn( body, y_axis, heading, math.rad(360) )
		Turn( pelvis, x_axis, -pitch, math.rad(180) )
		Turn( countertilt, x_axis, pitch, math.rad(180) )	
		WaitForTurn(body, y_axis)
		WaitForTurn(pelvis, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	end
end

function script.QueryWeapon(num)
	if num == 1 then
		return firepoints[gun_1]
	end
end

function script.FireWeapon(num)
	if num == 1 then
		local i = 3
		if gun_1 <= 2 then
			i = 1
		elseif gun_1 <= 4 then
			i = 2
		end
		StartThread(ReloadDisks, index)
	end
end

function script.Shot(num)
	if num == 1 then
		gun_1 = gun_1 + 1
		if gun_1 > 6 then gun_1 = 1 end
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity >= .25  then
		Explode(lfoot, sfxNone)
		Explode(lshin, sfxNone)
		Explode(lthigh, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(rfoot, sfxNone)
		Explode(rshin, sfxNone)
		Explode(rthigh, sfxNone)
		Explode(body, sfxNone)
		return 1
	elseif severity >= .50  then
		Explode(lfoot, sfxFall)
		Explode(lshin, sfxFall)
		Explode(lthigh, sfxFall)
		Explode(pelvis, sfxFall)
		Explode(rfoot, sfxFall)
		Explode(rshin, sfxFall)
		Explode(rthigh, sfxFall)
		Explode(body, sfxShatter)
		return 1
	elseif severity >= .99  then
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lshin, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(pelvis, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rshin, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(body, sfxShatter)
		return 2
	else
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lshin, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(pelvis, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rshin, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(body, sfxShatter + sfxExplode )
		return 2
	end
end