include "constants.lua"

local base, Hull, TurretHousing, Cannon, firepointC = piece('base', 'Hull', 'TurretHousing', 'Cannon', 'firepointC')
local TurretL, PistonL1, PistonL2, HeatrayL, firepointL = piece('TurretL', 'PistonL1', 'PistonL2', 'HeatrayL', 'firepointL')
local TurretR, PistonR1, PistonR2, HeatrayR, firepointR = piece('TurretR', 'PistonR1', 'PistonR2', 'HeatrayR', 'firepointR')
local Hatch, Cell1, Cell2, Cell3, Cell4, Cell5, Cell6, FireCell, HeldCell, ReloadCell = piece('Hatch', 'Cell1', 'Cell2', 'Cell3', 'Cell4', 'Cell5', 'Cell6', 'FireCell', 'HeldCell', 'ReloadCell')
local InserterPlate, Arm, Forearm, Loader, BottomClaw, LeftClaw, RightClaw = piece('InserterPlate', 'Arm', 'Forearm', 'Loader', 'BottomClaw', 'LeftClaw', 'RightClaw')
local RWheel1, RWheel2 = piece('RWheel1', 'RWheel2')
local LWheel1, LWheel2 = piece('LWheel1', 'LWheel2')
local RWheelGuard, LWheelGuard, BackWheels = piece('RWheelGuard', 'LWheelGuard', 'BackWheels')
local gs1r, gs2r = piece('gs1r', 'gs2r')
local gs1l, gs2l = piece('gs1l', 'gs2l')

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
		Spin (Backwheels, x_axis, wheelTurnSpeed)

		Sleep (34)
	end
end



