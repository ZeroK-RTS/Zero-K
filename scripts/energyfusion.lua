include "constants.lua"

function script.Create()
	-- NB: not "cables" because smoke prefers geometry over origin and cables' vertex 0 is at transformer
	StartThread(GG.Script.SmokeUnit, unitID, {piece("cables_smoke", "transformer", "pyramid_tip1", "pyramid_tip2")}, 2)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if (severity <= .5) then
		return 1
	else
		Explode(piece("base"), SFX.SHATTER)
		return 2
	end
end
