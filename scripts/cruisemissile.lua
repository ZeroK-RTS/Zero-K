include "constants.lua"

local base = piece 'base' 

function script.AimWeapon1(heading, pitch) return true end

local function RemoveMissile()
	Hide(base)
	Sleep(1000)
	Spring.DestroyUnit(unitID, false, true)	--"reclaim the missile"
end

function script.Shot1()
	StartThread(RemoveMissile)
end

function script.AimFromWeapon1() return base end

function script.QueryWeapon1() return base end

function script.Create()
	Turn( base , x_axis, math.rad(-90) )
	Move( base , y_axis,  40)
end

function script.Killed(recentDamage, maxHealth)
	Explode(base, sfxNone)
	return 1
end
