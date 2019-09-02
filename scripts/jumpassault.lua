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
include "rockPiece.lua"
include "JumpRetreat.lua"
local dynamicRockData

local smokePieces = {turret}

local gunHeading = 0
local walking = false
local hpi = math.pi*0.5

local PACE = 1.9

--Signal definitions
local SIG_MOVE = 2
local SIG_AIM = 4
local SIG_ROCK_X = 8
local SIG_ROCK_Z = 16
local SIG_RESTORE = 32
local SIG_STOP = 64

local ROCK_FORCE = 0.22

-- GG.ScriptRock.Rock X
local ROCK_X_SPEED = 10 -- Number of half-cycles per second around x-axis.
local ROCK_X_DECAY = -1/2 -- Rocking around x-axis is reduced by this factor each time = piece 'to rock.
local ROCK_X_PIECE = pre_turret -- should be negative to alternate rocking direction.
local ROCK_X_MIN = 0.05 -- If around x-axis rock is not greater than this amount, rocking will stop after returning to center.
local ROCK_X_MAX = 0.5

-- GG.ScriptRock.Rock Z
local ROCK_Z_SPEED = 10 -- Number of half-cycles per second around z-axis.
local ROCK_Z_DECAY = -1/2 -- Rocking around z-axis is reduced by this factor each time = piece 'to rock.
local ROCK_Z_PIECE = pre_turret -- should be between -1 and 0 to alternate rocking direction.
local ROCK_Z_MIN = 0.05 -- If around z-axis rock is not greater than this amount, rocking will stop after returning to center.
local ROCK_Z_MAX = 0.5

local rockData = {
	[x_axis] = {
		piece  = ROCK_X_PIECE,
		speed  = ROCK_X_SPEED,
		decay  = ROCK_X_DECAY,
		minPos = ROCK_X_MIN,
		maxPos = ROCK_X_MAX,
		signal = SIG_ROCK_X,
		axis = x_axis,
	},
	[z_axis] = {
		piece  = ROCK_Z_PIECE,
		speed  = ROCK_Z_SPEED,
		decay  = ROCK_Z_DECAY,
		minPos = ROCK_Z_MIN,
		maxPos = ROCK_Z_MAX,
		signal = SIG_ROCK_Z,
		axis = z_axis,
	},
}

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
	local speedMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)*PACE
	
	while true do

		Turn(r_leg, x_axis, math.rad(25), math.rad(50) * speedMult)
		Turn(r_foot, x_axis, math.rad(-10), math.rad(100) * speedMult)
		Turn(base, z_axis, math.rad(-(-8)), math.rad(15) * speedMult)
		Move(l_leg, y_axis, 0.3, 2 * speedMult)
		Turn(r_foot, z_axis, math.rad(-(8)), math.rad(15) * speedMult)
		Turn(l_foot, z_axis, math.rad(-(8)), math.rad(15) * speedMult)
		Move(base, y_axis, 3, 5 * speedMult)
		Move(r_foot, y_axis, 1.5, 2 * speedMult)
		Move(l_foot, y_axis, 1.5, 2 * speedMult)
		Turn(l_leg, x_axis, math.rad(-18), math.rad(50) * speedMult)
		Turn(l_foot, x_axis, math.rad(12), math.rad(100) * speedMult)
		Sleep(800/speedMult)
		
		speedMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)*PACE
		
		Turn(r_leg, x_axis, 0, math.rad(50) * speedMult)
		Turn(r_foot, x_axis, 0, math.rad(100) * speedMult)
		Turn(base, z_axis, math.rad(-(0)), math.rad(15) * speedMult)
		Move(l_leg, y_axis, -1, 1.5 * speedMult)
		Turn(r_foot, z_axis, math.rad(-(0)), math.rad(15) * speedMult)
		Turn(l_foot, z_axis, math.rad(-(0)), math.rad(15) * speedMult)
		Move(base, y_axis, 6, 2 * speedMult)
		Move(r_foot, y_axis, 0, 2 * speedMult)
		Move(l_foot, y_axis, 0, 2 * speedMult)
		Turn(l_leg, x_axis, 0, math.rad(50) * speedMult)
		Turn(l_foot, x_axis, 0, math.rad(100) * speedMult)
		--WaitForTurn(r_leg, x_axis)
		
		Turn(r_leg, x_axis, math.rad(-18), math.rad(50) * speedMult)
		Turn(r_foot, x_axis, math.rad(12), math.rad(100) * speedMult)
		Turn(base, z_axis, math.rad(-(8)), math.rad(15) * speedMult)
		Move(r_leg, y_axis, 0.1, 2 * speedMult)
		Turn(r_foot, z_axis, math.rad(-(-8)), math.rad(15) * speedMult)
		Turn(l_foot, z_axis, math.rad(-(-8)), math.rad(15) * speedMult)
		Move(base, y_axis, 3, 2 * speedMult)
		Move(r_foot, y_axis, 1.5, 2 * speedMult)
		Move(l_foot, y_axis, 1.5, 2 * speedMult)
		Turn(l_leg, x_axis, math.rad(25), math.rad(50) * speedMult)
		Turn(l_foot, x_axis, math.rad(-10), math.rad(100) * speedMult)
		Sleep(800/speedMult)
		
		speedMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)*PACE
		
		Turn(r_leg, x_axis, 0, math.rad(50) * speedMult)
		Turn(r_foot, x_axis, 0, math.rad(100) * speedMult)
		Turn(base, z_axis, math.rad(-(0)), math.rad(15) * speedMult)
		Move(r_leg, y_axis, -3, 1.5 * speedMult)
		Turn(r_foot, z_axis, math.rad(-(0)), math.rad(15) * speedMult)
		Turn(l_foot, z_axis, math.rad(-(0)), math.rad(15) * speedMult)
		Move(base, y_axis, 6, 2 * speedMult)
		Move(r_foot, y_axis, 0, 2 * speedMult)
		Move(l_foot, y_axis, 0, 2 * speedMult)
		Turn(l_leg, x_axis, 0, math.rad(50) * speedMult)
		Turn(l_foot, x_axis, 0, math.rad(100) * speedMult)
		--WaitForTurn(l_leg, x_axis)
	end
