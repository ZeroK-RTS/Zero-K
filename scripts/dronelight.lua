include "constants.lua"

--pieces
local base, fan, barrel, flare, thrust1, thrust2 = piece('base', 'fan', 'barrel', 'flare', 'thrust1', 'thrust2')
local blades = {piece('b1', 'b2', 'b3', 'b4', 'b5', 'b6')}

local smokePiece = {base}

--constants
local rotorSpeed = math.rad(1080)
local rotorAccel = math.rad(240)
--variables


--signals
local SIG_Aim = 1

----------------------------------------------------------

function script.Create()
	for i=1,#blades do
		Turn(blades[i], y_axis, math.rad((i-1)*60))
	end
	Spin(fan, y_axis, rotorSpeed, rotorAccel)
end

function script.StartMoving()
end

function script.StopMoving()
end

function script.QueryWeapon(num) return flare end

function script.AimFromWeapon(num) return base end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	Turn(barrel, y_axis, heading, pivotSpeed)
	Turn(barrel, x_axis, -pitch, pivotSpeed)
	WaitForTurn(barrel, y_axis)
	WaitForTurn(barrel, x_axis)
	return true
end

function script.Shot(num)
end

function script.Killed(recentDamage, maxHealth)
	local severity = (recentDamage/maxHealth)
	if severity < .5 then
		Explode(base, SFX.NONE)
		Explode(barrel, SFX.FALL)
		Explode(fan, SFX.FALL)
	elseif severity < 1 then
		Explode(base, SFX.NONE)
		Explode(barrel, SFX.SMOKE)
		Explode(fan, SFX.SMOKE)
	else
		Explode(base, SFX.SHATTER)
		Explode(barrel, SFX.SMOKE + SFX.EXPLODE)
		Explode(fan, SFX.SMOKE + SFX.EXPLODE)
	end
end
