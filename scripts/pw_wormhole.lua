include "constants.lua"

local base = piece('base')
local panel1, panel2 = piece('pannel1', 'pannel2')
local slider1, slider2, focal1, focal2 = piece('slider1', 'slider2', 'focal1', 'focal2')
local wheel1, wheel2 = piece('wheel1', 'wheel2')
local turret, cylinder, cannon, cannonbase = piece('turret', 'cylinder', 'canon', 'canonbase')
local drone = piece('drone')

local spin = math.rad(60)

local function SliderAnim(piece, reverse)
    local dist = 9 * (reverse and -1 or 1)
    while true do
	Move(piece, z_axis, dist, 4)
	WaitForMove(piece, z_axis)
	Move(piece, z_axis, -dist, 4)
	WaitForMove(piece, z_axis)
    end
end

function script.Create()
	if Spring.GetUnitRulesParam(unitID, "planetwarsDisable") == 1 then
		return
	end
	
    Spin(wheel1, x_axis, spin)
    Spin(wheel2, x_axis, spin)
    --StartThread(SliderAnim, slider1)
    --StartThread(SliderAnim, slider2)  
    Spin(focal1, y_axis, spin)
    Spin(focal2, y_axis, -spin)
end

function script.AimFromWeapon(num)
	return drone
end

-- fake weapon, do not fire
function script.AimWeapon(num)
	return false
end

function script.QueryWeapon(num)
	return drone
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < .5 then
		Explode(base, sfxNone)
		Explode(wheel1, sfxNone)
		Explode(wheel2, sfxNone)
		Explode(slider1, sfxNone)
		Explode(slider2, sfxNone)
		--Explode(focal1, sfxFall)
		--Explode(focal2, sfxFall)
		--Explode(panel1, sfxFall)
		--Explode(panel2, sfxFall)
		return 1
	else
		Explode(base, sfxShatter)
		Explode(wheel1, sfxShatter)
		Explode(wheel2, sfxShatter)
		Explode(slider1, sfxFall + sfxSmoke + sfxFire)
		Explode(slider2, sfxFall + sfxSmoke + sfxFire)
		Explode(panel1, sfxFall + sfxSmoke + sfxFire)
		Explode(panel2, sfxFall + sfxSmoke + sfxFire)
		return 2
	end
end