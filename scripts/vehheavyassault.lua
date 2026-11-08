include "constants.lua"

local base, Hull, TurretHousing, Cannon, firepointC = piece('base', 'Hull', 'TurretHousing', 'Cannon', 'firepointC')
local TurretL, PistonL1, PistonL2, HeatrayL, firepointL = piece('TurretL', 'PistonL1', 'PistonL2', 'HeatrayL', 'firepointL')
local TurretR, PistonR1, PistonR2, HeatrayR, firepointR = piece('TurretR', 'PistonR1', 'PistonR2', 'HeatrayR', 'firepointR')
local Hatch, Cell1, Cell2, Cell3, Cell4, Cell5, Cell6, FireCell, HeldCell, ReloadCell = piece('Hatch', 'Cell1', 'Cell2', 'Cell3', 'Cell4', 'Cell5', 'Cell6', 'FireCell', 'HeldCell', 'ReloadCell')
local InserterPlate, Arm, Forearm, Loader, BottomClaw, LeftClaw, RightClaw = piece('InserterPlate', 'Arm', 'Forearm', 'Loader', 'BottomClaw', 'LeftClaw', 'RightClaw')
local RWheel1, RWheel2 = piece('RWheel1', 'RWheel2')
local LWheel1, LWheel2 = piece('LWheel1', 'LWheel2')
local RWheelGuard, LWheelGuard, RBackWheel, LBackWheel = piece('RWheelGuard', 'LWheelGuard', 'RBackWheel', 'LBackWheel')
local gs1r, gs2r, gs3r = piece('gs1r', 'gs2r', 'gs3r')
local gs1l, gs2l, gs3l = piece('gs1l', 'gs2l', 'gs3l')

local CANNON_TURN_SPEED  = math.rad(280)
local CANNON_PITCH_SPEED = math.rad(50)
local TURRET_TURN_SPEED = math.rad(50)
local TURRET_PITCH_SPEED = math.rad(10)

-- holy hell what am I doing
local ANIM_FRAMES = 4
Hide(HeldCell)
-- Do I need signals for reloading and other stuff?
--I mean I do need to reload the big gun I think
-- some stuff needs to be hidden by default like the cell in loader arm
-- I also need a method of ejecting the ammo cell
-- maybe I need to add the ammo cell as a separate object?

local RECOIL_FORCE  = 0.0035
local SUSPENSION_BOUND_UPPER = 1.5
local SUSPENSION_BOUND_LOWER = -4
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitPiecePosDir = Spring.GetUnitPiecePosDir
local function GetWheelHeight(piece)
	local x, y, z = spGetUnitPiecePosDir(unitID, piece)
	local height = spGetGroundHeight(x, z) - y
	if height < SUSPENSION_BOUND_LOWER then
		height = SUSPENSION_BOUND_LOWER
	elseif height > SUSPENSION_BOUND_UPPER then
		height = SUSPENSION_BOUND_UPPER
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
		local s3r = GetWheelHeight(gs3r)
		local s1l = GetWheelHeight(gs1l)
		local s2l = GetWheelHeight(gs2l)
		local s3l = GetWheelHeight(gs3l)

		local frontR = (s1r + s2r)*0.5
		local frontL = (s1l + s2l)*0.5

		local xtilta = (s2r + s2l - frontR - frontL)/9000
		xtiltv = xtiltv*0.99 + xtilta
		xtilt = xtilt*0.985 + xtiltv

		local ztilta = (frontR + s2r - frontL - s2l)/20000
		ztiltv = ztiltv*0.99 + ztilta
		ztilt = ztilt*0.99 + ztiltv

		local ya = (frontR + s2r + frontL + s2l)/3000
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

		Move(RWheel1, y_axis, s1r, 20)
		Move(RWheel2, y_axis, s2r, 20)
		Move(LWheel1, y_axis, s1l, 20)
		Move(LWheel2, y_axis, s2l, 20)
		Move(RBackWheel, y_axis, s3l, 20)
		Move(LBackWheel, y_axis, s3l, 20)

		local _, _, _, speed = spGetUnitVelocity(unitID)
		local wheelTurnSpeed = speed * 3
		Spin (RWheel1, x_axis, wheelTurnSpeed)
		Spin (RWheel2, x_axis, wheelTurnSpeed)
		Spin (LWheel1, x_axis, wheelTurnSpeed)
		Spin (LWheel2, x_axis, wheelTurnSpeed)
		Spin (RBackWheel, x_axis, wheelTurnSpeed*0.6)
		Spin (LBackWheel, x_axis, wheelTurnSpeed*0.6)

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
	return Cannon
end

function script.QueryWeapon(num)
	return firepointC
end

local lastHeading = 0
local cos = math.cos
local sin = math.sin

function script.Shot(num)
	xtiltv = xtiltv - cos(lastHeading) * RECOIL_FORCE
	ztiltv = ztiltv - sin(lastHeading) * RECOIL_FORCE

	Move (Cannon, z_axis, -2)
	Move (Cannon, z_axis, 0, 28)
	EmitSfx(firepointC, 1024)
	EmitSfx(firepointC, 1025)
end

function script.AimWeapon(num, heading, pitch)
	Signal(1)
	SetSignalMask(1)
	
	local turretProp = 0.6
	Turn(TurretHousing, y_axis, heading*turretProp, TURRET_TURN_SPEED)
	Turn(TurretHousing, x_axis, -pitch*turretProp, TURRET_TURN_SPEED)
	Turn(Cannon, y_axis, heading*(1 - turretProp), TURRET_TURN_SPEED)
	Turn(Cannon, x_axis, -pitch*(1 - turretProp), TURRET_PITCH_SPEED)
	WaitForTurn(Cannon, y_axis)
	WaitForTurn(Cannon, x_axis)

	StartThread(RestoreAfterDelay)
	lastHeading = heading

	return true
end

function script.Create()
	StartThread(Suspension)
	StartThread(GG.Script.SmokeUnit, unitID, {body, firepointC})
end

local explodables = {Cannon, Hull, TurretHousing, RWheel1, LWheel2, RBackWheel, LBackWheel, RWheel2, LWheel1, LWheelGuard, RWheelGuard}
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
