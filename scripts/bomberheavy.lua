include "constants.lua"
include "bombers.lua"
include "fixedwingTakeOff.lua"


local wingtip_L = piece 'wingtip_L'
local wingtip_R = piece 'wingtip_R'
local base = piece 'base'
local wing_L = piece 'wing_L'
local wing_R = piece 'wing_R'
local thrust_L = piece 'thrust_L'
local thrust_R = piece 'thrust_R'
local drop = piece 'drop'
local extra_L = piece 'extra_L'
local extra_R = piece 'extra_R'
local radiator_L = piece 'radiator_L'--model
local radiator_R = piece 'radiator_R'
local rad_L = piece 'rad_L'--empty for fx
local rad_R = piece 'rad_R'
local hatch_L = piece 'hatch_L'
local hatch_R = piece 'hatch_R'
local singu2024 = piece 'singu2024'

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
		Show(radiator_L)
		Show(radiator_R)
		Turn(hatch_L, y_axis, math.rad(-90), 2)
		Turn(hatch_R, y_axis, math.rad(90), 2)
		Move(radiator_L, z_axis, 3, 1)
		Move(radiator_R, z_axis, 3, 1)
		Move(rad_L, z_axis, 3, 1)
		Move(rad_R, z_axis, 3, 1)
		Spin(singu2024, y_axis, 0)
		cooling = 1
	end
	if armed==1 and cooling ==1 then
		Move(radiator_L, z_axis, 0, 2)
		Move(radiator_R, z_axis, 0, 2)
		Move(rad_L, z_axis, -2, 2)
		Move(rad_R, z_axis, -2, 2)
		Turn(hatch_L, y_axis, math.rad(0), 1)
		Turn(hatch_R, y_axis, math.rad(0), 1)
		Spin(singu2024, y_axis, math.rad(30))
		WaitForTurn (hatch_L, y_axis)
		WaitForTurn (hatch_R, y_axis)
		Hide(radiator_L)
		Hide(radiator_R)
		cooling = 0
	end
	
end

--add spin?

local function Resingu2024()	
	local ammoState = Spring.GetUnitRulesParam(unitID, "noammo")
	
	if ammoState==0 then
		armed=1
		
		Show(singu2024)
		--SetPieceScale(singu2024, 1)
		Move(singu2024, x_axis, 0, 0)
		Move(singu2024, y_axis, 0, 0)
		Move(singu2024, z_axis, 0, 0)
		cool()
	end
end

local function LandOld()
	Turn(extra_L, z_axis, math.rad(-30), 3)
	Turn(extra_R, z_axis, math.rad(30), 3)
	
	WaitForTurn (extra_L, z_axis)
	WaitForTurn (extra_R, z_axis)
	
	Turn(extra_L, z_axis, math.rad(-146.3), 2)
	Turn(extra_R, z_axis, math.rad(146.3), 2)
	
	Turn(wing_L, y_axis, math.rad(-90), 2)
	Turn(wing_R, y_axis, math.rad(90), 2)
	
	WaitForTurn (wing_L, y_axis)
	WaitForTurn (wing_R, y_axis)
	
	Turn(wing_L, x_axis, math.rad(6), 2)
	Turn(wing_R, x_axis, math.rad(6), 2)
end

local function Land()
	Turn(extra_L, z_axis, math.rad(-30), 3)
	Turn(extra_R, z_axis, math.rad(30), 3)
	
	WaitForTurn (extra_L, z_axis)
	WaitForTurn (extra_R, z_axis)
	
	Turn(extra_L, z_axis, math.rad(-146.3), 2)
	Turn(extra_R, z_axis, math.rad(146.3), 2)
	
	Move(wing_L, x_axis, -7, 6)
	Move(wing_R, x_axis, 7, 6)
	
	Move(wing_L, y_axis, -9, 8)
	Move(wing_R, y_axis, -9, 8)
	
	WaitForTurn (extra_L, z_axis)
	WaitForTurn (extra_R, z_axis)
	
	Move(extra_L, x_axis, -1, 3)
	Move(extra_R, x_axis, 1, 3)
	
end

