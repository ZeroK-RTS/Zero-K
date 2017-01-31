local base = piece 'base' 
local l_leg = piece 'l_leg' 
local l_foot = piece 'l_foot' 
local l_rocket = piece 'l_rocket' 
local l_pt = piece 'l_pt' 
local r_leg = piece 'r_leg' 
local r_foot = piece 'r_foot' 
local r_rocket = piece 'r_rocket' 
local r_pt = piece 'r_pt' 
local pre_turret = piece 'pre_turret'
local turret = piece 'turret' 
local ram = piece 'ram' 
local spike = piece 'spike' 

include "constants.lua"
include "RockPiece.lua"
include "JumpRetreat.lua"

local smokePieces = {turret}

local gunHeading = 0
local walking = false

--Signal definitions
local SIG_MOVE = 2
local SIG_AIM = 4
local SIG_ROCK_X = 8
local SIG_ROCK_Z = 16
local SIG_RESTORE = 32
local SIG_STOP = 64

local ROCK_FORCE = 0.22

-- Rock X
local ROCK_X_SPEED = 10		--Number of half-cycles per second around x-axis.
local ROCK_X_DECAY = -1/2	--Rocking around x-axis is reduced by this factor each time = piece 'to rock.
local ROCK_PIECE_X = pre_turret	-- should be negative to alternate rocking direction.
local ROCK_X_MIN = 0.05 --If around x-axis rock is not greater than this amount, rocking will stop after returning to center.
local ROCK_X_MAX = 0.5

-- Rock Z
local ROCK_Z_SPEED = 10		--Number of half-cycles per second around z-axis.
local ROCK_Z_DECAY = -1/2	--Rocking around z-axis is reduced by this factor each time = piece 'to rock.
local ROCK_PIECE_Z = pre_turret	-- should be between -1 and 0 to alternate rocking direction.
local ROCK_Z_MIN = 0.05	--If around z-axis rock is not greater than this amount, rocking will stop after returning to center.
local ROCK_X_MAX = 0.5

-- Jumping

local function BeginJumpThread()
	Signal(SIG_MOVE)
	walking = false
	
	Move(l_rocket, x_axis, -1.5, 10)
	Move(r_rocket, x_axis, 1.5, 10)

	EmitSfx(l_foot, 1025)
	EmitSfx(r_foot, 1025)
	
	Turn(l_rocket, x_axis, math.rad(30), math.rad(60))
	Turn(r_rocket, x_axis, math.rad(30), math.rad(60))
	WaitForTurn(r_rocket, x_axis)
	Turn(l_rocket, x_axis, math.rad(-20), math.rad(15))
	Turn(r_rocket, x_axis, math.rad(-20), math.rad(15))
	WaitForTurn(r_rocket, x_axis)
	
	Turn(l_rocket, x_axis, 0, math.rad(30))
	Turn(r_rocket, x_axis, 0, math.rad(30))
end


local function EndJumpThread()

	EmitSfx(l_foot, 1025)
	EmitSfx(r_foot, 1025)
	
	Sleep(500)
	Move(l_rocket, x_axis, 2, 2)
	Move(r_rocket, x_axis, -2, 2)
end

function jumping(jumpPercent)
	GG.PokeDecloakUnit(unitID, 50)

	Turn(l_leg, x_axis, 0)
	Turn(r_leg, x_axis, 0)
	Turn(l_pt, x_axis, math.rad(90))
	Turn(r_pt, x_axis, math.rad(90))
	EmitSfx(l_pt, 1024)
	EmitSfx(r_pt, 1024)
end

function preJump(turn,distance)
end

function beginJump()
	StartThread(BeginJumpThread)
end

function halfJump()
end

function endJump()
	StartThread(EndJumpThread)
end

-- Moving

local function WalkThread()

	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	walking = true
	
	while true do

		Turn(r_leg, x_axis, math.rad(25), math.rad(50))
		Turn(r_foot, x_axis, math.rad(-10), math.rad(100))
		Turn(base, z_axis, math.rad(-(-8)), math.rad(15))
		Move(l_leg, y_axis, 0.3, 2)
		Turn(r_foot, z_axis, math.rad(-(8)), math.rad(15))
		Turn(l_foot, z_axis, math.rad(-(8)), math.rad(15))
		Move(base, y_axis, 3, 5)
		Move(r_foot, y_axis, 1.5, 2)
		Move(l_foot, y_axis, 1.5, 2)
		Turn(l_leg, x_axis, math.rad(-18), math.rad(50))
		Turn(l_foot, x_axis, math.rad(12), math.rad(100))
		Sleep(800)
		
		Turn(r_leg, x_axis, 0, math.rad(50))
		Turn(r_foot, x_axis, 0, math.rad(100))
		Turn(base, z_axis, math.rad(-(0)), math.rad(15))
		Move(l_leg, y_axis, -1, 1.5)
		Turn(r_foot, z_axis, math.rad(-(0)), math.rad(15))
		Turn(l_foot, z_axis, math.rad(-(0)), math.rad(15))
		Move(base, y_axis, 6, 2)
		Move(r_foot, y_axis, 0, 2)
		Move(l_foot, y_axis, 0, 2)
		Turn(l_leg, x_axis, 0, math.rad(50))
		Turn(l_foot, x_axis, 0, math.rad(100))
		--WaitForTurn(r_leg, x_axis)
		
		Turn(r_leg, x_axis, math.rad(-18), math.rad(50))
		Turn(r_foot, x_axis, math.rad(12), math.rad(100))
		Turn(base, z_axis, math.rad(-(8)), math.rad(15))
		Move(r_leg, y_axis, 0.1, 2)
		Turn(r_foot, z_axis, math.rad(-(-8)), math.rad(15))
		Turn(l_foot, z_axis, math.rad(-(-8)), math.rad(15))
		Move(base, y_axis, 3, 2)
		Move(r_foot, y_axis, 1.5, 2)
		Move(l_foot, y_axis, 1.5, 2)
		Turn(l_leg, x_axis, math.rad(25), math.rad(50))
		Turn(l_foot, x_axis, math.rad(-10), math.rad(100))
		Sleep(800)
		
		Turn(r_leg, x_axis, 0, math.rad(50))
		Turn(r_foot, x_axis, 0, math.rad(100))
		Turn(base, z_axis, math.rad(-(0)), math.rad(15))
		Move(r_leg, y_axis, -3, 1.5)
		Turn(r_foot, z_axis, math.rad(-(0)), math.rad(15))
		Turn(l_foot, z_axis, math.rad(-(0)), math.rad(15))
		Move(base, y_axis, 6, 2)
		Move(r_foot, y_axis, 0, 2)
		Move(l_foot, y_axis, 0, 2)
		Turn(l_leg, x_axis, 0, math.rad(50))
		Turn(l_foot, x_axis, 0, math.rad(100))
		--WaitForTurn(l_leg, x_axis)
	end
