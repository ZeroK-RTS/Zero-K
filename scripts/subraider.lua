--by Chris Mackey

local wake = piece "wake"
local base = piece "base"
local firepoint = piece "firepoint"

function script.QueryWeapon(num)
	return firepoint
end
function script.AimFromWeapon(num)
	return base
end

function script.AimWeapon(num, heading, pitch)
	return num == 2
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 240, 25, 0.5) -- Leeway for amph regen
end

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

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, SFX.NONE)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(base, SFX.SHATTER)
		return 1
	else
		Explode(base, SFX.SHATTER)
		return 2
	end
end