local function Stopping()
	Signal(SIG_move)
	SetSignalMask(SIG_move)	
	--LandOld()
	Land()
	
	
	Resingu2024()
	
end

local function FlyOld()
	Turn(wing_L, y_axis, math.rad(0), 2)
	Turn(wing_R, y_axis, math.rad(0), 2)
	Turn(wing_L, z_axis, math.rad(0), 2)
	Turn(wing_R, z_axis, math.rad(0), 2)
	Turn(wing_L, x_axis, math.rad(0), 2)
	Turn(wing_R, x_axis, math.rad(0), 2)
	Turn(extra_L, z_axis, math.rad(-30), 2)
	Turn(extra_R, z_axis, math.rad(30), 2)
	WaitForTurn (extra_L, z_axis)
	WaitForTurn (extra_R, z_axis)
	Turn(extra_L, z_axis, math.rad(0), 1)
	Turn(extra_R, z_axis, math.rad(0), 1)
end

local function Fly()
	Move(wing_L, x_axis, 0, 6)
	Move(wing_R, x_axis, 0, 6)
	Move(wing_L, y_axis, 0, 8)
	Move(wing_R, y_axis, 0, 8)
	
	Move(extra_L, x_axis, 0, 3)
	Move(extra_R, x_axis, 0, 3)
	
	Turn(extra_L, z_axis, math.rad(-30), 2)
	Turn(extra_R, z_axis, math.rad(30), 2)
	WaitForTurn (extra_L, z_axis)
	WaitForTurn (extra_R, z_axis)
	Turn(extra_L, z_axis, math.rad(0), 1)
	Turn(extra_R, z_axis, math.rad(0), 1)
end

local function WingStart()
	Move(wing_L, x_axis, -7, 0)
	Move(wing_R, x_axis, 7, 0)
	Move(wing_L, y_axis, -9, 0)
	Move(wing_R, y_axis, -9, 0)
	
	Turn(extra_L, z_axis, math.rad(-30), 0)
	Turn(extra_R, z_axis, math.rad(30), 0)
	WaitForTurn (extra_L, z_axis)
	WaitForTurn (extra_R, z_axis)
	Turn(extra_L, z_axis, math.rad(-146.3), 0)
	Turn(extra_R, z_axis, math.rad(146.3), 0)
	WaitForTurn (extra_L, z_axis)
	WaitForTurn (extra_R, z_axis)
	Move(extra_L, x_axis, -1, 0)
	Move(extra_R, x_axis, 1, 0)
end

local function WingStartOld()
	Turn(extra_L, z_axis, math.rad(-146.3), 0)
	Turn(extra_R, z_axis, math.rad(146.3), 0)
	
	Turn(wing_L, y_axis, math.rad(-90), 0)
	Turn(wing_R, y_axis, math.rad(90), 0)
	
	WaitForTurn (wing_L, y_axis)
	WaitForTurn (wing_R, y_axis)
	
	Turn(wing_L, x_axis, math.rad(6), 0)
	Turn(wing_R, x_axis, math.rad(6), 0)
end

local function Moving()
	Signal(SIG_move)
	SetSignalMask(SIG_move)
	
	Resingu2024()
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
	Show(singu2024)
end

function script.Create()

	local exhaust_L, exhaust_R = piece('thrust_L', 'thrust_R')
	Move(exhaust_L, y_axis, -5)
	Move(exhaust_R, y_axis, -5)
	
	Turn(exhaust_L, x_axis, math.rad(90))
	Turn(exhaust_R, x_axis, math.rad(90))
	
	Turn(rad_L, x_axis, math.rad(180))
	Turn(rad_R, x_axis, math.rad(180))
	Move(rad_L, z_axis, -2)
	Move(rad_R, z_axis, -2)
	Move(base, y_axis, 30, 60)
	
	WingStart()
	Hide(singu2024)
	Hide(radiator_L)
	Hide(radiator_R)

	SetInitialBomberSettings()
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(built)
	
	Spin(singu2024, y_axis, math.rad(30))
	
end

function script.FireWeapon(num)
	Move(singu2024, y_axis, 27)
	Move(singu2024, z_axis, 2)
	Hide(singu2024)
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
