include "constants.lua"

local base, Hull, TurretHousing, Cannon, firepointC = piece('base', 'Hull', 'TurretHousing', 'Cannon', 'firepointC')
local TurretL, PistonL1, PistonL2, HeatrayL, firepointL = piece('TurretL', 'PistonL1', 'PistonL2', 'HeatrayL', 'firepointL')
local TurretR, PistonR1, PistonR2, HeatrayR, firepointR = piece('TurretR', 'PistonR1', 'PistonR2', 'HeatrayR', 'firepointR')
local Cell1, Cell2, Cell3, Cell4, Cell5, Cell6, FireCell, HeldCell, ReloadCell = piece('Cell1', 'Cell2', 'Cell3', 'Cell4', 'Cell5', 'Cell6', 'FireCell', 'HeldCell', 'ReloadCell')
local InserterPlate, Arm, Forearm, Loader, BottomClaw, LeftClaw, RightClaw = piece('InserterPlate', 'Arm', 'Forearm', 'Loader', 'BottomClaw', 'LeftClaw', 'RightClaw')
local RWheel1, RWheel2 = piece('RWheel1', 'RWheel2')
local LWheel1, LWheel2 = piece('LWheel1', 'LWheel2')
local RWheelGuard, LWheelGuard, BackWheels = piece('RWheelGuard', 'LWheelGuard', 'BackWheels')
local gs1r, gs2r = piece('gs1r', 'gs2r')
local gs1l, gs2l = piece('gs1l', 'gs2l')

local CANNON_TURN_SPEED  = math.rad(280)
local CANNON_PITCH_SPEED = math.rad(50)
local TURRET_TURN_SPEED = math.rad(50)
local TURRET_PITCH_SPEED - math.rad(10)


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
	local xtilt, ztilt = 0, 0
	local yv, yp = 0, 0

	while true do
		local s1r = GetWheelHeight(gs1r)
		local s2r = GetWheelHeight(gs2r)
		local s1l = GetWheelHeight(gs1l)
		local s2l = GetWheelHeight(gs2l)

		local xtilta = (s2r + s2l - s1l - s1r)/6000
		xtiltv = xtiltv*0.99 + xtilta
		xtilt = xtilt*0.98 + xtiltv

		local ztilta = (s1r + s2r - s1l - s2l)/15000
		ztiltv = ztiltv*0.99 + ztilta
		ztilt = ztilt*0.99 + ztiltv

		local ya = (s1r + s2r + s1l + s2l)/1500
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

		Move(RWheelGuard, y_axis, s1r, 20)
		Move(LWheelGuard, y_axis, s1l, 20)
		Move(BackWheels, y_axis, s2l, 20)

		local _, _, _, speed = spGetUnitVelocity(unitID)
		local wheelTurnSpeed = speed * 3
		Spin (RWheel1, x_axis, wheelTurnSpeed)
		Spin (RWheel2, x_axis, wheelTurnSpeed)
		Spin (LWheel1, x_axis, wheelTurnSpeed)
		Spin (LWheel2, x_axis, wheelTurnSpeed)
		Spin (Backwheels, x_axis, wheelTurnSpeed/2)

		Sleep (34)
	end
end

local function RestoreAfterDelay()
	SetSignalMask(1)
	Sleep (5000)

	Turn(Cannon, y_axis, 0, math.rad(90))
	Turn(Cannon, x_axis, 0, math.rad(30))
	Turn(TurretHousing, y_axis, 0, math.rad(20))
	Turn(TurretHousing, x_axis, 0, math.rad(10))
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
