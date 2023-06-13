include "constants.lua"

local Root = piece('Root')
local Core = piece('Core')
local CoverL1 = piece('CoverL1')
local CoverL2 = piece('CoverL2')
local CoverL3 = piece('CoverL3')
local CoverMid = piece('CoverMid')
local CoverR1 = piece('CoverR1')
local CoverR2 = piece('CoverR2')
local CoverR3 = piece('CoverR3')
local CraneRoot = piece('CraneRoot')
local CraneWheel = piece('CraneWheel')
local Lid = piece('Lid')
local Nanos = piece('Nanos')
local RailBottom = piece('RailBottom')
local RailTop = piece('RailTop')
local Slider = piece('Slider')
local Train = piece('Train')
local Nano1 = piece('NanoLeft')
local Nano2 = piece('NanoRight')
local nanoPieces = {Nano1,Nano2}
local Nanoframe = piece('Nanoframe')

local open = false
local SIG_OPEN = 1
local SIG_TRAIN = 2

local function GetDisabled()
	return Spring.GetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID,"disarmed") == 1)
end

local function Open()
	if open then
		return
	end
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	open = true
	
	while GetDisabled() do
		Sleep(500)
	end
	
	Turn(CoverL1, y_axis, math.rad(90), math.rad(90))
	Turn(CoverR1, y_axis, math.rad(-90), math.rad(90))
	
	Move(Slider, z_axis, -20, 30)
	
	Turn(Lid, x_axis, math.rad(-45), math.rad(45))
	
	WaitForMove(Slider, z_axis)
	
	while GetDisabled() do
		Sleep(500)
	end
	
	Turn(CraneRoot, x_axis, math.rad(-45), math.rad(90))
	Move(RailTop, y_axis, -11, 35)
	WaitForMove(RailTop, y_axis)
	
	while GetDisabled() do
		Sleep(500)
	end
	
	Move(RailTop, y_axis, -30.2, 35)
	Move(RailBottom, y_axis, -11, 35)
	
	Turn(CoverL2, y_axis, math.rad(45), math.rad(90))
	Turn(CoverR2, y_axis, math.rad(-45), math.rad(90))
	
	Turn(CraneWheel, x_axis, math.rad(45), math.rad(50))
	
	WaitForMove(RailBottom, y_axis)
	
	while GetDisabled() do
		Sleep(500)
	end
	
	Turn(CoverL3, y_axis, math.rad(45), math.rad(90))
	Turn(CoverR3, y_axis, math.rad(-45), math.rad(90))
	
	WaitForTurn(CraneWheel, x_axis)
	
	while GetDisabled() do
		Sleep(500)
	end
	
	-- set values
	SetUnitValue(COB.YARD_OPEN, 1)
	--SetUnitValue(COB.BUGGER_OFF, 1)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	GG.Script.UnstickFactory(unitID)
end

local function Close()
	if not open then
		return
	end
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	open = false

	-- set values
	SetUnitValue(COB.YARD_OPEN, 0)
	--SetUnitValue(COB.BUGGER_OFF, 0)
	SetUnitValue(COB.INBUILDSTANCE, 0)
	
	while GetDisabled() do
		Sleep(500)
	end
	
	Turn(CraneWheel, x_axis, 0, math.rad(90))
	
	Move(Train,y_axis, 0, 20)
	
	Turn(CoverL3, y_axis, 0, math.rad(90))
	Turn(CoverR3, y_axis, 0, math.rad(90))
	
	Move(RailTop, y_axis, -11, 35)
	WaitForMove(RailTop, y_axis)
	
	Move(RailTop, y_axis, 0, 35)
	Move(RailBottom, y_axis, 0, 35)
	
	Turn(CoverL2, y_axis, 0, math.rad(45))
	Turn(CoverR2, y_axis, 0, math.rad(45))
	
	WaitForMove(RailTop, y_axis)
	
	Turn(CraneRoot, x_axis, 0, math.rad(90))
	
	WaitForTurn(CraneRoot, x_axis)
	
	while GetDisabled() do
		Sleep(500)
	end
	
	Turn(CoverL1, y_axis, 0, math.rad(90))
	Turn(CoverR1, y_axis, 0, math.rad(90))
	
	Move(Slider, z_axis, 0, 20)
	Turn(Lid, x_axis, 0, math.rad(45))
end

local function MoveTrain()
	Signal(SIG_TRAIN)
	SetSignalMask(SIG_TRAIN)
	
	while true do
		Move(Train,y_axis, 21, 4)
		WaitForMove(Train, y_axis)
		Move(Train,y_axis, 0, 4)
		WaitForMove(Train, y_axis)
	end
end

local function Test()
	while true do
		Move(Root, z_axis, -10, 15)
		WaitForMove(Root, z_axis)
		Move(Root, z_axis, -60, 15)
		WaitForMove(Root, z_axis)
	end
end

function script.Create()
	Move(Root, z_axis, -0.1)
	
	--Move(Root, z_axis, -40)
	--StartThread(Test)
	
	StartThread(Open)
	
	Spring.SetUnitNanoPieces(unitID, {Nano1, Nano2})
end

function script.StopBuilding()
	Signal(SIG_TRAIN)
	Move(Train,y_axis, 10.5, 4)
end

function script.StartBuilding(heading, pitch)
	StartThread(MoveTrain)
end

function script.Activate()
	StartThread(Open)
end

local firstDeactivate = true
function script.Deactivate()
	if firstDeactivate then
		firstDeactivate = false
		return
	end
	StartThread(Close)
end

function script.QueryBuildInfo()
	return Nanoframe
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= 0.5) then
		Explode(CoverL2, SFX.SHATTER)
		Explode(CoverR2, SFX.SHATTER)
		Explode(Lid, SFX.SHATTER)
		return 1
	end
	Explode(Core, SFX.SMOKE + SFX.SHATTER + SFX.FALL)
	Explode(Slider, SFX.SMOKE + SFX.FALL + SFX.FIRE)
	Explode(RailTop, SFX.SMOKE + SFX.FALL + SFX.FIRE)
	Explode(RailBottom, SFX.SMOKE + SFX.FALL + SFX.FIRE)
	Explode(RailBottom, SFX.SMOKE + SFX.FALL + SFX.FIRE)
	Explode(Nanoframe, SFX.SMOKE + SFX.FALL + SFX.FIRE)

	-- giblets
	Explode(CoverL1, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(CoverR1, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(CoverL2, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(CoverR2, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(CoverL3, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(CoverR3, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(Train, SFX.SMOKE)
	Explode(CraneWheel, SFX.SMOKE)

	return 2
end
            
