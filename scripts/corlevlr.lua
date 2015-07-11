include "constants.lua"
include "RockPiece.lua"
include "pieceControl.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------

local base, body, turret, sleeve, barrel, firepoint,
			rwheel1, rwheel2, rwheel3,
			lwheel1, lwheel2, lwheel3,
			gs1r, gs2r, gs3r,
			gs1l, gs2l, gs3l = piece(
		'base', 'body', 'turret', 'sleeve', 'barrel', 'firepoint',
			'rwheel1', 'rwheel2', 'rwheel3',
			'lwheel1', 'lwheel2', 'lwheel3',
			'gs1r', 'gs2r', 'gs3r',
			'gs1l', 'gs2l', 'gs3l')
			
-- speedups
local spGetGroundHeight = Spring.GetGroundHeight
local spGetPiecePosition = Spring.GetUnitPiecePosition
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitPiecePosDir = Spring.GetUnitPiecePosDir

local disarmed = false
local isMoving = false
local isAiming = false


local smokePiece = {turret, body}

local SUSPENSION_BOUND = 7
local WHEEL_TURN_MULT = 2.0

local ANIM_PERIOD = 50
local RESTORE_DELAY = 3000

local TURRET_TURN_SPEED = 160
local GUN_TURN_SPEED = 50


local SIG_Restore = 1
local SIG_Aim = 2
local SIG_Move = 4
local SIG_ROCK_X = 8
local SIG_ROCK_Z = 16
local SIG_Stun = 32

local ROCK_FIRE_FORCE = 0.2
local ROCK_SPEED = 9		--Number of half-cycles per second around x-axis.
local ROCK_DECAY = -0.25	--Rocking around axis is reduced by this factor each time = piece 'to rock.
local ROCK_PIECE = base	-- should be negative to alternate rocking direction.
local ROCK_MIN = 0.001 --If around axis rock is not greater than this amount, rocking will stop after returning to center.
local ROCK_MAX = 1.5

local gunHeading = 0

----

local function RestoreAfterDelay()
	Sleep(3000)
	Turn(turret, y_axis, math.rad(0), math.rad(TURRET_TURN_SPEED))
	Turn(sleeve, x_axis, math.rad(0), math.rad(GUN_TURN_SPEED))
	
	WaitForTurn (turret, y_axis)
	WaitForTurn (sleeve, x_axis)
	
	isAiming = false
end

local function GetWheelHeight(piece)
	local x,y,z = spGetUnitPiecePosDir(unitID, piece)
	local height = spGetGroundHeight(x,z) - y
	if height < -SUSPENSION_BOUND then
		height = -SUSPENSION_BOUND
	end
	if height > SUSPENSION_BOUND then
		height = SUSPENSION_BOUND
	end
	return height
end

function WheelsControl()
	Signal (SIG_Move)
	SetSignalMask (SIG_Move)
	
	local wheelTurnSpeed = 0
	local xtilta, xtiltv, xtilt = 0, 0 ,0
	local ztilta, ztiltv, ztilt = 0, 0, 0 
	local ya, yv, yp = 0, 0, 0
	
	while true do
		if isMoving then
			local speed  = select(4, spGetUnitVelocity(unitID))
			wheelTurnSpeed = speed * WHEEL_TURN_MULT
			
			local s1r = GetWheelHeight(gs1r)
			local s2r = GetWheelHeight(gs2r)
			local s3r = GetWheelHeight(gs3r)
			
			local s1l = GetWheelHeight(gs1l)
			local s2l = GetWheelHeight(gs2l)
			local s3l = GetWheelHeight(gs3l)
			
			xtilta = (s2r + s2l - s1l - s1r)/6000 
			xtiltv = xtiltv*0.99 + xtilta
			xtilt = xtilt*0.98 + xtiltv

			ztilta = (s1r + s2r - s1l - s2l)/10000
			ztiltv = ztiltv*0.99 + ztilta
			ztilt = ztilt*0.99 + ztiltv

			ya = (s1r + s2r + s1l + s2l)/1000
			yv = yv*0.99 + ya
			yp = yp*0.98 + yv

			Move(base, y_axis, yp, 9000)
			Turn(base, x_axis, xtilt, math.rad(9000))
			Turn(base, z_axis, -ztilt, math.rad(9000))

			Move(rwheel1, y_axis, s1r, 20)
			Move(rwheel2, y_axis, s2r, 20)
			Move(rwheel3, y_axis, s3r, 20)
										
			Move(lwheel1, y_axis, s1l, 20)
			Move(lwheel2, y_axis, s2l, 20)
			Move(lwheel3, y_axis, s3l, 20) 
		else
			wheelTurnSpeed = 0
		end
		
		Spin(rwheel1, x_axis, wheelTurnSpeed)
		Spin(rwheel2, x_axis, wheelTurnSpeed)
		Spin(rwheel3, x_axis, wheelTurnSpeed)
		
		Spin(lwheel1, x_axis, wheelTurnSpeed)
		Spin(lwheel2, x_axis, wheelTurnSpeed)
		Spin(lwheel3, x_axis, wheelTurnSpeed)
		
		Sleep(ANIM_PERIOD)	
	end
