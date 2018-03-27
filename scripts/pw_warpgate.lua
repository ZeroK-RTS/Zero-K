include "constants.lua"

local base = piece "base"
local gen1 = piece "gen1"
local gen2 = piece "gen2"

local smokePiece = {gen1}

function script.Create()
	StartThread(SmokeUnit, smokePiece)
end

function script.Activate ()
	if Spring.GetUnitRulesParam(unitID, "planetwarsDisable") ~= 1 then
		Spin(gen1, y_axis, 1, 0.01)
		Spin(gen2, y_axis, -1, 0.01)
	end
end

function script.Deactivate ()
	StopSpin(gen1, y_axis, 0.1)
	StopSpin(gen2, y_axis, 0.1)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(base, sfxNone)
		Explode(gen1, sfxNone)
		Explode(gen2, sfxNone)
		return 1
	else
		Explode(base, sfxShatter)
		Explode(gen1, sfxShatter)
		Explode(gen2, sfxShatter)
		return 2
	end
end