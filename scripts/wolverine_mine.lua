local base = piece 'base' 
local flare = piece 'flare' 

function script.Create()
	Spin( flare , y_axis, 9000 )
end

function script.AimFromWeapon(num)
	return flare
end

function script.QueryWeapon(num)
	return flare
end

function script.AimWeapon(num, heading, putch)
	return true
end

function script.FireWeapon(num)
	Sleep(300)
	Spring.DestroyUnit(unitID, true, false)
end

function script.Killed(severity, corpsetype)
	--Explode(base, SFX.SHATTER)
end