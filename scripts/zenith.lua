include "constants.lua"

local spGetUnitRulesParam 	= Spring.GetUnitRulesParam

local base = piece "base"
local flare = piece "flare"
local firept = piece "firept"

local SOURCE_RANGE = 2000	-- size of the box which the emit point can be randomly placed in

smokePiece = {base}

local function LaserEmit()
	while (GetUnitValue(COB.BUILD_PERCENT_LEFT) ~= 0) do Sleep(400) end
	while true do
		--if (spGetUnitRulesParam(unitID, "lowpower") == 0) then
			EmitSfx(flare, 2049)
		--end
		Sleep(300)
	end
end

function script.Create()
	Move( firept, y_axis, 9001)
	Turn( flare, x_axis, math.rad(-90))
	StartThread(SmokeUnit)
	StartThread(LaserEmit)
end

function script.QueryWeapon(num) 
	return firept
end

function script.AimFromWeapon(num)
	return firept
end

function script.AimWeapon(num, heading, pitch)
	return (num ~= 2) --and (spGetUnitRulesParam(unitID, "lowpower") == 0)
end

function script.FireWeapon(num)
	Move(firept, x_axis, math.random(-SOURCE_RANGE, SOURCE_RANGE))
	Move(firept, z_axis, math.random(-SOURCE_RANGE, SOURCE_RANGE))
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(base, sfxNone)
		return 1
	else
		Explode(base, sfxShatter)
		return 2
	end
end