end

local function StopMovingThread()
	Signal(SIG_STOP)
	SetSignalMask(SIG_STOP)
	
	Sleep(50)
	
	local speedMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)*PACE
	Signal(SIG_MOVE)
	walking = false
	
	--move all the pieces to their original spots
	Turn(l_leg, x_axis, 0, math.rad(90) * speedMult)
	Turn(l_foot, x_axis, 0, math.rad(90) * speedMult)
	Turn(l_foot, z_axis, math.rad(-(0)), math.rad(15) * speedMult)
	Move(l_foot, y_axis, 0, 4 * speedMult)
	
	Turn(r_leg, x_axis, 0, math.rad(90) * speedMult)
	Turn(r_foot, x_axis, 0, math.rad(90) * speedMult)
	Turn(r_foot, z_axis, math.rad(-(0)), math.rad(15) * speedMult)
	Move(r_foot, y_axis, 0, 4 * speedMult)
	
	Turn(base, z_axis, math.rad(-(0)), math.rad(90) * speedMult)
	Turn(base, x_axis, 0, math.rad(90) * speedMult)
	Move(base, y_axis, 3, 5 * speedMult)
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
	dynamicRockData = GG.ScriptRock.InitializeRock(rockData)
	StartThread(GG.Script.SmokeUnit, unitID, smokePieces)
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
	StartThread(GG.ScriptRock.Rock, dynamicRockData[z_axis], gunHeading, ROCK_FORCE)
	StartThread(GG.ScriptRock.Rock, dynamicRockData[x_axis], gunHeading - hpi, ROCK_FORCE)
	Move(spike, z_axis, 30, 1800)
	WaitForMove(spike, z_axis)
	Move(spike, z_axis, 0, 40)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= 0.25) then
		Explode(base, SFX.NONE)
		Explode(spike, SFX.NONE)
		Explode(turret, SFX.NONE)
		Explode(ram, SFX.NONE)
		Explode(l_foot, SFX.NONE)
		Explode(l_leg, SFX.NONE)
		Explode(r_foot, SFX.NONE)
		Explode(r_leg, SFX.NONE)
		return 1
	elseif (severity <= 0.5) then
		Explode(base, SFX.NONE)
		Explode(spike, SFX.FALL)
		Explode(turret, SFX.FALL)
		Explode(ram, SFX.FALL)
		Explode(l_foot, SFX.FALL)
		Explode(l_leg, SFX.FALL)
		Explode(r_foot, SFX.FALL)
		Explode(r_leg, SFX.FALL)
		return 1
	end
	Explode(base, SFX.NONE)
		Explode(spike, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(ram, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(l_foot, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(l_leg, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(r_foot, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(r_leg, SFX.FALL + SFX.SMOKE + SFX.FIRE)
	return 2
end
