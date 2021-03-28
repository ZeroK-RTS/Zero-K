include "constants.lua"

local base, body, turret, sleeve, barrel, firepoint = piece('base', 'body', 'turret', 'sleeve', 'barrel', 'firepoint')
local rwheel1, rwheel2, rwheel3, rwheel4 = piece('rwheel1', 'rwheel2', 'rwheel3', 'rwheel4')
local lwheel1, lwheel2, lwheel3, lwheel4 = piece('lwheel1', 'lwheel2', 'lwheel3', 'lwheel4')
local gs1r, gs2r, gs3r, gs4r = piece('gs1r', 'gs2r', 'gs3r', 'gs4r')
local gs1l, gs2l, gs3l, gs4l = piece('gs1l', 'gs2l', 'gs3l', 'gs4l')

local SIG_AIM = 1
local SIG_MOVE = 2
local RESTORE_DELAY = 3000
local TURRET_TURN_SPEED = math.rad(90)
local SLEEVE_TURN_SPEED = math.rad(45)

local angle = math.rad(90)

local recoil = -1.75
local recoilamount = 10
local returnspeed = 1.5
local fired = false

local mainhead = 0

local SUSPENSION_BOUND = 3


-- speedups --
local cos = math.cos
local sin = math.sin
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitPiecePosDir = Spring.GetUnitPiecePosDir

local function GetWheelHeight(piece)
	local x, y, z = spGetUnitPiecePosDir(unitID, piece)
	local height = spGetGroundHeight(x, z) - y
	if height < -SUSPENSION_BOUND then
		height = -SUSPENSION_BOUND
	elseif height > SUSPENSION_BOUND then
		height = SUSPENSION_BOUND
	end
	return height
end

local xtiltv, ztiltv = 0, 0
local spGetUnitVelocity = Spring.GetUnitVelocity

local function Suspension() -- Shamelessly stolen and adapted from Ripper. Perhaps this should be an include or something?
	local xtilt, ztilt = 0, 0
	local yv, yp = 0, 0
	local s1r, s2r, s3r, sl1, s2l, s3l, s4l, s4r, xtilta, ztilta, ya, speed, wheelTurnSpeed
	while true do
		s1r = GetWheelHeight(gs1r)
		s2r = GetWheelHeight(gs2r)
		s3r = GetWheelHeight(gs3r)
		s4r = GetWheelHeight(gs4r)
		s1l = GetWheelHeight(gs1l)
		s2l = GetWheelHeight(gs2l)
		s3l = GetWheelHeight(gs3l)
		s4l = GetWheelHeight(gs4l)
		xtilta = (s3r + s3l - s1l - s1r)/6000
		xtiltv = xtiltv*0.99 + xtilta
		xtilt = xtilt*0.98 + xtiltv

		ztilta = (s1r + s2r + s3r - s1l - s2l - s3l)/15000
		ztiltv = ztiltv*0.99 + ztilta
		ztilt = ztilt*0.99 + ztiltv
		
		ya = (s1r + s2r + s3r + s1l + s2l + s3l)/1500
		
		yv = yv*0.99 + ya
		if yv < -0.1 then
			yv = -0.1
		end
		yp = yp*0.98 + yv
		if yp < -3 then
			yp = -3
		end

		Move(base, y_axis, yp)
		Turn(base, x_axis, xtilt)
		Turn(base, z_axis, -ztilt)

		Move(rwheel1, y_axis, s1r, 20)
		Move(rwheel2, y_axis, s2r, 20)
		Move(rwheel3, y_axis, s3r, 20)
		Move(rwheel4, y_axis, s4r, 20)
		Move(lwheel1, y_axis, s1l, 20)
		Move(lwheel2, y_axis, s2l, 20)
		Move(lwheel3, y_axis, s3l, 20)
		Move(lwheel4, y_axis, s4l, 20)

		_, _, _, speed = spGetUnitVelocity(unitID)
		wheelTurnSpeed = speed * 3
		Spin (rwheel1, x_axis, wheelTurnSpeed)
		Spin (rwheel2, x_axis, wheelTurnSpeed)
		Spin (rwheel3, x_axis, wheelTurnSpeed)
		Spin (rwheel4, x_axis, wheelTurnSpeed)
		Spin (lwheel1, x_axis, wheelTurnSpeed)
		Spin (lwheel2, x_axis, wheelTurnSpeed)
		Spin (lwheel3, x_axis, wheelTurnSpeed)
		Spin (lwheel4, x_axis, wheelTurnSpeed)

		Sleep (34)
	end
end

local function BarrelRecoil()
	Move(barrel, z_axis, recoil)
	Sleep(200)
	Move(barrel, z_axis, 0, returnspeed)
end

local function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	Turn(turret, y_axis, 0, TURRET_TURN_SPEED)
	Turn(sleeve, x_axis, 0, SLEEVE_TURN_SPEED)
end

function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon(num)
	return firepoint
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(turret, y_axis, heading, TURRET_TURN_SPEED)
	Turn(sleeve, x_axis, -pitch, SLEEVE_TURN_SPEED)
	WaitForTurn(turret, y_axis)
	WaitForTurn(sleeve, x_axis)
	mainhead = heading -- Used for the "barrel recoil" thing.
	StartThread(RestoreAfterDelay)
	return true
end

function script.Shot(num) -- Moved off FireWeapon for modders/tweakunits mostly.
	xtiltv = xtiltv - cos(mainhead) / 80
	ztiltv = ztiltv - sin(mainhead) / 80
	EmitSfx(firepoint, 1024)
	EmitSfx(firepoint, 1025)
	StartThread(BarrelRecoil)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, {body, turret})
	StartThread(Suspension)
	Hide(firepoint)
end

local explodables = {barrel, sleeve, turret, rwheel1, rwheel2, rwheel3, rwheel4, lwheel1, lwheel2, lwheel3, lwheel4}
-- Note: Old script did not have exploding wheels. Liberties were taken.

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	local brutal = severity > 0.5
	for i = 1, #explodables do
		if math.random() < severity then
			Explode(explodables[i], SFX.FALL + (brutal and (SFX.SMOKE + SFX.FIRE) or 0))
		end
	end
	
	if not brutal then
		return 1
	else
		Explode(body, SFX.SHATTER)
		return 2
	end
end
