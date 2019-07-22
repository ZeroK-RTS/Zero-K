include "constants.lua"

--pieces
local base, flare = piece('base', 'flare')

local smokePiece = {base}

----------------------------------------------------------

function script.Create()
end

function script.StartMoving()
end

function script.StopMoving()
end

function script.QueryWeapon(num) return flare end

function script.AimFromWeapon(num) return base end

function script.AimWeapon(num, heading, pitch)
	return true
end

function script.Shot(num)
end

function script.Killed(recentDamage, maxHealth)
	local severity = (recentDamage/maxHealth)
	if severity < .5 then
		Explode(base, SFX.NONE)
	elseif severity < 1 then
		Explode(base, SFX.NONE)
	else
		Explode(base, SFX.SHATTER)
	end
end
