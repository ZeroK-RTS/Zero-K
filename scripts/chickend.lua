include 'constants.lua'

local body = piece("body")
local firepoint = piece("firepoint")

function script.Create()
	Turn (body, y_axis, math.random() * math.pi * 2)
	EmitSfx(body, 1024 + 2)
	Move(body, y_axis, -50)
	Move(body, y_axis, 0, 40)
end

function script.AimFromWeapon()
	return firepoint
end

function script.AimWeapon()
	return true
end

function script.QueryWeapon()
	return firepoint
end

function script.HitByWeapon()
	EmitSfx(body, 1024)
end

function script.Killed()
	EmitSfx(body, 1024 + 1)
	Explode(body, SFX.SHATTER)
end
