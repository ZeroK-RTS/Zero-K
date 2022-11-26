include "constants.lua"
include "plates.lua"

local base, body, bay, side1, door1, side2, door2, plate1, nano1, nanoemit1, plate2, nano2, nanoemit2, padfloor, pad1, pad2, pad3 = piece (
	'base', 'body', 'bay', 'side1', 'door1', 'side2', 'door2', 'plate1', 'nano1', 'nanoemit1', 'plate2', 'nano2', 'nanoemit2', 'padfloor', 'pad1', 'pad2', 'pad3')

local nanoPieces  = { nanoemit1, nanoemit2 }
local smokePiece  = { pad1, nano1, nano2}
local explodables = { body, bay, side1, door1, side2, door2, plate1, nano1, plate2, nano2, padfloor, pad1 }

local function Open ()
	Signal (1)
	SetSignalMask (1)

	Turn(side1, y_axis, 0.611, 0.35)
	Turn(side2, y_axis, -0.611, 0.35)
	WaitForTurn(side1, y_axis)
	
	Turn(door1, y_axis, -1.571, 0.9)
	Turn(door2, y_axis, 1.571, 0.9)
	WaitForTurn(door1, y_axis)

	Move(plate1, z_axis, 8.47, 3.2)
	Turn(side1, y_axis, 0, 0.15)
	Turn(nano1, y_axis, -0.3, 0.35)
	
	Move(plate2, z_axis, 8.47, 3.2)
	Turn(side2, y_axis, 0, 0.15)
	Turn(nano2, y_axis, 0.3, 0.35)
	Sleep(650)

	SetUnitValue(COB.YARD_OPEN, 1)
	SetInBuildDistance(true)
	--SetUnitValue(COB.BUGGER_OFF, 1)
end

local function Close()
	Signal (1)
	SetSignalMask (1)
	
	SetUnitValue(COB.YARD_OPEN, 0)
	--SetUnitValue(COB.BUGGER_OFF, 0)
	SetInBuildDistance(false)

	Move(plate1, z_axis, 0, 3.2)
	Turn(side1, y_axis, 0.611, 0.15)
	Turn(nano1, y_axis, 0, 0.35)
	
	Move(plate2, z_axis, 0, 3.2)
	Turn(side2, y_axis, -0.611, 0.15)
	Turn(nano2, y_axis, 0, 0.35)
	WaitForMove(plate1, z_axis)

	Turn(door1, y_axis, 0, 0.9)
	Turn(door2, y_axis, 0, 0.9)
	WaitForTurn(door1, y_axis)

	Turn(side1, y_axis, 0, 0.35)
	Turn(side2, y_axis, 0, 0.35)
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
	StartThread (GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces (unitID, nanoPieces)
	local buildprogress = select(5, Spring.GetUnitHealth(unitID))
	while buildprogress < 1 do
		Sleep(250)
		buildprogress = select(5, Spring.GetUnitHealth(unitID))
	end
	StartThread(padchange)
end

function script.Activate ()
	StartThread (Open)
end

function script.Deactivate ()
	StartThread (Close)
end

function script.QueryBuildInfo ()
	return pad1
end

function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	for i = 1, #explodables do
		if (severity > math.random()) then Explode(explodables[i], SFX.SMOKE + SFX.FIRE) end
	end

	if (severity <= .5) then
		return 1
	else
		Explode (bay, SFX.SHATTER)
		return 2
	end
end
