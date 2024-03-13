include "constants.lua"
include "bombers.lua"
include "fixedwingTakeOff.lua"

local base = piece 'likho2024'
local wing1 = piece 'wing_L'
local wing2 = piece 'wing_R'
local drop = piece 'drop'
local wingletL = piece 'extra_L'
local wingletR = piece 'extra_R'
local coolerL = piece 'radiator_L'
local coolerR = piece 'radiator_R'
local hatchL = piece 'hatch_L'
local hatchR = piece 'hatch_R'
local ball = piece 'singu2024'
-- also: wingtip_L, wingtip_R, thrust_L, thrust_R

local smokePiece = {base, coolerL, coolerR}

--Signal
local SIG_move = 1
local SIG_TAKEOFF = 2
local takeoffHeight = UnitDefNames["bomberheavy"].cruiseAltitude

local armed = true
local cooling = false

local function UpdateCooling()
	if not armed and not cooling then
		Turn(hatchL, y_axis, math.rad(-90), 2)
		Turn(hatchR, y_axis, math.rad( 90), 2)
		Move(coolerL, z_axis, 3, 1)
		Move(coolerR, z_axis, 3, 1)
		cooling = true
	end

	if armed and cooling then
		Move(coolerL, z_axis, 0, 2)
		Move(coolerR, z_axis, 0, 2)
		Turn(hatchL, y_axis, math.rad(0), 1)
		Turn(hatchR, y_axis, math.rad(0), 1)
		cooling = false
	end
end

--add spin?

local function Reball()
	local ammoState = Spring.GetUnitRulesParam(unitID, "noammo")
	if ammoState == 0 then
		armed = true

		Show(ball)
		Move(ball, x_axis, 0)
		Move(ball, y_axis, 0)
		Move(ball, z_axis, 0)

		UpdateCooling()
	end
end

local function Stopping()
	Signal(SIG_move)
	SetSignalMask(SIG_move)

	Turn(wingletL, z_axis, math.rad(-30), 3)
	Turn(wingletR, z_axis, math.rad( 30), 3)

	WaitForTurn (wingletL, z_axis)
	WaitForTurn (wingletR, z_axis)

	Turn(wingletL, z_axis, math.rad(-146.3), 2)
	Turn(wingletR, z_axis, math.rad( 146.3), 2)

	Turn(wing1, y_axis, math.rad(-90), 2)
	Turn(wing2, y_axis, math.rad( 90), 2)

	WaitForTurn (wing1, y_axis)
	WaitForTurn (wing2, y_axis)

	Turn(wing1, x_axis, math.rad(6), 2)
	Turn(wing2, x_axis, math.rad(6), 2)

	Reball()
end

local function Moving()
	Signal(SIG_move)
	SetSignalMask(SIG_move)

	Reball()

	Turn(wing1, y_axis, math.rad(0), 2)
	Turn(wing2, y_axis, math.rad(0), 2)
	Turn(wing1, z_axis, math.rad(0), 2)
	Turn(wing2, z_axis, math.rad(0), 2)
	Turn(wing1, x_axis, math.rad(0), 2)
	Turn(wing2, x_axis, math.rad(0), 2)
	Turn(wingletL, z_axis, math.rad(-30), 2)
	Turn(wingletR, z_axis, math.rad( 30), 2)
	WaitForTurn (wingletL, z_axis)
	WaitForTurn (wingletR, z_axis)
	Turn(wingletL, z_axis, math.rad(0), 1)
	Turn(wingletR, z_axis, math.rad(0), 1)
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

local function ShowBallWhenReady()
	Hide(ball)
	while Spring.GetUnitIsBeingBuilt(unitID) do
		Sleep(100)
	end
	Show(ball)
	Spin(ball, y_axis, math.rad(30))
end

function script.Create()
	-- Work around a LUPS ribbon bug. See #5178
	local tip1, tip2 = piece('wingtip_L', 'wingtip_R')
	local speedPerFrame = UnitDef.speed / Game.gameSpeed
	Move(tip1, y_axis, speedPerFrame)
	Move(tip2, y_axis, speedPerFrame)

	local exhaust_L, exhaust_R = piece('thrust_L', 'thrust_R')
	Move(exhaust_L, y_axis, -5)
	Move(exhaust_R, y_axis, -5)
	Turn(exhaust_L, x_axis, math.rad(90))
	Turn(exhaust_R, x_axis, math.rad(90))
	Turn(coolerL, x_axis, math.rad(180))
	Turn(coolerR, x_axis, math.rad(180))

	-- Stopping() but without the waits
	Turn(wingletL, z_axis, math.rad(-146.3))
	Turn(wingletR, z_axis, math.rad( 146.3))
	Turn(wing1, y_axis, math.rad(-90))
	Turn(wing2, y_axis, math.rad( 90))
	Turn(wing1, x_axis, math.rad(6))
	Turn(wing2, x_axis, math.rad(6))

	SetInitialBomberSettings()
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)

	StartThread(ShowBallWhenReady)
end

function script.FireWeapon(num)
	Move(ball, y_axis, 27)
	Move(ball, z_axis, 2)
	Hide(ball)
	armed = false
	UpdateCooling()
	SetUnarmedAI()
	Sleep(50)	-- delay before clearing attack order; else bomb loses target and fails to home
	Reload()
end

function script.AimWeapon(num)
	return true
end

function script.QueryWeapon(num)
	return drop
end

function script.BlockShot(num)
	return (GetUnitValue(COB.CRASHING) == 1) or RearmBlockShot()
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, SFX.NONE)
		Explode(wing1, SFX.NONE)
		Explode(wing2, SFX.NONE)
		return 1
	elseif severity <= .50 or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing") then
		Explode(wing1, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(wing2, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 1
	elseif severity <= .75 then
		Explode(wing1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(wing2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	else
		Explode(wing1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(wing2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	end
end
