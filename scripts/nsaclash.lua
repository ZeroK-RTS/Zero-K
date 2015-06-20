include "constants.lua"
include "RockPiece.lua"

local base = piece 'base' 
local front = piece 'front' 
local turret = piece 'turret' 
local lbarrel = piece 'lbarrel' 
local rbarrel = piece 'rbarrel' 
local lflare = piece 'lflare' 
local rflare = piece 'rflare' 
local exhaust = piece 'exhaust' 
local wake1 = piece 'wake1' 
local wake2 = piece 'wake2' 
local wake3 = piece 'wake3' 
local wake4 = piece 'wake4' 
local wake5 = piece 'wake5' 
local wake6 = piece 'wake6' 
local wake7 = piece 'wake7' 
local wake8 = piece 'wake8' 
local ground1 = piece 'ground1'

local random = math.random 

local shotNum = 1
local flares = {
	lflare,
	rflare,
}

local gunHeading = 0

local SIG_ROCK_X = 8
local SIG_ROCK_Z = 16

local ROCK_FIRE_FORCE = 0.35
local ROCK_SPEED = 10	--Number of half-cycles per second around x-axis.
local ROCK_DECAY = -0.85	--Rocking around axis is reduced by this factor each time = piece 'to rock.
local ROCK_PIECE = base	-- should be negative to alternate rocking direction.
local ROCK_MIN = 0.001 --If around axis rock is not greater than this amount, rocking will stop after returning to center.
local ROCK_MAX = 1.5

local SIG_MOVE = 1
local SIG_AIM = 2
local RESTORE_DELAY = 3000

local function WobbleUnit()
	local wobble = true
	while true do
		if wobble == true then
			Move(base, y_axis, 0.9, 1.2)
		end
		if wobble == false then
		
			Move(base, y_axis, -0.9, 1.2)
		end
		wobble = not wobble
		Sleep(750)
	end
end

local function MoveScript()
	while Spring.GetUnitIsStunned(unitID) do
		Sleep(2000)
	end
	while true do
		if random() < 0.5 then
			EmitSfx(wake1, 5)
			EmitSfx(wake3, 5)
			EmitSfx(wake5, 5)
			EmitSfx(wake7, 5)
			EmitSfx(wake1, 3)
			EmitSfx(wake3, 3)
			EmitSfx(wake5, 3)
			EmitSfx(wake7, 3)
		else
			EmitSfx(wake2, 5)
			EmitSfx(wake4, 5)
			EmitSfx(wake6, 5)
			EmitSfx(wake8, 5)
			EmitSfx(wake2, 3)
			EmitSfx(wake4, 3)
			EmitSfx(wake6, 3)
			EmitSfx(wake8, 3)
		end
		EmitSfx(ground1, UNIT_SFX1)
		Sleep(150)
	end
end

function script.Create()
	Turn(exhaust, y_axis, math.rad(-180))
	StartThread(SmokeUnit, {base})
	StartThread(WobbleUnit)
	StartThread(MoveScript)
	InitializeRock(ROCK_PIECE, ROCK_SPEED, ROCK_DECAY, ROCK_MIN, ROCK_MAX, SIG_ROCK_X, x_axis)
	InitializeRock(ROCK_PIECE, ROCK_SPEED, ROCK_DECAY, ROCK_MIN, ROCK_MAX, SIG_ROCK_Z, z_axis)
end

local function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	Turn(turret, y_axis, 0, math.rad(90))
	Turn(turret, x_axis, 0, math.rad(45))
end

function script.AimFromWeapon() 
	return turret
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(turret, y_axis, heading, math.rad(180))
	Turn(turret, x_axis, -pitch, math.rad(100))
	Turn(lbarrel, y_axis, 2*pitch, math.rad(300))
	Turn(rbarrel, y_axis, -2*pitch, math.rad(300))
	Turn(lbarrel, x_axis, -pitch, math.rad(300))
	Turn(rbarrel, x_axis, -pitch, math.rad(300))
	gunHeading = heading
	WaitForTurn(turret, y_axis)
	WaitForTurn(turret, x_axis)
	StartThread(RestoreAfterDelay)
	return (1)
end

function script.QueryWeapon(piecenum)
	return flares[shotNum]
end

function script.FireWeapon()
	StartThread(Rock, gunHeading, ROCK_FIRE_FORCE, z_axis)
	StartThread(Rock, gunHeading - hpi, ROCK_FIRE_FORCE*0.4, x_axis)
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 620.1, 70, true)
end

function script.Shot() 
	EmitSfx(flares[shotNum], UNIT_SFX2)
	EmitSfx(exhaust, UNIT_SFX3)
	shotNum = 3 - shotNum
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(front, sfxNone)
		Explode(wake1, sfxNone)
		Explode(wake2, sfxNone)
		Explode(wake3, sfxNone)
		Explode(wake4, sfxNone)
		Explode(wake5, sfxNone)
		Explode(wake6, sfxNone)
		return 1
	elseif severity <= 0.50 then
		Explode(front, sfxNone)
		Explode(turret, sfxShatter)
		Explode(wake1, sfxFall)
		Explode(wake2, sfxFall)
		Explode(wake3, sfxFall)
		Explode(wake4, sfxFall)
		Explode(wake5, sfxFall)
		Explode(wake6, sfxFall)
		return 1
	elseif severity <= 0.99 then
		Explode(front, sfxShatter)
		Explode(turret, sfxShatter)
		Explode(wake1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(wake2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(wake3, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(wake4, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(wake5, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(wake6, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		return 2
	end
	Explode(front, sfxShatter)
	Explode(turret, sfxShatter)
	Explode(wake1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(wake2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(wake3, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(wake4, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(wake5, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(wake6, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	return 2
end
