local base = piece 'base' 
local chest = piece 'chest' 
local aim = piece 'aim' 
local flare = piece 'flare' 
local hips = piece 'hips' 
local lthigh = piece 'lthigh' 
local rthigh = piece 'rthigh' 
local lforearm = piece 'lforearm' 
local rforearm = piece 'rforearm' 
local rshoulder = piece 'rshoulder' 
local lshoulder = piece 'lshoulder' 
local rshin = piece 'rshin' 
local rfoot = piece 'rfoot' 
local lshin = piece 'lshin' 
local lfoot = piece 'lfoot' 
--linear constant=65536

include "constants.lua"

local smokePiece = {chest}

local aiming = false
local walking = false

-- Signal definitions
local SIG_MOVE = 1
local SIG_RESTORE = 2
local SIG_AIM = 4
local SIG_STOPMOVE = 8

local RESTORE_DELAY = 3000

local runspeed = 1.9
local hangtime = 32
local steptime = 10
local stride_top = -0.5
local stride_bottom = -2.75


local function walk()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)

	local speedmod = 1
	local truespeed = runspeed
	while true do
		speedmod = (Spring.GetUnitRulesParam(unitID, "totalMoveSpeedChange") or 1)
                truespeed = runspeed * speedmod
		Turn(hips, z_axis, 0.08, truespeed*0.15)

		Turn(rthigh, x_axis, -0.65, truespeed*1.25)
		Turn(rshin, x_axis, 0.8, truespeed*1.25)
		Turn(rfoot, x_axis, 0, truespeed*0.5)

		Turn(lshin, x_axis, 0.4, truespeed*0.5)
		Turn(lthigh, x_axis, 0.5, truespeed*1.25)
		Turn(lfoot, x_axis, -0.3, truespeed*1)

		Move(hips, y_axis, stride_top, truespeed*4)

		if not aiming then
			Move(chest, y_axis, -0.15, truespeed*1)
			Turn(chest, x_axis, -0.08, truespeed*0.25)
			Turn(chest, y_axis, -0.065, truespeed*0.25)
		end

		WaitForMove(hips, y_axis)

		Move(hips, y_axis, stride_bottom, truespeed*1)

		Sleep(hangtime)

		Move(hips, y_axis, stride_bottom, truespeed*4)
		Turn(rshin, x_axis, 0.0, truespeed*0.75)
		Turn(rfoot, x_axis, -0.2, truespeed*0.5)
		Turn(lshin, x_axis, 0.6, truespeed*0.75)
		Turn(lfoot, x_axis, -0.0, truespeed*1.25)

		if not aiming then
			Move(chest, y_axis, 0, truespeed*1)
			Turn(chest, x_axis, 0, truespeed*0.25)
			Turn(chest, y_axis, 0, truespeed*0.25)
		end

		WaitForTurn(rthigh, x_axis)

		Sleep(steptime)

		speedmod = (Spring.GetUnitRulesParam(unitID, "totalMoveSpeedChange") or 1)
                truespeed = runspeed * speedmod
		Turn(hips, z_axis, -0.08, truespeed*0.15)

		Turn(lthigh, x_axis, -0.65, truespeed*1.25)
		Turn(lshin, x_axis, 0.8, truespeed*1.25)
		Turn(lfoot, x_axis, 0, truespeed*0.5)

		Turn(rshin, x_axis, 0.4, truespeed*0.5)
		Turn(rthigh, x_axis, 0.5, truespeed*1.25)
		Turn(rfoot, x_axis, -0.3, truespeed*1)

		Move(hips, y_axis, stride_top, truespeed*4)

		if not aiming then
			Move(chest, y_axis, -0.15, truespeed*1)
			Turn(chest, x_axis, -0.08, truespeed*0.25)
			Turn(chest, y_axis, 0.065, truespeed*0.25)
		end

		WaitForMove(hips, y_axis)

		Move(hips, y_axis, stride_bottom, truespeed*1)

		Sleep(hangtime)

		Move(hips, y_axis, stride_bottom, truespeed*4)
		Turn(lshin, x_axis, 0.0, truespeed*0.75)
		Turn(lfoot, x_axis, -0.2, truespeed*0.5)
		Turn(rshin, x_axis, 0.6, truespeed*0.75)
		Turn(rfoot, x_axis, -0.0, truespeed*1.25)

		if not aiming then
			Move(chest, y_axis, 0, truespeed*1)
			Turn(chest, x_axis, 0, truespeed*0.25)
			Turn(chest, y_axis, 0, truespeed*0.25)
		end

		WaitForTurn(lthigh, x_axis)

		Sleep(steptime)
	end
