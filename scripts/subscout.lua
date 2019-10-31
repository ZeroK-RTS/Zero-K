local body = piece "body"
local tail = piece "tail"
local enginel = piece "enginel"
local enginer = piece "enginer"
local wingl = piece "wingl"
local wingr = piece "wingr"

local submerged = true
local subArmorClass = Game.armorTypes.subs
local elseArmorClass = Game.armorTypes["else"]

function script.setSFXoccupy(num)
	if (num == 4) or (num == 0) then
		submerged = false
	else
		submerged = true
	end
end

function script.HitByWeapon (x, z, weaponDefID, damage)
	if weaponDefID < 0 then return damage end
	if not submerged then
		local damages = WeaponDefs[weaponDefID].damages
		return damage * (damages[elseArmorClass] / damages[subArmorClass])
	end
	return damage
end

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
