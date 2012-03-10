--linear constant 65536

include "constants.lua"

local base, head, body, barrel, firepoint = piece('base', 'head', 'body', 'barrel', 'firepoint')
local rthigh, rshin, rfoot, lthigh, lshin, lfoot = piece('rthigh', 'rshin', 'rfoot', 'lthigh', 'lshin', 'lfoot')
local vent1, vent2, vent3 = piece('vent1', 'vent2', 'vent3')

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
local SIG_BOB = 16
local SIG_FLOAT = 32

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Swim functions

local function Bob()
	Signal(SIG_BOB)
	SetSignalMask(SIG_BOB)
	while true do
		Turn(base, x_axis, math.rad(math.random(-3,3)), math.rad(math.random(1,2)) )
		Turn(base, z_axis, math.rad(math.random(-3,3)), math.rad(math.random(1,2)) )
		Move(base, y_axis, math.rad(math.random(0,6)), math.rad(math.random(2,6)) )
		Sleep(2000)
		Turn(base, x_axis, math.rad(math.random(-3,3)), math.rad(math.random(1,2)) )
		Turn(base, z_axis, math.rad(math.random(-3,3)), math.rad(math.random(1,2)) )
		Move(base, y_axis, math.rad(math.random(-6,0)), math.rad(math.random(2,6)) )
		Sleep(2000)
	end
end

local function SinkBubbles()
    SetSignalMask(SIG_FLOAT)
    while true do
        EmitSfx(vent1, SFX.BUBBLE)
        EmitSfx(vent2, SFX.BUBBLE)
        EmitSfx(vent3, SFX.BUBBLE)
        Sleep(66)
    end
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Swim gadget callins

function Float_startFromFloor()
	Signal(SIG_WALK)
    Signal(SIG_FLOAT)
	StartThread(Bob)
end

function Float_stopOnFloor()
	Signal(SIG_BOB)
    Signal(SIG_FLOAT)
end

function Float_rising()
     Signal(SIG_FLOAT)
end

function Float_sinking()
    Signal(SIG_FLOAT)
    StartThread(SinkBubbles)
end

function Float_crossWaterline(speed)
    --Signal(SIG_FLOAT)
end

function Float_stationaryOnSurface()
     Signal(SIG_FLOAT)
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local gun_1 = 1
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Turn(base, x_axis, 0, math.rad(20))
	Turn(base, z_axis, 0, math.rad(20))
	Move(base, y_axis, 0, 10)
	
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
	GG.Floating_StopMoving(unitID)
end

function script.Create()
	StartThread(SmokeUnit)	
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(5000)
	Turn( head, y_axis, 0, math.rad(65) )
	Turn( barrel, x_axis, 0, math.rad(65) )
end

function script.AimFromWeapon()
	return barrel
end

function script.AimWeapon(num, heading, pitch)
	GG.Floating_AimWeapon(unitID)
	
	if num == 1 then
		Signal(SIG_AIM1)
		SetSignalMask(SIG_AIM1)
		Turn( head, y_axis, heading, math.rad(360) )
		Turn( barrel, x_axis, -pitch, math.rad(180) )
		WaitForTurn(head, y_axis)
		WaitForTurn(barrel, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	end
end

function script.QueryWeapon(num)
	if num == 1 then
		return firepoint
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity >= .25  then
		Explode(lfoot, sfxNone)
		Explode(lshin, sfxNone)
		Explode(lthigh, sfxNone)
		Explode(rfoot, sfxNone)
		Explode(rshin, sfxNone)
		Explode(rthigh, sfxNone)
		Explode(body, sfxNone)
		return 1
	elseif severity >= .50  then
		Explode(lfoot, sfxFall)
		Explode(lshin, sfxFall)
		Explode(lthigh, sfxFall)
		Explode(rfoot, sfxFall)
		Explode(rshin, sfxFall)
		Explode(rthigh, sfxFall)
		Explode(body, sfxShatter)
		return 1
	elseif severity >= .99  then
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lshin, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rshin, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
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