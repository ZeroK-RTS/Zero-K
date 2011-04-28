include "constants.lua"

local base = piece "base"
local turret = piece "turret"

smokePiece = {turret}

local function TurnTurret ()
	while ( true ) do
		Move(turret, y_axis, -10, 4)
		WaitForMove(turret, y_axis)
		Sleep(200)
		Move(turret, y_axis, 0, 4)
		WaitForMove(turret, y_axis)
		Turn(turret, y_axis, 1.57079633, 1)
		WaitForTurn(turret, y_axis)

	    Move(turret, y_axis, -10, 4)
	    WaitForMove(turret, y_axis) 
	    Sleep(200)
	    Move(turret, y_axis, 0, 4)
	    WaitForMove(turret, y_axis)
	    Turn(turret, y_axis, 3.14159266, 1)
		WaitForTurn(turret, y_axis)

	    Move(turret, y_axis, -10, 4)
	    WaitForMove(turret, y_axis) 
	    Sleep(200)
	    Move(turret, y_axis, 0, 4)
	    WaitForMove(turret, y_axis)
	    Turn(turret, y_axis, 4.71238899, 1)
		WaitForTurn(turret, y_axis)

	    Move(turret, y_axis, -10, 4)
	    WaitForMove(turret, y_axis) 
	    Sleep(200)
	    Move(turret, y_axis, 0, 4)
	    WaitForMove(turret, y_axis)
	    Turn(turret, y_axis, 6.28318532, 1)
		WaitForTurn(turret, y_axis)
		Turn(turret, y_axis, 0)
	end
end

local function Initialize()
        Signal(1)
        SetSignalMask(2)

        StartThread(TurnTurret)
end

local function Deinitialize()
	Signal(2)
	SetSignalMask(1)
end

function script.Activate ( )
	StartThread(Initialize)
end

function script.Deactivate ( )
	StartThread(Deinitialize)
end
