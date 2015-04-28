--by Chris Mackey

local wake1 = piece "wake"
local wake2 = piece "wake2"
local base = piece "base"
local tube1 = piece "tube1"
local tube2 = piece "tube2"

local tube = false

function script.QueryWeapon1()
	if tube then return tube1
	else return tube2 end
end

function script.AimFromWeapon1() return base end

function script.AimWeapon1( heading, pitch )
	return true
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 900.1, 120, true)
end

function script.FireWeapon1()
	tube = not tube
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
	if not submerged then
		local damages = WeaponDefs[weaponDefID].damages
		return damage * (damages[elseArmorClass] / damages[subArmorClass])
	end
	return damage
end

function script.Killed(recentDamage, maxHealth)
	Explode( base, SFX.SHATTER )
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		return 1 -- corpsetype
	elseif (severity <= .5) then
		return 1
	else		
		return 2
	end
end
