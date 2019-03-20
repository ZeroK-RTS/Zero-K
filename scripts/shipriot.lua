include "constants.lua"

local base = piece 'base' 
local hull = piece 'hull' 
local gunf = piece 'gunf' 
local barrelfl = piece 'barrelfl' 
local flarefl = piece 'flarefl' 
local barrelfr = piece 'barrelfr' 
local flarefr = piece 'flarefr' 
local gunb = piece 'gunb' 
local barrelbl = piece 'barrelbl' 
local flarebl = piece 'flarebl' 
local barrelbr = piece 'barrelbr' 
local flarebr = piece 'flarebr' 
local wake1 = piece 'wake1' 
local wake2 = piece 'wake2' 

local smokePiece = {gunf, hull, gunb}

local turretData = {
	{
		gun = gunb,
		barrelRight = barrelbr,
		barrelLeft = barrelbl,
		flares = {flarebr, flarebl},
		SIG_AIM = 2,
		SIG_RESTORE = 4,
		shot = 1,
		gunRestore = math.rad(180),
	},
	{
		gun = gunf,
		barrelRight = barrelfr,
		barrelLeft = barrelfl,
		flares = {flarefr, flarefl},
		SIG_AIM = 16,
		SIG_RESTORE = 32,
		shot = 1,
		gunRestore = 0,
	}
}

local gun_1, gun_2

-- Signal definitions
local SIG_AIM = 2
local SIG_AIM_2 = 4
local SIG_MOVE = 8
local SIG_RESTORE = 16

local RESTORE_DELAY = 3000


function script.Create()
	StartThread(GG.Script.SmokeUnit, smokePiece)

	Turn(gunb, y_axis, math.rad(-180))
end

local function MoveThread()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	while true do
		if(not Spring.GetUnitIsCloaked(unitID)) then
			EmitSfx(wake1, 2)
			EmitSfx(wake2, 2)
		end
		Sleep(300)
	end
end

function script.StartMoving()
	StartThread(MoveThread)
end

function script.StopMoving()
	Signal(SIG_MOVE)
end

local function RestoreAfterDelay(num)
	local turret = turretData[num]
	
	Signal(turret.SIG_RESTORE)
	SetSignalMask(turret.SIG_RESTORE)
	Sleep(RESTORE_DELAY)
	
	Turn(turret.gun, y_axis, turret.gunRestore, math.rad(90))
	Turn(turret.barrelRight, x_axis, 0, math.rad(50))
	Turn(turret.barrelLeft, x_axis, 0, math.rad(50))
end

function script.AimWeapon(num, heading, pitch)
	local turret = turretData[num]

	Signal(turret.SIG_AIM)
	SetSignalMask(turret.SIG_AIM)
	
	Turn(turret.gun, y_axis, heading, math.rad(800)) -- Was 375
	Turn(turret.barrelRight, x_axis, -pitch, math.rad(150))
	Turn(turret.barrelLeft, x_axis, -pitch, math.rad(150))
	WaitForTurn(turret.gun, y_axis)
	WaitForTurn(turret.barrelRight, x_axis)
	StartThread(RestoreAfterDelay, num)
	return true
end

function script.Shot(num)
	local turret = turretData[num]

	EmitSfx(turret.flares[turret.shot], 1024)
	EmitSfx(turret.gun, 1025)
	turret.shot = 3 - turret.shot
end

function script.AimFromWeapon(num)
	return turretData[num].gun
end

function script.QueryWeapon(num)
	local turret = turretData[num]

	return turret.flares[turret.shot]
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= 0.25) then
		Explode(hull, SFX.NONE)
		Explode(gunf, SFX.NONE)
		Explode(base, SFX.NONE)
		Explode(gunb, SFX.NONE)
		Explode(barrelfr, SFX.NONE)
		return 1
	end
	if severity <= 0.50 then
		Explode(hull, SFX.NONE)
		Explode(gunf, SFX.FALL)
		Explode(base, SFX.NONE)
		Explode(gunb, SFX.FALL)
		Explode(barrelbr, SFX.FALL)
		return 1
	end
	if severity <= 0.99 then
		Explode(hull, SFX.SHATTER)
		Explode(gunf, SFX.FALL)
		Explode(base, SFX.NONE)
		Explode(gunb, SFX.FALL)
		Explode(barrelbr, SFX.FALL)
		Explode(barrelfr, SFX.FALL)
		Explode(barrelfl, SFX.FALL)
		return 2
	end
	Explode(hull, SFX.SHATTER)
	Explode(gunf, SFX.FALL)
	Explode(base, SFX.NONE)
	Explode(gunb, SFX.FALL)
	Explode(barrelbr, SFX.FALL)
	Explode(barrelfr, SFX.FALL)
	Explode(barrelfl, SFX.FALL)
	return 2
end
