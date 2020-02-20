include "constants.lua"

local base, body, turret, sleeve, barrel, firepoint = piece('base', 'body', 'turret', 'sleeve', 'barrel', 'firepoint')
local rwheel1, rwheel2, rwheel3 = piece('rwheel1', 'rwheel2', 'rwheel3')
local lwheel1, lwheel2, lwheel3 = piece('lwheel1', 'lwheel2', 'lwheel3')
local gs1r, gs2r, gs3r = piece('gs1r', 'gs2r', 'gs3r')
local gs1l, gs2l, gs3l = piece('gs1l', 'gs2l', 'gs3l')

local TURRET_TURN_SPEED  = math.rad(160)
local TURRET_PITCH_SPEED = math.rad(50)

local SUSPENSION_BOUND = 3
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
local function Suspension()
	local xtilt, xtilta = 0, 0, 0
	local ztilt, ztilta = 0, 0, 0
	local ya, yv, yp = 0, 0, 0

	while true do
		local s1r = GetWheelHeight(gs1r)
		local s2r = GetWheelHeight(gs2r)
		local s3r = GetWheelHeight(gs3r)
		local s1l = GetWheelHeight(gs1l)
		local s2l = GetWheelHeight(gs2l)
		local s3l = GetWheelHeight(gs3l)

		xtilta = (s3r + s3l - s1l - s1r)/6000
		xtiltv = xtiltv*0.99 + xtilta
		xtilt = xtilt*0.98 + xtiltv

		ztilta = (s1r + s2r + s3r - s1l - s2l - s3l)/15000
		ztiltv = ztiltv*0.99 + ztilta
		ztilt = ztilt*0.99 + ztiltv

		ya = (s1r + s2r + s3r + s1l + s2l + s3l)/1500
		yv = yv*0.99 + ya
		yp = yp*0.98 + yv

		Move(base, y_axis, yp)
		Turn(base, x_axis, xtilt)
		Turn(base, z_axis, -ztilt)

		Move(rwheel1, y_axis, s1r, 20)
		Move(rwheel2, y_axis, s2r, 20)
		Move(rwheel3, y_axis, s3r, 20)
		Move(lwheel1, y_axis, s1l, 20)
		Move(lwheel2, y_axis, s2l, 20)
		Move(lwheel3, y_axis, s3l, 20)

		local _, _, _, speed = spGetUnitVelocity(unitID)
		local wheelTurnSpeed = speed * 3
		Spin (rwheel1, x_axis, wheelTurnSpeed)
		Spin (rwheel2, x_axis, wheelTurnSpeed)
		Spin (rwheel3, x_axis, wheelTurnSpeed)
		Spin (lwheel1, x_axis, wheelTurnSpeed)
		Spin (lwheel2, x_axis, wheelTurnSpeed)
		Spin (lwheel3, x_axis, wheelTurnSpeed)

		Sleep (34)
	end
end

local function RestoreAfterDelay()
	SetSignalMask(1)
	Sleep (5000)

	Turn(turret, y_axis, 0, math.rad(30))
	Turn(sleeve, x_axis, 0, math.rad(10))
end

function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon(num)
	return firepoint
end

local lastHeading = 0
local cos = math.cos
local sin = math.sin
function script.Shot(num)
	xtiltv = xtiltv - cos(lastHeading) / 69
	ztiltv = ztiltv - sin(lastHeading) / 69

	Move (barrel, z_axis, -8)
	Move (barrel, z_axis, 0, 13)
	EmitSfx(firepoint, 1024)
	EmitSfx(firepoint, 1025)
end

function script.AimWeapon(num, heading, pitch)
	Signal(1)
	SetSignalMask(1)

	Turn(turret, y_axis, heading, TURRET_TURN_SPEED)
	Turn(sleeve, x_axis, -pitch, TURRET_PITCH_SPEED)
	WaitForTurn(turret, y_axis)
	WaitForTurn(sleeve, x_axis)

	StartThread(RestoreAfterDelay)
	lastHeading = heading

	return true
end

function script.Create()
	StartThread(Suspension)
	StartThread(GG.Script.SmokeUnit, unitID, {body, firepoint})
end

local explodables = {barrel, sleeve, turret, rwheel1, lwheel2, rwheel3, rwheel2, lwheel1, lwheel3}
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	local brutal = (severity > 0.5)

	for i = 1, #explodables do
		if math.random() < severity then
			Explode (explodables[i], SFX.FALL + (brutal and (SFX.SMOKE + SFX.FIRE) or 0))
		end
	end

	if not brutal then
		return 1
	else
		Explode (body, SFX.SHATTER)
		return 2
	end
end