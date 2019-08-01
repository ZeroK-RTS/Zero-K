include 'constants.lua'

local body = piece("body")
local firepoint = piece("firepoint")

function script.Create()
	Turn (body, y_axis, math.random() * 2 * math.pi)
	Turn (body, z_axis, (math.random() - 0.5) * 0.8) -- up to 22 degrees
	EmitSfx(body, 1024+2)
	Move(body, y_axis, -80)
	Move(body, y_axis, 0,30)
end

function script.AimFromWeapon(weaponNum)
	return firepoint
end

function script.AimWeapon(num,_)
	return Spring.GetUnitRulesParam(unitID,"disarmed") ~= 1
end

function script.QueryWeapon(weaponNum)
	return firepoint
end

function script.HitByWeapon()
	EmitSfx(body, 1024)
end

function script.Killed()
	EmitSfx(body, 1025)
	Explode(body, SFX.SHATTER)
end
