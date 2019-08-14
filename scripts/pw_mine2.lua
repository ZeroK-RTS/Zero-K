include "constants.lua"

local base = piece "base"
local cylinder1 = piece "cylinder1"
local cylinder2 = piece "cylinder2"
local wheel1 = piece "wheel1"
local wheel2 = piece "wheel2"
local wheel3 = piece "wheel3"
local wheel4 = piece "wheel4"

local wheels = {wheel1, wheel2, wheel3, wheel4}

local smokePiece = {base, wheel1, wheel2, wheel3, wheel4}

function script.Activate()
	if Spring.GetUnitRulesParam(unitID, "planetwarsDisable") == 1 or GG.applyPlanetwarsDisable then
		return
	end
	
	Spin(cylinder1, y_axis, 0.4, 0.001)
	Spin(cylinder2, y_axis, -0.4, 0.001)
	Spin(wheel1, z_axis, 0.3, 0.1)
	Spin(wheel2, x_axis, 0.3, 0.1)
	Spin(wheel3, z_axis, -0.3, 0.1)
	Spin(wheel4, x_axis, -0.3, 0.1)
end

function script.Deactivate()
	StopSpin(cylinder1, y_axis, 0.01)
	StopSpin(cylinder2, y_axis, 0.01)
	StopSpin(wheel1, z_axis, 0.01)
	StopSpin(wheel2, x_axis, 0.01)
	StopSpin(wheel3, z_axis, 0.01)
	StopSpin(wheel4, x_axis, 0.01)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(base, SFX.NONE)
		Explode(cylinder1, SFX.NONE)
		Explode(cylinder2, SFX.NONE)
		for i=1,#wheels do
			Explode(wheels[i], SFX.NONE)
		end
		return 1
	else
		Explode(base, SFX.SHATTER)
		Explode(cylinder1, SFX.SHATTER)
		Explode(cylinder2, SFX.SHATTER)
		for i=1,#wheels do
			Explode(wheels[i], SFX.SHATTER)
		end
		return 2
	end
end