end

local function StopMovingThread()
	Signal(SIG_STOP)
	SetSignalMask(SIG_STOP)
	
	Sleep(50)
	
	Signal(SIG_MOVE)
	walking = false
	
	--move all the pieces to their original spots
	Turn(l_leg, x_axis, 0, math.rad(90))
	Turn(l_foot, x_axis, 0, math.rad(90))
	Turn(l_foot, z_axis, math.rad(-(0)), math.rad(15))
	Move(l_foot, y_axis, 0, 4)
	
	Turn(r_leg, x_axis, 0, math.rad(90))
	Turn(r_foot, x_axis, 0, math.rad(90))
	Turn(r_foot, z_axis, math.rad(-(0)), math.rad(15))
	Move(r_foot, y_axis, 0, 4)
	
	Turn(base, z_axis, math.rad(-(0)), math.rad(90))
	Turn(base, x_axis, 0, math.rad(90))
	Move(base, y_axis, 3, 5)
end

function script.StartMoving()
	Signal(SIG_STOP)
	if not walking then
		StartThread(WalkThread)
	end
end

function script.StopMoving()
	StartThread(StopMovingThread)
end

function script.Create()
	Move(base, y_axis, 3)
	Move(l_rocket, x_axis, 2)
	Move(r_rocket, x_axis, -2)
	InitializeRock(ROCK_PIECE_X, ROCK_X_SPEED, ROCK_X_DECAY, ROCK_X_MIN, ROCK_X_MAX, SIG_ROCK_X, x_axis)
	InitializeRock(ROCK_PIECE_Z, ROCK_Z_SPEED, ROCK_Z_DECAY, ROCK_Z_MIN, ROCK_Z_MAX, SIG_ROCK_Z, z_axis)
	StartThread(SmokeUnit, smokePieces)
end

function script.AimFromWeapon()
	return ram
end

function script.QueryWeapon()
	return ram
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(3000)
	Turn(pre_turret, y_axis, 0, math.rad(135))
	Turn(ram, x_axis, 0, math.rad(85))
end

function script.AimWeapon(num, heading, pitch)
	
	StartThread(RestoreAfterDelay)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(turret, y_axis, heading, math.rad(360)) -- left-right
	Turn(ram, x_axis, -pitch, math.rad(270)) --up-down
	WaitForTurn(ram, y_axis)
	WaitForTurn(turret, x_axis)
	gunHeading = heading
	return true
end

function script.FireWeapon(num)
	StartThread(Rock, gunHeading, ROCK_FORCE, z_axis)
	StartThread(Rock, gunHeading - hpi, ROCK_FORCE, x_axis)
	Move(spike, z_axis, 30, 1800)
	WaitForMove(spike, z_axis)
	Move(spike, z_axis, 0, 40)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= 0.25) then
		Explode(base, sfxNone)
		Explode(spike, sfxNone)
		Explode(turret, sfxNone)
		Explode(ram, sfxNone)
		Explode(l_foot, sfxNone)
		Explode(l_leg, sfxNone)
		Explode(r_foot, sfxNone)
		Explode(r_leg, sfxNone)
		return 1
	elseif (severity <= 0.5) then
		Explode(base, sfxNone)
		Explode(spike, sfxFall)
		Explode(turret, sfxFall)
		Explode(ram, sfxFall)
		Explode(l_foot, sfxFall)
		Explode(l_leg, sfxFall)
		Explode(r_foot, sfxFall)
		Explode(r_leg, sfxFall)
		return 1
	end
	Explode(base, sfxNone)
		Explode(spike, sfxFall + sfxSmoke + sfxFire)
		Explode(turret, sfxFall + sfxSmoke + sfxFire)
		Explode(ram, sfxFall + sfxSmoke + sfxFire)
		Explode(l_foot, sfxFall + sfxSmoke + sfxFire)
		Explode(l_leg, sfxFall + sfxSmoke + sfxFire)
		Explode(r_foot, sfxFall + sfxSmoke + sfxFire)
		Explode(r_leg, sfxFall + sfxSmoke + sfxFire)
	return 2
end
