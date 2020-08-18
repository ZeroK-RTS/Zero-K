local base = piece "base"
local door1 = piece "door1"
local door2 = piece "door2"
local missile = piece "missile"
local aimpoint = piece "aimpoint"

local smokePiece = {base}

include "constants.lua"

local SIG_AIM = 1

function script.QueryWeapon()
	return missile
end

function script.AimFromWeapon()
	return aimpoint
end

local respawning_rocket = false

local function MoveScript()
	while true do
		if moving and not Spring.GetUnitIsCloaked(unitID) then
			local x,y,z = Spring.GetUnitPosition(unitID);
			if y > criticalHeight then
				EmitSfx(missile, 3)
			end
		end
		Sleep(150)
	end
end

local function RestoreAfterDelay ()
	SetSignalMask (SIG_AIM)
	Sleep (5000)

	while (Spring.GetUnitRulesParam(unitID, "disarmed") == 1) do
		Sleep(100)
	end

	Turn (missile, x_axis, 0, math.rad(30))
	WaitForTurn (missile, x_axis)

	Turn (door1, z_axis, 0, math.rad(20))
	Turn (door2, z_axis, 0, math.rad(20))
end

function script.AimWeapon(num, heading, pitch)
	Signal (SIG_AIM)
	SetSignalMask (SIG_AIM)
	if respawning_rocket then return false end

	while (Spring.GetUnitRulesParam(unitID, "disarmed") == 1) do
		Sleep(100)
	end

	local slowMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
	Turn (door1, z_axis, math.rad(90), math.rad(90)*slowMult)
	Turn (door2, z_axis, math.rad(-90), math.rad(90)*slowMult)
	WaitForTurn (door1, z_axis)
	Turn (missile, x_axis, math.rad(-90), math.rad(180)*slowMult)
	WaitForTurn (missile, x_axis)
	StartThread (RestoreAfterDelay)
	return true
end

function script.FireWeapon()
	respawning_rocket = true
	Signal (SIG_AIM)

	Hide (missile)
	Turn (missile, x_axis, 0)

	local slowMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
	Turn (door1, z_axis, 0, math.rad(80)*slowMult)
	Turn (door2, z_axis, 0, math.rad(80)*slowMult)
	WaitForTurn (door1, z_axis)

	respawning_rocket = false
	Show(missile)
end

function script.StopMoving()
	moving = false
end

function script.StartMoving()
	moving = true
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(MoveScript)
	criticalHeight = -1 * Spring.GetUnitHeight(unitID) + 5
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= 0.25) then
		return 1
	elseif (severity <= 0.50) then
		Explode (door1, SFX.FALL)
		return 1
	elseif (severity <= 0.75) then
		Explode (base, SFX.SHATTER)
		Explode (door1, SFX.FALL)
		return 2
	else
		Explode (base, SFX.SHATTER)
		Explode (door1, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode (door2, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 2
	end
end
