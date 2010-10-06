include "constants.lua"

--pieces
local base = piece "base"
local wingR, wingL, wingtipR, wingtipL = piece("wingr", "wingl", "wingtip1", "wingtip2")
local engineR, engineL, thrust1, thrust2, thrust3 = piece("jetr", "jetl", "thrust1", "thrust2", "thrust3")
local missR, missL = piece("m1", "m2")

local smokePiece = {base, engineL, engineR}

--constants

--variables
local gun = false

--signals
local SIG_Aim = 1

--cob values
local CRASHING = 97

----------------------------------------------------------

function script.Create()
	Turn(thrust1, x_axis, -1.57, 1)
	Turn(thrust2, x_axis, -1.57, 1)
end

function script.StartMoving()
	Turn(engineL, z_axis, -1.57, 1)
	Turn(engineR, z_axis, 1.57, 1)
	Turn(engineL, y_axis, -1.57, 1)
	Turn(engineR, y_axis, 1.57, 1)
end

function script.StopMoving()
	Turn(engineL, z_axis, 0, 1)
	Turn(engineR, z_axis, 0, 1)
	Turn(engineL, y_axis, 0, 1)
	Turn(engineR, y_axis, 0, 1)
end

function script.QueryWeapon1()
	if gun then return missR
	else return missL end
end

function script.AimFromWeapon1() return base end

function script.AimWeapon1(heading, pitch)
	if (GetUnitValue(CRASHING) == 1) then return false end
	return true
end

function script.Shot1()
	gun = not gun
end

function script.BlockShot1()
	return (GetUnitValue(CRASHING) == 1)
end

function script.Killed(recentDamage, maxHealth)
	local severity = (recentDamage/maxHealth) * 100
	if severity < 50 then
		Explode(base, sfxNone)
		Explode(engineL, sfxSmoke)
		Explode(engineR, sfxSmoke)
		Explode(wingL, sfxNone)
		Explode(wingR, sfxNone)
		return 1
	elseif severity < 100 then
		Explode(base, sfxShatter)
		Explode(engineL, sfxSmoke + sfxFire + sfxExplode)
		Explode(engineR, sfxSmoke + sfxFire + sfxExplode)
		Explode(wingL, sfxFall + sfxSmoke)
		Explode(wingR, sfxFall + sfxSmoke)
		return 2
	else
		Explode(base, sfxShatter)
		Explode(engineL, sfxSmoke + sfxFire + sfxExplode)
		Explode(engineR, sfxSmoke + sfxFire + sfxExplode)
		Explode(wingL, sfxSmoke + sfxExplode)
		Explode(wingR, sfxSmoke + sfxExplode)
		return 3
	end
end
