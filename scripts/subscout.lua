local body = piece "body"
local tail = piece "tail"
local enginel = piece "enginel"
local enginer = piece "enginer"
local wingl = piece "wingl"
local wingr = piece "wingr"

local explodables = {tail, enginel, enginer, wingl, wingr}
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	local brutal = (severity > 0.5)
	local effect = SFX.FALL + (brutal and (SFX.SMOKE + SFX.FIRE) or 0)

	for i = 1, #explodables do
		if math.random() < severity then
			Explode (explodables[i], effect)
		end
	end

	if not brutal then
		return 1
	else
		Explode (body, SFX.SHATTER)
		return 2
	end
end
