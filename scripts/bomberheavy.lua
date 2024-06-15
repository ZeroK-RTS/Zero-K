include "constants.lua"
include "bombers.lua"
include "fixedwingTakeOff.lua"


local base       = piece 'base'
local wing_L     = piece 'wing_L'
local wing_R     = piece 'wing_R'
local drop       = piece 'drop'
local ball_emit  = piece 'ball_emit'
local extra_L    = piece 'extra_L'
local extra_R    = piece 'extra_R'
local radiator_L = piece 'radiator_L'
local radiator_R = piece 'radiator_R'
local rad_L      = piece 'rad_L' -- empty piece for fx
local rad_R      = piece 'rad_R'
local hatch_L    = piece 'hatch_L'
local hatch_R    = piece 'hatch_R'
local ball       = piece 'ball'
local thrust_L, thrust_R = piece('thrust_L', 'thrust_R')
local wingtip_L, wingtip_R = piece('wingtip_L', 'wingtip_R')

local smokePiece = {base, radiator_L, radiator_R}

--Signal
local SIG_move = 1
local SIG_TAKEOFF = 2
local takeoffHeight = UnitDefNames["bomberheavy"].cruiseAltitude

local function ShowBall()
	Show(ball)
	
	Move(radiator_L, z_axis, 0, 2)
	Move(radiator_R, z_axis, 0, 2)
	Move(rad_L, z_axis, -2, 2)
	Move(rad_R, z_axis, -2, 2)
	Turn(hatch_L, y_axis, math.rad(0), 1)
	Turn(hatch_R, y_axis, math.rad(0), 1)
	Spin(ball_emit, y_axis, math.rad(30))
	
	local spSetUnitPieceMatrix = Spring.SetUnitPieceMatrix
	local newTable = {1, 0, 0, 0,    0, 1, 0, 0,     0, 0, 1, 0,      0, 0, 0, 1}
	for i = 1, 15 do
		local scale = math.sin(i / 15 * 1.602)
		newTable[1] = scale
		newTable[6] = scale
		newTable[11] = scale
		spSetUnitPieceMatrix(unitID, ball, newTable)
		Sleep(33)
	end
	
	WaitForTurn (hatch_L, y_axis)
	WaitForTurn (hatch_R, y_axis)
	Hide(radiator_L)
	Hide(radiator_R)
end

local function HideBall()
	Hide(ball)
	Spring.SetUnitPieceMatrix(unitID, ball, {0, 0, 0})
	Turn(ball_emit, y_axis, 0)
	Spin(ball_emit, y_axis, 0)
	Move(ball, y_axis, 27)
	Move(ball, z_axis, 1)
	
	Show(radiator_L)
	Show(radiator_R)
	Turn(hatch_L, y_axis, math.rad(-90), 2)
	Turn(hatch_R, y_axis, math.rad( 90), 2)
	Move(radiator_L, z_axis, 3, 1)
	Move(radiator_R, z_axis, 3, 1)
	Move(rad_L, z_axis, 3, 1)
	Move(rad_R, z_axis, 3, 1)
end

--add spin?

function ReammoComplete()
	StartThread(ShowBall)
end

local function Land()
	Turn(extra_L, z_axis, math.rad(-30), 3)
	Turn(extra_R, z_axis, math.rad( 30), 3)

	WaitForTurn (extra_L, z_axis)
	WaitForTurn (extra_R, z_axis)

	Turn(extra_L, z_axis, math.rad(-146.3), 2)
	Turn(extra_R, z_axis, math.rad( 146.3), 2)

	Move(wing_L, x_axis, -7, 6)
	Move(wing_R, x_axis,  7, 6)

	Move(wing_L, y_axis, -9, 8)
	Move(wing_R, y_axis, -9, 8)

	WaitForTurn (extra_L, z_axis)
	WaitForTurn (extra_R, z_axis)

	Move(extra_L, x_axis, -1, 3)
	Move(extra_R, x_axis,  1, 3)
end

local function Stopping()
	Signal(SIG_move)
	SetSignalMask(SIG_move)
	Land()
end