end

function script.Create()
	StartThread(SmokeUnit, smokePiece)
end

function script.StartMoving()
	Signal(SIG_STOPMOVE)
	if walking == false then

		walking = true
		StartThread(walk)
	end
end

local function StopMovingThread()
	
	Signal(SIG_STOPMOVE)
	SetSignalMask(SIG_STOPMOVE)
	Sleep(33)
	
	walking = false
	Signal(SIG_MOVE)

	Turn(hips, z_axis, 0, math.rad(60.0))
	Move(hips, y_axis, 0, 8.0)
	Turn(rthigh, x_axis, 0, math.rad(120.000000))
	Turn(rshin, x_axis, 0, math.rad(240.000000))
	Turn(rfoot, x_axis, 0, math.rad(120.000000))
	Turn(lthigh, x_axis, 0, math.rad(120.000000))
	Turn(lshin, x_axis, 0, math.rad(240.000000))
	Turn(lfoot, x_axis, 0, math.rad(120.000000))
	
	if not aiming then
		Move(chest, y_axis, 0, 8.0)
		Turn(chest, y_axis, 0, math.rad(120.000000))
		Turn(rshoulder, x_axis, 0, math.rad(120.000000))
		Turn(rforearm, x_axis, 0, math.rad(120.000000))
		Turn(lshoulder, x_axis, 0, math.rad(120.000000))
		Turn(lforearm, x_axis, 0, math.rad(120.000000))
	end
end

function script.StopMoving()
	StartThread(StopMovingThread)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	
	Sleep(RESTORE_DELAY)
	Turn(chest, y_axis, 0, math.rad(90))
	Turn(chest, x_axis, 0, math.rad(45))
	WaitForTurn(chest, y_axis)
	WaitForTurn(chest, x_axis)
	aiming = false
end

function script.AimFromWeapon()
	return aim
end

function script.QueryWeapon()
	return flare
end

function script.FireWeapon()
	EmitSfx(flare, UNIT_SFX1)
	EmitSfx(flare, UNIT_SFX1)
end

function script.AimWeapon(num, heading, pitch)

	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	StartThread(RestoreAfterDelay)
	aiming = true
	
	Turn(chest, y_axis, heading, math.rad(150))
	Turn(chest, x_axis, -pitch-0.08, math.rad(60))
	WaitForTurn(chest, y_axis)
	WaitForTurn(chest, x_axis)
	return true
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(lfoot, sfxNone)
		Explode(lshin, sfxNone)
		Explode(lshoulder, sfxNone)
		Explode(lthigh, sfxNone)
		Explode(lforearm, sfxNone)
		Explode(rfoot, sfxNone)
		Explode(rshin, sfxNone)
		Explode(rshoulder, sfxNone)
		Explode(rthigh, sfxNone)
		Explode(rforearm, sfxNone)
		Explode(chest, sfxNone)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(lfoot, sfxFall)
		Explode(lshin, sfxFall)
		Explode(lshoulder, sfxFall)
		Explode(lthigh, sfxFall)
		Explode(lforearm, sfxFall)
		Explode(rfoot, sfxFall)
		Explode(rshin, sfxFall)
		Explode(rshoulder, sfxFall)
		Explode(rthigh, sfxFall)
		Explode(rforearm, sfxFall)
		Explode(chest, sfxShatter)
		return 1 -- corpsetype
	elseif (severity <= 1) then
		Explode(lfoot, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(lshin, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(lshoulder, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(lthigh, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(lforearm, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(rfoot, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(rshin, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(rshoulder, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(rthigh, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(rforearm, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(chest, sfxShatter)
		return 2
	end
	Explode(lfoot, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(lshin, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(lshoulder, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(lthigh, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(lforearm, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(rfoot, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(rshin, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(rshoulder, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(rthigh, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(rforearm, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(chest, sfxShatter, sfxExplodeOnHit)
	return 2
end
