include "constants.lua"

local spGetUnitTeam = Spring.GetUnitTeam

--pieces
local base = piece "base"

local bay = piece "bay"
local narm1 = piece "narm1"
local nano1 = piece "nano1"
local emit1 = piece "emit1"
local arm1b = piece "arm1b"
local arm1 = piece "arm1"
local arm1top = piece "arm1top"
local arm1bot = piece "arm1bot"
local pow1 = piece "pow1"
local pow2 = piece "pow2"
local plate = piece "plate"
local nano2 = piece "nano2"
local emit2 = piece "emit2"
local door1 = piece "door1"
local door2 = piece "door2"
local fuelpad = piece "fuelpad"
local padbase = piece "padbase"
local pad1 = piece "pad1"
local pad2 = piece "pad2"
local pad3 = piece "pad3"
local build = piece "build"
local land = piece "land"

--local vars
local nanoPieces = {emit1,emit2}
local smokePiece = { piece "bay", piece "pad1", piece "fuelpad" }

--opening animation
local function Open()
	Signal(1) --kill the closing animation if it is in process
	SetSignalMask(1) --set the signal to kill the opening animation

	Move(bay, 1, -18, 15)

	Turn(narm1, 1, 1.85, 0.75)
	Turn(nano1, 1, -1.309, 0.35)
	Turn(door1, 2, -0.611, 0.35)
	Sleep(600)
	Move(arm1b, 1, -11, 5)
	Turn(pow1, 3, -1.571, 0.8)
	
	WaitForTurn(door1, 2)

	Turn(door2, 2, 1.571, 0.9)
	Turn(arm1, 1, 1.3, 0.35)
	Turn(arm1top, 1, -0.873, 0.4)
	Turn(arm1bot, 1, 1.31, 0.5)
	Sleep(200)
	Turn(pow2, 1, 1.571, 1)
	
	WaitForTurn(door2, 2)

	Turn(narm1, 1, 1.466, 0.15)
	Move(plate, 3, 8.47, 3.2)
	Turn(door1, 2, 0, 0.15)
	Turn(nano2, 2, 0.698, 0.35)
		Sleep(500)
		Turn(arm1, 1, 0.524, 0.2)
		
	Sleep(150)

--	SetUnitValue(COB.YARD_OPEN, 1) --Tobi said its not necessary
	--SetUnitValue(COB.BUGGER_OFF, 1)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	GG.Script.UnstickFactory(unitID)
end

--closing animation of the factory
local function Close()
	Signal(1) --kill the opening animation if it is in process
	SetSignalMask(1) --set the signal to kill the closing animation

--	SetUnitValue(COB.YARD_OPEN, 0)
	--SetUnitValue(COB.BUGGER_OFF, 0)
	SetUnitValue(COB.INBUILDSTANCE, 0)

	Turn(narm1, 1, 1.85, 0.25)
	Sleep(800)
	Turn(arm1, 1, 1, 0.45)
	Move(plate, 3, 0, 3.2)
	Turn(door1, 2, -0.611, 0.15)
	Turn(nano2, 2, 0, 0.35)

	WaitForMove(plate, 3)

	Turn(arm1top, 1, 0, 0.4)
	Turn(arm1bot, 1, 0, 0.5)
	Turn(pow2, 1, 0, 1)
	Sleep(200)
	Turn(arm1, 1, 0, 0.3)
	Turn(door2, 2, 0, 0.9)

	WaitForTurn(door2, 2)

	Move(arm1b, 1, 0, 5)
	Turn(pow1, 3, 0, 1)
	Sleep(600)
	Turn(narm1, 1, 0, 0.75)
	Turn(nano1, 1, 0, 0.35)
	Turn(door1, 2, 0, 0.35)
	
	WaitForTurn(door1, 2)

	Move(bay, 1, 0, 11)
	WaitForMove(bay,1)
end

local function padchange()
	while true do
		Sleep(1200)
		Hide(pad1)
		Show(pad2)
		Sleep(1200)
		Hide(pad2)
		Show(pad3)
		Sleep(1200)
		Hide(pad3)
		Show(pad2)
		Sleep(1200)
		Hide(pad2)
		Show(pad1)
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	local buildprogress = select(5, Spring.GetUnitHealth(unitID))
	while buildprogress < 1 do
		Sleep(250)
		buildprogress = select(5, Spring.GetUnitHealth(unitID))
	end
	StartThread(padchange)
end

function script.QueryBuildInfo()
	return build
end

function script.QueryLandingPads()
	return { land }
end

function script.Activate ()
	StartThread(Open) --animation needs its own thread because Sleep and WaitForTurn will not work otherwise
end

function script.Deactivate ()
	StartThread(Close)
end

--death and wrecks
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		Explode(pad1, SFX.EXPLODE)

		Explode(fuelpad, SFX.EXPLODE_ON_HIT)
		Explode(nano1, SFX.EXPLODE_ON_HIT)
		Explode(nano2, SFX.EXPLODE_ON_HIT)

		Explode(door1, SFX.EXPLODE_ON_HIT)
		Explode(door2, SFX.EXPLODE_ON_HIT)

		return 1 -- corpsetype

	elseif (severity <= .5) then
		Explode(base, SFX.SHATTER)

		Explode(pad1, SFX.EXPLODE)

		Explode(fuelpad, SFX.EXPLODE_ON_HIT)
		Explode(nano1, SFX.EXPLODE_ON_HIT)
		Explode(nano2, SFX.EXPLODE_ON_HIT)

		Explode(door1, SFX.EXPLODE_ON_HIT)
		Explode(door2, SFX.EXPLODE_ON_HIT)

		return 1 -- corpsetype
	else
		Explode(base, SFX.SHATTER)
		Explode(bay, SFX.SHATTER)
		Explode(door1, SFX.SHATTER)
		Explode(door2, SFX.SHATTER)
		Explode(fuelpad, SFX.SHATTER)

		Explode(pad1, SFX.EXPLODE)

		Explode(nano1, SFX.EXPLODE_ON_HIT)
		Explode(nano2, SFX.EXPLODE_ON_HIT)

		return 2 -- corpsetype
	end
end
