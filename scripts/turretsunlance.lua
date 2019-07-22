include "constants.lua"

local spGetUnitRulesParam 	= Spring.GetUnitRulesParam

local base, turret, breech, barrel1, barrel2, flare = piece("base", "turret", "breech", "barrel1", "barrel2", "flare")
local smokePiece = {base, turret}

-- Signal definitions
local SIG_AIM = 1

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(turret, y_axis, heading, math.rad(80))
	Turn(breech, x_axis, 0 - pitch, math.rad(60))
	WaitForTurn(breech, x_axis)
	WaitForTurn(turret, y_axis)
	return (spGetUnitRulesParam(unitID, "lowpower") == 0)	--checks for sufficient energy in grid
end

function script.AimFromWeapon(num) return breech end

function script.QueryWeapon(num)
	return flare
end

local function Recoil()
	EmitSfx(flare, 1024)
	Move(barrel2, z_axis, -6)
	Sleep(300)
	Move(barrel2, z_axis, 0, 4)
end

function script.Shot(num)
	StartThread(Recoil)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, smokePiece)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, SFX.NONE)
		Explode(turret, SFX.NONE)
		Explode(breech, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(base, SFX.NONE)
		Explode(turret, SFX.NONE)
		Explode(breech, SFX.NONE)
		return 1
	elseif severity <= .99 then
		Explode(base, SFX.SHATTER)
		Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(breech, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 2
	else
		Explode(base, SFX.SHATTER)
		Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(breech, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	end
end
