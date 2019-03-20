include "constants.lua"

local base = piece "base"
local smokePiece = { base }

function script.Create()
	StartThread(GG.Script.SmokeUnit, smokePiece)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if (severity <= .5) then
		return 1
	else
		Explode(base, SFX.SHATTER)
		return 2
	end
end
