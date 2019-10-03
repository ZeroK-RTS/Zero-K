include "constants.lua"

local base = piece "base"
local wheel = piece "wheel"

function script.Activate ()
		Spin(wheel, y_axis, 3, 0.1)
end

function script.Deactivate ()
	StopSpin(wheel, y_axis, 0.1)
end

local smokePiece = {wheel}

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, SFX.NONE)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(base, SFX.SHATTER)
		return 1 -- corpsetype
	else
		Explode(base, SFX.SHATTER)
		return 2 -- corpsetype
	end
end
