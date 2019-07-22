include "constants.lua"

local base = piece "base"
local smoke1 = piece "smoke1"
local smoke2 = piece "smoke2"
local smoke3 = piece "smoke3"

function script.Create()
	Spin (smoke1, y_axis, math.rad(1000))
	StartThread(GG.Script.SmokeUnit, {smoke1, smoke2, smoke2, smoke3, smoke3, smoke3}, 6)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, SFX.NONE)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(base, SFX.NONE)
		return 1 -- corpsetype
	else
		Explode(base, SFX.SHATTER)
		return 2 -- corpsetype
	end
end