end

function StunnedThread()
	disarmed = true
	Signal (SIG_Restore)
	Signal (SIG_Stun)
	SetSignalMask (SIG_Stun)
	StopTurn(turret, y_axis)
	StopTurn(sleeve, x_axis)
	while IsDisarmed() do
		Sleep (100)
	end
	disarmed = false
	if isAiming then
		StartThread(RestoreAfterDelay)
	end
end

function Stunned(isFull)
	StartThread (StunnedThread) -- for Sleep()
end

function script.StartMoving()
	isMoving = true
	StartThread(WheelsControl)
end

function script.StopMoving()
	isMoving = false
end

-- Weapons
function script.AimFromWeapon1()
	return turret
end

function script.QueryWeapon1()
	return firepoint
end

function script.AimWeapon1(heading, pitch)
	Signal (SIG_Aim)
	SetSignalMask (SIG_Aim)

	isAiming = true
	
	while disarmed do
		Sleep (100)
	end

	local slowMult = (1 - (Spring.GetUnitRulesParam (unitID, "slowState") or 0))
	Turn (turret, y_axis, heading, math.rad(TURRET_TURN_SPEED)*slowMult)
	Turn (sleeve, x_axis, -pitch, math.rad(GUN_TURN_SPEED)*slowMult)

	StartThread(RestoreAfterDelay)
	WaitForTurn(turret, y_axis)
	WaitForTurn(sleeve, x_axis)

	gunHeading = heading

	return true	
end

function script.Shot1()
	StartThread(Rock, gunHeading, ROCK_FIRE_FORCE, z_axis)
	StartThread(Rock, gunHeading - hpi, ROCK_FIRE_FORCE, x_axis)
	Move(barrel , z_axis, -1)
	Move(barrel , z_axis, 0 , 4)
	EmitSfx(firepoint,  UNIT_SFX1)
	EmitSfx(firepoint,  UNIT_SFX2)
end

function script.Create()
	InitializeRock(ROCK_PIECE, ROCK_SPEED, ROCK_DECAY, ROCK_MIN, ROCK_MAX, SIG_ROCK_X, x_axis)
	InitializeRock(ROCK_PIECE, ROCK_SPEED, ROCK_DECAY, ROCK_MIN, ROCK_MAX, SIG_ROCK_Z, z_axis)
	
	while (select(5, Spring.GetUnitHealth(unitID)) < 1) do
		Sleep (250)
	end

	StartThread(SmokeUnit, smokePiece)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth * 100
	if (severity <= 25) then			
		Explode(barrel, sfxNone)
		Explode(sleeve, sfxNone)
		Explode(body, sfxNone)
		Explode(turret, sfxNone)
		return 1
	end
	if severity < 50 then
		Explode(barrel, sfxFall)
		Explode(sleeve, sfxFall)
		Explode(body, sfxNone)
		Explode(turret, sfxShatter)
		return 2
	end
	if severity < 100 then			
		Explode(barrel, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(sleeve, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(body, sfxNone)
		Explode(turret, sfxShatter)
		return 3
	end
	-- D-Gunned/Self-D
	if severity >= 100 then			
		Explode(barrel, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(sleeve, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(body, sfxShatter)
		Explode(turret, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		return 3
	end
end