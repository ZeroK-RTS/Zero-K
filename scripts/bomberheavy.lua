include "constants.lua"
include "bombers.lua"
include "fixedwingTakeOff.lua"


local flare1 = piece 'wingtip_L'
local flare2 = piece 'wingtip_R'
local base = piece 'likho2024'
local wing1 = piece 'wing_L'
local wing2 = piece 'wing_R'
local thrust1 = piece 'thrust_L'
local thrust2 = piece 'thrust_R'
local drop = piece 'drop'
local wingletL = piece 'extra_L'
local wingletR = piece 'extra_R'
local coolerL = piece 'radiator_L'--model
local coolerR = piece 'radiator_R'
local heatL = piece 'rad_L'--empty for fx
local heatR = piece 'rad_R'
local hatchL = piece 'hatch_L'
local hatchR = piece 'hatch_R'
local ball = piece 'singu2024'

local smokePiece = {base}

--Signal
local SIG_move = 1
local SIG_TAKEOFF = 2
local takeoffHeight = UnitDefNames["bomberheavy"].wantedHeight

local armed = 1
local cooling = 0

--unreliable
local function SetPieceScale(pieceID, scale)
	local matrix = {Spring.GetUnitPieceMatrix(unitID, pieceID)}
	matrix[ 1] = scale
	matrix[ 6] = scale
	matrix[11] = scale
	Spring.SetUnitPieceMatrix(unitID, pieceID, matrix)
end

local function cool()
	if armed==0 and cooling==0 then
		Show(coolerL)
		Show(coolerR)
		Turn(hatchL, y_axis, math.rad(-90), 2)
		Turn(hatchR, y_axis, math.rad(90), 2)
		Move(coolerL, z_axis, 3, 1)
		Move(coolerR, z_axis, 3, 1)
		Move(heatL, z_axis, 3, 1)
		Move(heatR, z_axis, 3, 1)
		Spin(ball, y_axis, 0)
		cooling = 1
	end
	if armed==1 and cooling ==1 then
		Move(coolerL, z_axis, 0, 2)
		Move(coolerR, z_axis, 0, 2)
		Move(heatL, z_axis, -2, 2)
		Move(heatR, z_axis, -2, 2)
		Turn(hatchL, y_axis, math.rad(0), 1)
		Turn(hatchR, y_axis, math.rad(0), 1)
		Spin(ball, y_axis, math.rad(30))
		WaitForTurn (hatchL, y_axis)
		WaitForTurn (hatchR, y_axis)
		Hide(coolerL)
		Hide(coolerR)
		cooling = 0
	end
	
end

--add spin?

local function Reball()	
	local ammoState = Spring.GetUnitRulesParam(unitID, "noammo")
	
	if ammoState==0 then
		armed=1
		
		Show(ball)
		--SetPieceScale(ball, 1)
		Move(ball, x_axis, 0, 0)
		Move(ball, y_axis, 0, 0)
		Move(ball, z_axis, 0, 0)
		cool()
	end
end

local function LandOld()
	Turn(wingletL, z_axis, math.rad(-30), 3)
	Turn(wingletR, z_axis, math.rad(30), 3)
	
	WaitForTurn (wingletL, z_axis)
	WaitForTurn (wingletR, z_axis)
	
	Turn(wingletL, z_axis, math.rad(-146.3), 2)
	Turn(wingletR, z_axis, math.rad(146.3), 2)
	
	Turn(wing1, y_axis, math.rad(-90), 2)
	Turn(wing2, y_axis, math.rad(90), 2)
	
	WaitForTurn (wing1, y_axis)
	WaitForTurn (wing2, y_axis)
	
	Turn(wing1, x_axis, math.rad(6), 2)
	Turn(wing2, x_axis, math.rad(6), 2)
end

local function Land()
	Turn(wingletL, z_axis, math.rad(-30), 3)
	Turn(wingletR, z_axis, math.rad(30), 3)
	
	WaitForTurn (wingletL, z_axis)
	WaitForTurn (wingletR, z_axis)
	
	Turn(wingletL, z_axis, math.rad(-146.3), 2)
	Turn(wingletR, z_axis, math.rad(146.3), 2)
	
	Move(wing1, x_axis, -7, 6)
	Move(wing2, x_axis, 7, 6)
	
	Move(wing1, y_axis, -9, 8)
	Move(wing2, y_axis, -9, 8)
	
	WaitForTurn (wingletL, z_axis)
	WaitForTurn (wingletR, z_axis)
	
	Move(wingletL, x_axis, -1, 3)
	Move(wingletR, x_axis, 1, 3)
	
