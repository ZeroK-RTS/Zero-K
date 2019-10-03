include 'constants.lua'

local base = piece "base"
local wheel = piece "wheel"
local pumpcylinders = piece "pumpcylinders"
local turret = piece "turret"
local pump1 = piece "pump1"
local pump2 = piece "pump2"
local pump3 = piece "pump3"

local function Initialize()
	Signal(1)
	SetSignalMask(2)

	Spin(wheel, y_axis, 3, 0.1)
	Spin(turret, y_axis, -1, 0.01)

	while (true) do
		Move(pumpcylinders, z_axis, -11, 15)
		Turn(pump1, x_axis, -1.4, 2)
		Turn(pump2, z_axis, -1.4, 2)
		Turn(pump3, z_axis, 1.4, 2)

		WaitForMove(pumpcylinders, z_axis)
		WaitForTurn(pump1, x_axis)
		WaitForTurn(pump2, z_axis)
		WaitForTurn(pump3, z_axis)

		Move(pumpcylinders, z_axis, 0, 15)
		Turn(pump1, x_axis, 0, 2)
		Turn(pump2, z_axis, 0, 2)
		Turn(pump3, z_axis, 0, 2)

		WaitForMove(pumpcylinders, z_axis)
		WaitForTurn(pump1, x_axis)
		WaitForTurn(pump2, z_axis)
		WaitForTurn(pump3, z_axis)
	end
end

local function Deinitialize()
	Signal(2)
	SetSignalMask(1)

	StopSpin(wheel, y_axis, 0.1)
	StopSpin(turret, y_axis, 0.1)
end

function script.Create()
	Turn(pump2, y_axis, -0.523598776)
	Turn(pump3, y_axis, 0.523598776)
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

-- Invulnerability
--function script.HitByWeapon()
--	return 0
--end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(base, SFX.NONE)
		Explode(turret, SFX.NONE)
		Explode(pumpcylinders, SFX.NONE)
		Explode(wheel, SFX.FALL)
		return 1
	else
		Explode(base, SFX.SHATTER)
		Explode(turret, SFX.SHATTER)
		Explode(pumpcylinders, SFX.SHATTER)
		Explode(wheel, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 2
	end
end
