include "constants.lua"

local base = piece "base"
local cylinder1 = piece "cylinder1"
local cylinder2 = piece "cylinder2"
local wheel1 = piece "wheel1"
local wheel2 = piece "wheel2"
local wheel3 = piece "wheel3"
local wheel4 = piece "wheel4"

smokePiece = {base, wheel1, wheel2, wheel3, wheel4}

function script.Activate ( )
	Spin(cylinder1, y_axis, 0.4, 0.001)
	Spin(cylinder2, y_axis, -0.4, 0.001)
	Spin(wheel1, z_axis, 0.3, 0.1)
	Spin(wheel2, x_axis, 0.3, 0.1)
	Spin(wheel3, z_axis, -0.3, 0.1)
	Spin(wheel4, x_axis, -0.3, 0.1)
end

function script.Deactivate ( )
	StopSpin(cylinder1, y_axis, 0.01)
	StopSpin(cylinder2, y_axis, 0.01)
	StopSpin(wheel1, z_axis, 0.01)
	StopSpin(wheel2, x_axis, 0.01)
	StopSpin(wheel3, z_axis, 0.01)
	StopSpin(wheel4, x_axis, 0.01)
end