local function Reload()
 -- For demolisher.blend Created by https://github.com/Beherith/Skeletor_S3O V((1, 3, 0))
	-- Frame:6
	Signal(SIG_RELOAD)
	SetSignalMask(SIG_RELOAD)
	local speedMult, sleepTime = GG.Script.GetSpeedParams(unitID, ANIM_FRAMES)

	Hide(FireCell)
	Move(Cell3, x_axis, 0.000000, 45.491699 * speedMult)
	Move(Cell3, z_axis, 0.000000, 71.281450 * speedMult)
	Move(Cell3, y_axis, 0.000000, 80.860748 * speedMult)
	Move(Cell1, x_axis, 0.000000, 30.281832 * speedMult)
	Move(Cell1, y_axis, 0.000000, 113.013325 * speedMult)
	Move(Cell2, x_axis, 0.000000, 44.858254 * speedMult)
	Move(Cell2, z_axis, 0.000000, 41.378213 * speedMult)
	Move(Cell2, y_axis, 0.000000, 99.822750 * speedMult)
	Move(Cell4, x_axis, 0.000000, 30.281814 * speedMult)
	Move(Cell4, y_axis, 0.000000, 113.013332 * speedMult)
	Move(Cell5, x_axis, 0.000000, 44.858254 * speedMult)
	Move(Cell5, z_axis, 0.000000, 41.378213 * speedMult)
	Move(Cell5, y_axis, 0.000000, 99.822750 * speedMult)
	Move(Cell6, x_axis, 0.000000, 45.491749 * speedMult)
	Move(Cell6, z_axis, 0.000000, 71.281486 * speedMult)
	Move(Cell6, y_axis, 0.000000, 80.860691 * speedMult)
	Turn(LeftClaw, y_axis, 0.188496, 5.654866 * speedMult)
	Turn(RightClaw, y_axis, -0.188496, 5.654866 * speedMult)
		Sleep(sleepTime)
	-- Frame:10
	Turn(LeftClaw, y_axis, 0.436332, 7.435103 * speedMult)
	Turn(RightClaw, y_axis, -0.436332, 7.435103 * speedMult)
		Sleep(sleepTime)
	-- Frame:15
	Turn(Hatch, x_axis, -0.058043, 1.741286 * speedMult)
	Turn(LeftClaw, y_axis, 0.736311, 8.999353 * speedMult)
	Turn(RightClaw, y_axis, -0.736311, 8.999353 * speedMult)
		Sleep(sleepTime)
	-- Frame:20
	Turn(Hatch, x_axis, -0.246122, 5.642367 * speedMult)
	Turn(LeftClaw, y_axis, 0.872665, 4.090617 * speedMult)
	Turn(RightClaw, y_axis, -0.872665, 4.090617 * speedMult)
		Sleep(sleepTime)
	-- Frame:22
	Turn(Hatch, x_axis, -0.409396, 4.898225 * speedMult)
		Sleep(sleepTime)
	-- Frame:31
	Turn(Hatch, x_axis, -1.660238, 37.525274 * speedMult)
		Sleep(sleepTime)
	-- Frame:42
	Show(HeldCell)
	Hide(ReloadCell)
	Turn(Hatch, x_axis, -1.912734, 7.574869 * speedMult)
		Sleep(sleepTime)
	-- Frame:45
	Turn(Hatch, x_axis, -1.919862, 0.213844 * speedMult)
	Turn(LeftClaw, y_axis, 0.596548, 8.283495 * speedMult)
	Turn(RightClaw, y_axis, -0.596548, 8.283495 * speedMult)
		Sleep(sleepTime)
	-- Frame:50
	Turn(Hatch, x_axis, -1.919934, 0.002164 * speedMult)
	Turn(LeftClaw, y_axis, -0.000000, 17.896444 * speedMult)
	Turn(RightClaw, y_axis, -0.000000, 17.896444 * speedMult)
		Sleep(sleepTime)
	-- Frame:56
	Turn(Hatch, x_axis, -1.919832, 0.003072 * speedMult)
		Sleep(sleepTime)
	-- Frame:60
	Turn(Hatch, x_axis, -1.919642, 0.005697 * speedMult)
		Sleep(sleepTime)
	-- Frame:72
	Move(Cell1, x_axis, -0.104977, 3.149311 * speedMult)
	Move(Cell1, y_axis, -0.391780, 11.753387 * speedMult)
	Move(Cell4, x_axis, -0.104977, 3.149311 * speedMult)
	Move(Cell4, y_axis, -0.391780, 11.753387 * speedMult)
	Turn(Hatch, x_axis, -1.918431, 0.036321 * speedMult)
		Sleep(sleepTime)
	-- Frame:73
	Move(Cell1, x_axis, -0.121623, 0.499370 * speedMult)
	Move(Cell1, y_axis, -0.453902, 1.863673 * speedMult)
	Move(Cell4, x_axis, -0.121623, 0.499370 * speedMult)
	Move(Cell4, y_axis, -0.453902, 1.863673 * speedMult)
	Turn(Hatch, x_axis, -1.918284, 0.004431 * speedMult)
		Sleep(sleepTime)
	-- Frame:82
	Move(Cell1, x_axis, -0.307604, 5.579427 * speedMult)
	Move(Cell1, y_axis, -1.147992, 20.822704 * speedMult)
	Move(Cell4, x_axis, -0.307604, 5.579427 * speedMult)
	Move(Cell4, y_axis, -1.147992, 20.822704 * speedMult)
	Turn(Hatch, x_axis, -1.916594, 0.050694 * speedMult)
		Sleep(sleepTime)
	-- Frame:88
	Move(Cell1, x_axis, -0.454302, 4.400959 * speedMult)
	Move(Cell1, y_axis, -1.695479, 16.424603 * speedMult)
	Move(Cell4, x_axis, -0.454302, 4.400959 * speedMult)
	Move(Cell4, y_axis, -1.695479, 16.424603 * speedMult)
	Turn(Hatch, x_axis, -1.915077, 0.045508 * speedMult)
		Sleep(sleepTime)
	-- Frame:120
	Move(Cell1, x_axis, -1.009394, 16.652766 * speedMult)
	Move(Cell1, y_axis, -3.767111, 62.148957 * speedMult)
	Move(Cell4, x_axis, -1.009394, 16.652766 * speedMult)
	Move(Cell4, y_axis, -3.767111, 62.148957 * speedMult)
	Turn(Hatch, x_axis, -1.899958, 0.453551 * speedMult)
		Sleep(sleepTime)
	-- Frame:122
	Turn(Hatch, x_axis, -1.898497, 0.043831 * speedMult)
		Sleep(sleepTime)
	-- Frame:130
	Turn(Hatch, x_axis, -1.891811, 0.200579 * speedMult)
		Sleep(sleepTime)
	-- Frame:138
	Turn(Hatch, x_axis, -1.883508, 0.249102 * speedMult)
		Sleep(sleepTime)
	-- Frame:140
	Turn(Hatch, x_axis, -1.881125, 0.071504 * speedMult)
		Sleep(sleepTime)
	-- Frame:162
	Move(Cell2, x_axis, -0.455671, 13.670138 * speedMult)
	Move(Cell2, z_axis, 0.420321, 12.609628 * speedMult)
	Move(Cell2, y_axis, -1.014002, 30.420059 * speedMult)
	Move(Cell5, x_axis, 0.455671, 13.670138 * speedMult)
	Move(Cell5, z_axis, 0.420321, 12.609628 * speedMult)
	Move(Cell5, y_axis, -1.014002, 30.420059 * speedMult)
	Turn(Hatch, x_axis, -1.841617, 1.185232 * speedMult)
		Sleep(sleepTime)
	-- Frame:163
	Move(Cell2, x_axis, -0.490713, 1.051261 * speedMult)
	Move(Cell2, z_axis, 0.452644, 0.969704 * speedMult)
	Move(Cell2, y_axis, -1.091981, 2.339362 * speedMult)
	Move(Cell5, x_axis, 0.490713, 1.051261 * speedMult)
	Move(Cell5, z_axis, 0.452644, 0.969704 * speedMult)
	Move(Cell5, y_axis, -1.091981, 2.339362 * speedMult)
	Turn(Hatch, x_axis, -1.838895, 0.081646 * speedMult)
		Sleep(sleepTime)
	-- Frame:166
	Move(Cell2, x_axis, -0.598996, 3.248486 * speedMult)
	Move(Cell2, z_axis, 0.552527, 2.996473 * speedMult)
	Move(Cell2, y_axis, -1.332942, 7.228832 * speedMult)
	Move(Cell5, x_axis, 0.598996, 3.248486 * speedMult)
	Move(Cell5, z_axis, 0.552527, 2.996473 * speedMult)
	Move(Cell5, y_axis, -1.332942, 7.228832 * speedMult)
	Turn(Hatch, x_axis, -1.829869, 0.270789 * speedMult)
	Move(HeldCell, y_axis, -0.500298, 15.008937 * speedMult)
		Sleep(sleepTime)
	-- Frame:169
	Move(Cell2, x_axis, -0.710269, 3.338199 * speedMult)
	Move(Cell2, z_axis, 0.655168, 3.079230 * speedMult)
	Move(Cell2, y_axis, -1.580558, 7.428474 * speedMult)
	Move(Cell5, x_axis, 0.710269, 3.338199 * speedMult)
	Move(Cell5, z_axis, 0.655168, 3.079230 * speedMult)
	Move(Cell5, y_axis, -1.580558, 7.428474 * speedMult)
	Turn(Hatch, x_axis, -1.819199, 0.320113 * speedMult)
	Move(HeldCell, y_axis, -1.400000, 26.991059 * speedMult)
		Sleep(sleepTime)
	-- Frame:171
	Move(Cell2, x_axis, -0.785006, 2.242084 * speedMult)
	Move(Cell2, z_axis, 0.724106, 2.068144 * speedMult)
	Move(Cell2, y_axis, -1.746867, 4.989295 * speedMult)
	Move(Cell5, x_axis, 0.785006, 2.242084 * speedMult)
	Move(Cell5, z_axis, 0.724106, 2.068144 * speedMult)
	Move(Cell5, y_axis, -1.746867, 4.989295 * speedMult)
	Turn(Hatch, x_axis, -1.810839, 0.250797 * speedMult)
	Move(HeldCell, y_axis, -1.848584, 13.457512 * speedMult)
		Sleep(sleepTime)
	-- Frame:173
	Move(Cell2, x_axis, -0.859409, 2.232116 * speedMult)
	Move(Cell2, z_axis, 0.792738, 2.058949 * speedMult)
	Move(Cell2, y_axis, -1.912438, 4.967104 * speedMult)
	Move(Cell5, x_axis, 0.859409, 2.232116 * speedMult)
	Move(Cell5, z_axis, 0.792738, 2.058949 * speedMult)
	Move(Cell5, y_axis, -1.912438, 4.967104 * speedMult)
	Turn(Hatch, x_axis, -1.801101, 0.292128 * speedMult)
	Move(HeldCell, y_axis, -2.240000, 11.742486 * speedMult)
		Sleep(sleepTime)
	-- Frame:177
	Move(Cell2, x_axis, -1.004562, 4.354570 * speedMult)
	Move(Cell2, z_axis, 0.926629, 4.016753 * speedMult)
	Move(Cell2, y_axis, -2.235444, 9.690195 * speedMult)
	Move(Cell5, x_axis, 1.004562, 4.354570 * speedMult)
	Move(Cell5, z_axis, 0.926629, 4.016753 * speedMult)
	Move(Cell5, y_axis, -2.235444, 9.690195 * speedMult)
	Turn(Hatch, x_axis, -1.774948, 0.784600 * speedMult)
	Move(HeldCell, y_axis, -3.248252, 30.247557 * speedMult)
		Sleep(sleepTime)
	-- Frame:180
	Move(Cell2, x_axis, -1.107611, 3.091482 * speedMult)
	Move(Cell2, z_axis, 1.021684, 2.851651 * speedMult)
	Move(Cell2, y_axis, -2.464759, 6.879458 * speedMult)
	Move(Cell5, x_axis, 1.107611, 3.091482 * speedMult)
	Move(Cell5, z_axis, 1.021684, 2.851651 * speedMult)
	Move(Cell5, y_axis, -2.464759, 6.879458 * speedMult)
	Turn(Hatch, x_axis, -1.745329, 0.888555 * speedMult)
	Move(HeldCell, y_axis, -4.124219, 26.279032 * speedMult)
		Sleep(sleepTime)
	-- Frame:190
	Move(Cell2, x_axis, -1.384514, 8.307084 * speedMult)
	Move(Cell2, z_axis, 1.277105, 7.662628 * speedMult)
	Move(Cell2, y_axis, -3.080949, 18.485692 * speedMult)
	Move(Cell5, x_axis, 1.384514, 8.307084 * speedMult)
	Move(Cell5, z_axis, 1.277105, 7.662628 * speedMult)
	Move(Cell5, y_axis, -3.080949, 18.485692 * speedMult)
	Turn(Hatch, x_axis, -0.920388, 24.748224 * speedMult)
	Move(HeldCell, y_axis, -6.195484, 62.137942 * speedMult)
	Show(FireCell)
	Hide(HeldCell)
		Sleep(sleepTime)
	-- Frame:191
	Move(Cell2, x_axis, -1.404437, 0.597693 * speedMult)
	Move(Cell2, z_axis, 1.295483, 0.551330 * speedMult)
	Move(Cell2, y_axis, -3.125284, 1.330054 * speedMult)
	Move(Cell5, x_axis, 1.404437, 0.597693 * speedMult)
	Move(Cell5, z_axis, 1.295483, 0.551330 * speedMult)
	Move(Cell5, y_axis, -3.125284, 1.330054 * speedMult)
	Turn(Hatch, x_axis, -0.747151, 5.197127 * speedMult)
	Move(HeldCell, y_axis, -6.220000, 0.735469 * speedMult)
		Sleep(sleepTime)
	-- Frame:192
	Move(Cell2, x_axis, -1.422616, 0.545361 * speedMult)
	Move(Cell2, z_axis, 1.312251, 0.503050 * speedMult)
	Move(Cell2, y_axis, -3.165737, 1.213574 * speedMult)
	Move(Cell5, x_axis, 1.422616, 0.545361 * speedMult)
	Move(Cell5, z_axis, 1.312251, 0.503050 * speedMult)
	Move(Cell5, y_axis, -3.165737, 1.213574 * speedMult)
	Turn(Hatch, x_axis, -0.557414, 5.692095 * speedMult)
	Move(HeldCell, y_axis, 0.000000, 186.599994 * speedMult)
		Sleep(sleepTime)
	-- Frame:200
	Move(Cell2, x_axis, -1.495275, 2.179781 * speedMult)
	Move(Cell2, z_axis, 1.379274, 2.010673 * speedMult)
	Move(Cell2, y_axis, -3.327425, 4.850650 * speedMult)
	Move(Cell5, x_axis, 1.495275, 2.179781 * speedMult)
	Move(Cell5, z_axis, 1.379274, 2.010673 * speedMult)
	Move(Cell5, y_axis, -3.327425, 4.850650 * speedMult)
	Turn(Hatch, x_axis, -0.409062, 4.450586 * speedMult)
		Sleep(sleepTime)
	-- Frame:205
	Turn(Hatch, x_axis, -0.352816, 1.687379 * speedMult)
		Sleep(sleepTime)
	-- Frame:212
	Turn(Hatch, x_axis, -0.104720, 7.442875 * speedMult)
		Sleep(sleepTime)
	-- Frame:214
	Turn(Hatch, x_axis, -0.095720, 0.269980 * speedMult)
		Sleep(sleepTime)
	-- Frame:215
	Turn(Hatch, x_axis, -0.066473, 0.877436 * speedMult)
		Sleep(sleepTime)
	-- Frame:220
	Turn(Hatch, x_axis, -0.000000, 1.994176 * speedMult)
	Show(ReloadCell)
		Sleep(sleepTime)
	-- Frame:227
	Move(Cel3, x_axis, -0.057103, 1.713099 * speedMult)
	Move(Cel3, z_axis, 0.089476, 2.684275 * speedMult)
	Move(Cel3, y_axis, -0.101500, 3.045006 * speedMult)
	Move(Cell6, x_axis, 0.057103, 1.713101 * speedMult)
	Move(Cell6, z_axis, 0.089476, 2.684276 * speedMult)
	Move(Cell6, y_axis, -0.101500, 3.045004 * speedMult)
		Sleep(sleepTime)
	-- Frame:242
	Move(Cel3, x_axis, -0.462106, 12.150075 * speedMult)
	Move(Cel3, z_axis, 0.724079, 19.038087 * speedMult)
	Move(Cel3, y_axis, -0.821385, 21.596557 * speedMult)
	Move(Cell6, x_axis, 0.462106, 12.150089 * speedMult)
	Move(Cell6, z_axis, 0.724079, 19.038098 * speedMult)
	Move(Cell6, y_axis, -0.821385, 21.596543 * speedMult)
		Sleep(sleepTime)
	-- Frame:250
	Move(Cel3, x_axis, -0.758195, 8.882675 * speedMult)
	Move(Cel3, z_axis, 1.188024, 13.918363 * speedMult)
	Move(Cel3, y_axis, -1.347679, 15.788811 * speedMult)
	Move(Cell6, x_axis, 0.758196, 8.882684 * speedMult)
	Move(Cell6, z_axis, 1.188025, 13.918369 * speedMult)
	Move(Cell6, y_axis, -1.347678, 15.788798 * speedMult)
		Sleep(sleepTime)
	-- Frame:280
	Move(Cel3, x_axis, -1.516390, 22.745849 * speedMult)
	Move(Cel3, z_axis, 2.376048, 35.640725 * speedMult)
	Move(Cel3, y_axis, -2.695358, 40.430374 * speedMult)
	Move(Cell6, x_axis, 1.516392, 22.745875 * speedMult)
	Move(Cell6, z_axis, 2.376050, 35.640743 * speedMult)
	Move(Cell6, y_axis, -2.695356, 40.430346 * speedMult)
		Sleep(sleepTime)
	reloading = false
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
	xtiltv = xtiltv - cos(lastHeading) / 69
	ztiltv = ztiltv - sin(lastHeading) / 69

	Move (Cannon, z_axis, -8)
	Move (Cannon, z_axis, 0, 13)
	EmitSfx(firepointC, 1024)
	EmitSfx(firepointC, 1025)
	if not reloading then
		reloading = true
		StartThread(Reload)
	end
end

function script.AimWeapon(num, heading, pitch)
	Signal(1)
	SetSignalMask(1)

	Turn(Cannon, y_axis, heading, TURRET_TURN_SPEED)
	Turn(Cannon, x_axis, -pitch, TURRET_PITCH_SPEED)
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

local explodables = {Cannon, Hull, TurretHousing, RWheel1, LWheel2, BackWheels, RWheel2, LWheel1, LWheelGuard, RWheelGuard}
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
