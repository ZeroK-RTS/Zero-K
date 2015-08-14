local sqrt = math.sqrt
local pi = math.pi
local cos = math.cos
local sin = math.sin

local function DistSq(x1,z1,x2,z2)
	return (x1 - x2)*(x1 - x2) + (z1 - z2)*(z1 - z2)
end

local function Mult(b, v)
	return {b*v[1], b*v[2]}
end

local function AbsVal(x, y, z)
	if z then
		return sqrt(x*x + y*y + z*z)
	elseif y then
		return sqrt(x*x + y*y)
	elseif x[3] then
		return sqrt(x[1]*x[1] + x[2]*x[2] + x[3]*x[3])
	else
		return sqrt(x[1]*x[1] + x[2]*x[2])
	end
end

local function Unit(v)
	local mag = AbsVal(v)
	if mag > 0 then
		return {v[1]/mag, v[2]/mag}
	else
		return v
	end
end

local function Norm(b, v)
	local mag = AbsVal(v)
	if mag > 0 then
		return {b*v[1]/mag, b*v[2]/mag}
	else
		return v
	end
end

local function Angle(x,z)
	if not z then
		x,z = x[1], x[2]
	end
	if x == 0 and z == 0 then
		return 0
	end
	local mult = 1/AbsVal(x, z)
	x, z = x*mult, z*mult
	if z > 0 then
		return math.acos(x)
	elseif z < 0 then
		return 2*math.pi - math.acos(x)
	elseif x < 0 then
		return math.pi
	end
	-- x < 0
	return 0
end

-- Spring.GetHeadingFromVector is actually broken at angles close to pi/4 and reflections
local function AngleSpringHeaving(x, z)
	if z then
		return -Spring.GetHeadingFromVector(x, z)/2^15*pi + pi/2
	else
		return -Spring.GetHeadingFromVector(x[1], x[2])/2^15*pi + pi/2
	end
end

local function PolarToCart(mag, dir)
	return {mag*cos(dir), mag*sin(dir)}
end

local function Add(v1, v2)
	return {v1[1] + v2[1], v1[2] + v2[2]}
end

Spring.Utilities.Vector = {
	DistSq = DistSq,
	Mult = Mult,
	AbsVal = AbsVal,
	Unit = Unit,
	Norm = Norm,
	Angle = Angle,
	PolarToCart = PolarToCart,
	Add = Add,
}