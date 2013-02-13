include "constants.lua"

--pieces
local base, flare = piece('base', 'flare')

smokePiece = {base}

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
		Explode(base, sfxNone)
	elseif severity < 1 then
		Explode(base, sfxNone)
	else
		Explode(base, sfxShatter)
	end
end
