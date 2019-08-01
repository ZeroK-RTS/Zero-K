include "constants.lua"

local base, body, turret, sleeve, barrel, firepoint,
	rwheel1, rwheel2,
	lwheel1, lwheel2,
	lfender1, lfender2, rfender1, rfender2,
	gs1r, gs2r,
	gs1l, gs2l
= piece(
	'base', 'body', 'turret', 'sleeve', 'barrel', 'firepoint',
	'rwheel1', 'rwheel2',
	'lwheel1', 'lwheel2',
	'lfender1', 'lfender2', 'rfender1', 'rfender2',
	'gs1r', 'gs2r',
	'gs1l', 'gs2l'
)

local moving, runSpin, reloading, mainHead, wheelTurnSpeed

local smokePiece = {turret, body}

-- Signal definitions
local SIG_AIM = 1
local ANIM_SPEED = 50
local RESTORE_DELAY = 2000

local TURRET_TURN_SPEED = 220
local SLEEVE_TURN_SPEED = 70

local SUSPENSION_BOUND = 6
local WHEEL_TURN_MULT = 3
local MAX_PIVOT = math.rad(30)

local spGetGroundHeight = Spring.GetGroundHeight
local spGetPiecePosition = Spring.GetUnitPiecePosition
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetUnitPosition = Spring.GetUnitPosition


local function GetWheelHeight(piece)
	local x,y,z = Spring.GetUnitPiecePosDir(unitID, piece)
	local height = spGetGroundHeight(x,z) - y
	if height < -SUSPENSION_BOUND then
		height = -SUSPENSION_BOUND
	end
	if height > SUSPENSION_BOUND then
		height = SUSPENSION_BOUND
	end
	return height
end

function Suspension()
	local x, y, z, height
	local s1r, s2r = 0, 0
	local s1l, s2l = 0, 0
	local xtilt, xtiltv, xtilta = 0, 0, 0
	local ztilt, ztiltv, ztilta = 0, 0, 0
	local ya, yv, yp = 0, 0, 0
	local speed = 0
	local onGround = false
	
	while true do 
		-- Moving check
		speed = select(4,spGetUnitVelocity(unitID))
		wheelTurnSpeed = speed*WHEEL_TURN_MULT
	
		if not moving and speed > 0.06 then
			runSpin = true
			moving = true
		end

		if moving then
			x,y,z = spGetUnitPosition(unitID)
			height = spGetGroundHeight(x,z)
			if y - height < 1 then -- If I am on the ground
				s1r = GetWheelHeight(gs1r) 
				s2r = GetWheelHeight(gs2r) 
				s1l = GetWheelHeight(gs1l) 
				s2l = GetWheelHeight(gs2l) 
				
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
				Move(rfender1, y_axis, s1r, 20)
				Move(rfender2, y_axis, s2r, 20)
											
				Move(lwheel1, y_axis, s1l, 20)
				Move(lwheel2, y_axis, s2l, 20)
				Move(lfender1, y_axis, s1l, 20)
				Move(lfender2, y_axis, s2l, 20)

				Spin(rwheel1, x_axis, wheelTurnSpeed)
				Spin(rwheel2, x_axis, wheelTurnSpeed)
				Spin(lwheel1, x_axis, wheelTurnSpeed)
				Spin(lwheel2, x_axis, wheelTurnSpeed)
			end
		end
		Sleep(50)
	end 
end

function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	Turn(turret, y_axis, 0, math.rad(90))
end

function script.StopMoving()
	moving = false
	StartThread(Roll)
end

function Roll()
	Sleep(500)
	if not moving then
		StopSpin(rwheel1, x_axis)
		StopSpin(rwheel2, x_axis)
		StopSpin(lwheel1, x_axis)
		StopSpin(lwheel2, x_axis)
	
		runSpin = false
	end
end

function script.StartMoving()
	moving = true
	runSpin = true
	
	local x,y,z = spGetUnitVelocity(unitID)
	wheelTurnSpeed = math.sqrt(x*x+y*y+z*z)*10
	
	Spin(rwheel1, x_axis, wheelTurnSpeed)
	Spin(rwheel2, x_axis, wheelTurnSpeed)
	Spin(lwheel1, x_axis, wheelTurnSpeed)
	Spin(lwheel2, x_axis, wheelTurnSpeed)
end

-- Weapons
function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon(num)
	return firepoint
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	
	Turn(turret, y_axis, heading, math.rad(TURRET_TURN_SPEED))
	Turn(sleeve, x_axis, -pitch, math.rad(SLEEVE_TURN_SPEED))
	WaitForTurn(turret, y_axis)
	WaitForTurn(sleeve, y_axis)
	StartThread(RestoreAfterDelay)

	return (true)
end

function FireWeapon(num)
	EmitSfx(firepoint, GG.Script.UNIT_SFX1)
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity >= 0 and severity < 0.25 then
		Explode(barrel, SFX.NONE)
		Explode(sleeve, SFX.NONE)
		Explode(body, SFX.NONE)
		Explode(turret, SFX.NONE)
		return 1
	elseif severity < 0.50 then
		Explode(barrel, SFX.FALL)
		Explode(sleeve, SFX.FALL)
		Explode(body, SFX.NONE)
		Explode(turret, SFX.SHATTER)
		return 1
	elseif severity < 1 then
		Explode(barrel, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(sleeve, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(body, SFX.NONE)
		Explode(turret, SFX.SHATTER)
		return 2
	else
		Explode(barrel, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(sleeve, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(body, SFX.SHATTER)
		Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	end
end

function script.Create()
	moving = false
	StartThread(Suspension)
	
	StartThread(GG.Script.SmokeUnit, smokePiece)
end
