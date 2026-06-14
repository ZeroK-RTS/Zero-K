-- TODO: CACHE INCLUDE FILE
-- Only Krow and Jugglenaut use this
local hpi = math.pi*0.5

local cos = math.cos
local sin = math.sin
local acos = math.acos
local asin = math.asin

function rotateXaxis(v, angle)
	return {v[1], v[2]*cos(angle) - v[3]*sin(angle), v[3]*cos(angle) + v[2]*sin(angle)}
end

function rotateYaxis(v, angle)
	return {v[1]*cos(angle) + v[3]*sin(angle), v[2], v[3]*cos(angle) - v[1]*sin(angle)}
end

function rotateZaxis(v, angle)
	return {v[1]*cos(angle) - v[2]*sin(angle), v[2]*cos(angle) + v[1]*sin(angle), v[3]}
end

function dot(v1, v2)
	return v1[1]*v2[1] + v1[2]*v2[2] + v1[3]*v2[3]
end

function cross(v1, v2)
	return {v1[2]*v2[3] - v1[3]*v2[2], v1[3]*v2[1] - v1[1]*v2[3], v1[1]*v2[2] - v1[2]*v2[1]}
end

function add(v1, v2)
	return {v1[1]+v2[1], v1[2]+v2[2], v1[3]+v2[3]}
end

function hat(v)
	return mult(1/modulus(v),v)
end

function modulus(v)
	return math.sqrt(v[1]^2 + v[2]^2 + v[3]^2)
end

function mult(s, v)
	return {v[1]*s, v[2]*s, v[3]*s}
end

-- Up is along y axis
-- Front is along z axis

-- Spring tells the turret to point in the direction defined by heading a pitch, in unit worldspace coordinates.
-- This only works out of the box for turrets that are aligned to the horizon (ie almost all of them).
-- Off-axis turrets define their axis of rotation by the normal vector.
-- The radial vector must be perpendicular to the normal vector, and should correspond to the neutral aim position.
-- The right vector must be perpendicular to both normal and radial.

-- First convert heading and pitch to the vector 'aim'.
-- phi is how far the turret should pitch "up" or "down", where these directions are defined by the normal vector.
-- orthagonal is the component of the aim vector that is perpendicular to normal.
-- theta is the angle from the radial vector, in the plane perpendicular to normal, to rotate the turret.

function getTheActuallyCorrectHeadingAndPitch(heading, pitch, normal, radial, right) -- desired up, front and right vector, must be unit
	local aim = {sin(heading)*cos(pitch), sin(pitch), cos(heading)*cos(pitch)}
	local phi = acos(dot(aim, normal)) - hpi
	
	local orthagonal = add(mult(-dot(aim,normal), normal), aim)
	local modOtho = modulus(orthagonal)
	if modOtho <= 0.0001 then
		return 0, -hpi -- Fire straight up
	end
	local xFactor = dot(radial, orthagonal)/modOtho
	local theta = (xFactor >= 1 and 0) or (xFactor <= -1 and math.pi) or acos(xFactor)
	
	if dot(right, aim) < 0 then
		theta = -theta
	end
	
	--Spring.Echo(normal)
	--Spring.Echo((phi+hpi)*180/math.pi)
	return theta, phi
end