local function Fly()
	Move(wing_L, x_axis, 0, 6)
	Move(wing_R, x_axis, 0, 6)
	Move(wing_L, y_axis, 0, 8)
	Move(wing_R, y_axis, 0, 8)

	Move(extra_L, x_axis, 0, 3)
	Move(extra_R, x_axis, 0, 3)
	Turn(extra_L, z_axis, math.rad(-30), 2)
	Turn(extra_R, z_axis, math.rad( 30), 2)
	WaitForTurn (extra_L, z_axis)
	WaitForTurn (extra_R, z_axis)

	Turn(extra_L, z_axis, math.rad(0), 1)
	Turn(extra_R, z_axis, math.rad(0), 1)
end

local function WingStart()
	Move(wing_L, x_axis, -7, 0)
	Move(wing_R, x_axis,  7, 0)
	Move(wing_L, y_axis, -9, 0)
	Move(wing_R, y_axis, -9, 0)

	Turn(extra_L, z_axis, math.rad(-30), 0)
	Turn(extra_R, z_axis, math.rad( 30), 0)
	WaitForTurn (extra_L, z_axis)
	WaitForTurn (extra_R, z_axis)

	Turn(extra_L, z_axis, math.rad(-146.3), 0)
	Turn(extra_R, z_axis, math.rad( 146.3), 0)
	WaitForTurn (extra_L, z_axis)
	WaitForTurn (extra_R, z_axis)

	Move(extra_L, x_axis, -1, 0)
	Move(extra_R, x_axis,  1, 0)
end

local function WingStartOld()
	Turn(extra_L, z_axis, math.rad(-146.3), 0)
	Turn(extra_R, z_axis, math.rad( 146.3), 0)

	Turn(wing_L, y_axis, math.rad(-90), 0)
	Turn(wing_R, y_axis, math.rad( 90), 0)

	WaitForTurn (wing_L, y_axis)
	WaitForTurn (wing_R, y_axis)

	Turn(wing_L, x_axis, math.rad(6), 0)
	Turn(wing_R, x_axis, math.rad(6), 0)
end

local function Moving()
	Signal(SIG_move)
	SetSignalMask(SIG_move)
	Fly()
end

function script.StartMoving()
	StartThread(Moving)
end

function script.StopMoving()
	StartThread(Stopping)
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
end

function script.MoveRate(rate)
	if rate == 1 then
		Turn(base, z_axis, math.rad(-240), math.rad(120))
		WaitForTurn(base, z_axis)
		Turn(base, z_axis, math.rad(-120), math.rad(180))
		WaitForTurn(base, z_axis)
		Turn(base, z_axis, 0, math.rad(120))
	end
end

local function ShowBallWhenConstructionFinished()
	local stunned_or_inbuild = Spring.GetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID, "disarmed") == 1)
	while stunned_or_inbuild do
		Sleep(100)
		stunned_or_inbuild = Spring.GetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID, "disarmed") == 1)
	end
	ShowBall()
end

function script.Create()
	Move(thrust_L, y_axis, -5)
	Move(thrust_R, y_axis, -5)
	Move(wingtip_L, y_axis, 5)
	Move(wingtip_R, y_axis, 5)

	Turn(thrust_L, x_axis, math.rad(90))
	Turn(thrust_R, x_axis, math.rad(90))

	Turn(rad_L, x_axis, math.rad(180))
	Turn(rad_R, x_axis, math.rad(180))
	Move(rad_L, z_axis, -2)
	Move(rad_R, z_axis, -2)

	WingStart()
	Hide(ball)
	Hide(radiator_L)
	Hide(radiator_R)

	SetInitialBomberSettings()
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)

	StartThread(ShowBallWhenConstructionFinished)
	Spin(ball, y_axis, math.rad(30))
end

function script.FireWeapon(num)
	HideBall()
	SetUnarmedAI()
	Sleep(50) -- delay before clearing attack order; else bomb loses target and fails to home
	Reload()
end

function script.AimWeapon(num)
	return true
end

function script.QueryWeapon(num)
	return ball_emit
end

function script.AimFromWeapon(num)
	return drop
end

function script.BlockShot(num)
	return (GetUnitValue(COB.CRASHING) == 1) or RearmBlockShot()
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, SFX.NONE)
		Explode(wing_L, SFX.NONE)
		Explode(wing_R, SFX.NONE)
		return 1
	elseif severity <= .50 or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing") then
		Explode(wing_L, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(wing_R, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 1
	elseif severity <= .75 then
		Explode(wing_L, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(wing_R, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	else
		Explode(wing_L, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(wing_R, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	end
end