include "constants.lua"

local base = piece "base"
local turret = piece "turret"

local smokePiece = {turret}

local function TurnTurret()
	while (true) do
		Move(turret, z_axis, -10, 4)
		WaitForMove(turret, z_axis)
		Sleep(200)
		Move(turret, z_axis, 0, 4)
		WaitForMove(turret, z_axis)
		Turn(turret, y_axis, 1.57079633, 1)
		WaitForTurn(turret, y_axis)

		Move(turret, z_axis, -10, 4)
		WaitForMove(turret, z_axis) 
		Sleep(200)
		Move(turret, z_axis, 0, 4)
		WaitForMove(turret, z_axis)
		Turn(turret, y_axis, 3.14159266, 1)
		WaitForTurn(turret, y_axis)

		Move(turret, z_axis, -10, 4)
		WaitForMove(turret, z_axis) 
		Sleep(200)
		Move(turret, z_axis, 0, 4)
		WaitForMove(turret, z_axis)
		Turn(turret, y_axis, 4.71238899, 1)
		WaitForTurn(turret, y_axis)

		Move(turret, z_axis, -10, 4)
		WaitForMove(turret, z_axis) 
		Sleep(200)
		Move(turret, z_axis, 0, 4)
		WaitForMove(turret, z_axis)
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

function script.Activate()
	if Spring.GetUnitRulesParam(unitID, "planetwarsDisable") == 1 or GG.applyPlanetwarsDisable then
		return
	end
	
	StartThread(Initialize)
end

function script.Deactivate()
	StartThread(Deinitialize)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(base, SFX.NONE)
		Explode(turret, SFX.NONE)
		return 1
	else
		Explode(base, SFX.SHATTER)
		Explode(turret, SFX.SHATTER)
		return 2
	end
end
