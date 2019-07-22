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

function getTheActuallyCorrectHeadingAndPitch(heading, pitch, normal, radial, right) -- desired up, front and right vector, must be unit
	local aim = {sin(heading)*cos(pitch), sin(pitch), cos(heading)*cos(pitch)}
	local phi = acos(dot(aim,normal)) - hpi
	
	local orthagonal = add(mult(-dot(aim,normal), normal), aim)
	local modOtho = modulus(orthagonal)
	local theta = (modOtho > 0 and acos(dot(radial,orthagonal)/modOtho)) or hpi
	
	if dot(right,aim) < 0 then
		theta = -theta
	end
	
	--Spring.Echo(normal)
	--Spring.Echo((phi+hpi)*180/math.pi)
	
	return theta, phi
end