end

local function Stopping()
	Signal(SIG_move)
	SetSignalMask(SIG_move)	
	--LandOld()
	Land()
	
	
	Reball()
	
end

local function FlyOld()
	Turn(wing1, y_axis, math.rad(0), 2)
	Turn(wing2, y_axis, math.rad(0), 2)
	Turn(wing1, z_axis, math.rad(0), 2)
	Turn(wing2, z_axis, math.rad(0), 2)
	Turn(wing1, x_axis, math.rad(0), 2)
	Turn(wing2, x_axis, math.rad(0), 2)
	Turn(wingletL, z_axis, math.rad(-30), 2)
	Turn(wingletR, z_axis, math.rad(30), 2)
	WaitForTurn (wingletL, z_axis)
	WaitForTurn (wingletR, z_axis)
	Turn(wingletL, z_axis, math.rad(0), 1)
	Turn(wingletR, z_axis, math.rad(0), 1)
end

local function Fly()
	Move(wing1, x_axis, 0, 6)
	Move(wing2, x_axis, 0, 6)
	Move(wing1, y_axis, 0, 8)
	Move(wing2, y_axis, 0, 8)
	
	Move(wingletL, x_axis, 0, 3)
	Move(wingletR, x_axis, 0, 3)
	
	Turn(wingletL, z_axis, math.rad(-30), 2)
	Turn(wingletR, z_axis, math.rad(30), 2)
	WaitForTurn (wingletL, z_axis)
	WaitForTurn (wingletR, z_axis)
	Turn(wingletL, z_axis, math.rad(0), 1)
	Turn(wingletR, z_axis, math.rad(0), 1)
end

local function WingStart()
	Move(wing1, x_axis, -7, 0)
	Move(wing2, x_axis, 7, 0)
	Move(wing1, y_axis, -9, 0)
	Move(wing2, y_axis, -9, 0)
	
	Turn(wingletL, z_axis, math.rad(-30), 0)
	Turn(wingletR, z_axis, math.rad(30), 0)
	WaitForTurn (wingletL, z_axis)
	WaitForTurn (wingletR, z_axis)
	Turn(wingletL, z_axis, math.rad(-146.3), 0)
	Turn(wingletR, z_axis, math.rad(146.3), 0)
	WaitForTurn (wingletL, z_axis)
	WaitForTurn (wingletR, z_axis)
	Move(wingletL, x_axis, -1, 0)
	Move(wingletR, x_axis, 1, 0)
end

local function WingStartOld()
	Turn(wingletL, z_axis, math.rad(-146.3), 0)
	Turn(wingletR, z_axis, math.rad(146.3), 0)
	
	Turn(wing1, y_axis, math.rad(-90), 0)
	Turn(wing2, y_axis, math.rad(90), 0)
	
	WaitForTurn (wing1, y_axis)
	WaitForTurn (wing2, y_axis)
	
	Turn(wing1, x_axis, math.rad(6), 0)
	Turn(wing2, x_axis, math.rad(6), 0)
end

local function Moving()
	Signal(SIG_move)
	SetSignalMask(SIG_move)
	
	Reball()
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

local function built()
	local stunned_or_inbuild = Spring.GetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID, "disarmed") == 1)
	while stunned_or_inbuild do
		Sleep(100)
		stunned_or_inbuild = Spring.GetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID, "disarmed") == 1)
	end
	Show(ball)
end

function script.Create()

	local exhaust_L, exhaust_R = piece('thrust_L', 'thrust_R')
	Move(exhaust_L, y_axis, -5)
	Move(exhaust_R, y_axis, -5)
	
	Turn(exhaust_L, x_axis, math.rad(90))
	Turn(exhaust_R, x_axis, math.rad(90))
	
	Turn(heatL, x_axis, math.rad(180))
	Turn(heatR, x_axis, math.rad(180))
	Move(heatL, z_axis, -2)
	Move(heatR, z_axis, -2)
			
	
	WingStart()
	Hide(ball)
	Hide(coolerL)
	Hide(coolerR)

	SetInitialBomberSettings()
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(built)
	
	Spin(ball, y_axis, math.rad(30))
	
end

function script.FireWeapon(num)
	Move(ball, y_axis, 27)
	Move(ball, z_axis, 2)
	Hide(ball)
	armed=0
	cool()
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
