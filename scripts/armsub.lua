--by Chris Mackey

local tail = piece "tail"
local base = piece "base"
local flare1 = piece "flare1"
local flare2 = piece "flare2"

local function rise()
	Move( base, y_axis, 20 )
	Sleep( 1000 )
	Move( base, y_axis, 0, 5 )
end

function script.Create()
	StartThread( rise )
end

function script.QueryWeapon1() return base end

function script.AimFromWeapon1() return base end

function script.AimWeapon1( heading, pitch ) return true end

function script.FireWeapon1() end

function script.Killed(recentDamage, maxHealth)
	Explode( base, SFX.EXPLODE )
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		return 1 -- corpsetype

	elseif (severity <= .5) then
		return 2 -- corpsetype

	else		
		return 3 -- corpsetype
	end
end
