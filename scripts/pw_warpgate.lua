include "constants.lua"

local base = piece "base"
local gen1 = piece "gen1"
local gen2 = piece "gen2"

local smokePiece = {gen1}

function script.Create()
	StartThread(GG.Script.SmokeUnit, smokePiece)
end

function script.Activate ()
	if (Spring.GetUnitRulesParam(unitID, "planetwarsDisable") ~= 1) and not GG.applyPlanetwarsDisable then
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
		Explode(base, SFX.NONE)
		Explode(gen1, SFX.NONE)
		Explode(gen2, SFX.NONE)
		return 1
	else
		Explode(base, SFX.SHATTER)
		Explode(gen1, SFX.SHATTER)
		Explode(gen2, SFX.SHATTER)
		return 2
	end
end