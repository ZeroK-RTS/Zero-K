local sqrt = math.sqrt
local pi = math.pi
local cos = math.cos
local sin = math.sin
local atan2 = math.atan2

local function New3(x,y,z)
	return {x, z}, y
end

local function DistSq(x1,z1,x2,z2)
	return (x1 - x2)*(x1 - x2) + (z1 - z2)*(z1 - z2)
end

local function Dist3D(x1,y1,z1,x2,y2,z2)
	return sqrt((x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2) + (z1 - z2)*(z1 - z2))
end

local function Mult(b, v)
	return {b*v[1], b*v[2]}
end

local function Add(v1, v2)
	return {v1[1] + v2[1], v1[2] + v2[2]}
end

local function Subtract(v1, v2)
	return {v1[1] - v2[1], v1[2] - v2[2]}
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

local function Negative(v)
	return {-v[1], -v[2]}
end

local function Mag(v)
	return sqrt(v[1] * v[1] + v[2] * v[2])
end

local function Unit(v)
	local mag = AbsVal(v)
	if mag > 0 then
		return {v[1]/mag, v[2]/mag}
	else
		return v
	end
end

local function Clone(v)
	return {v[1], v[2]}
end

local function Norm(b, v)
	local mag = AbsVal(v)
	if mag > 0 then
		return {b*v[1]/mag, b*v[2]/mag}
	else
		return v
	end
end

local function Angle(x, z)
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

local function Dot(v1, v2)
	if v1[3] then
		return v1[1]*v2[1] + v1[2]*v2[2] + v1[3]*v2[3]
	else
		return v1[1]*v2[1] + v1[2]*v2[2]
	end
end

local function Cross(v1, v2)
	return {v1[2]*v2[3] - v1[3]*v2[2], v1[3]*v2[1] - v1[1]*v2[3], v1[1]*v2[2] - v1[2]*v2[1]}
end

-- Projection of v1 onto v2
local function Project(v1, v2)
	local uV2 = Unit(v2)
	return Mult(Dot(v1, uV2), uV2)
end

-- The normal of v1 onto v2. Returns such that v1 = normal + projection
local function Normal(v1, v2)
	local projection = Project(v1, v2)
	return Subtract(v1, projection), projection
end

function AngleTo(v1, v2)
	return atan2(v1[1]*v2[2] - v1[2]*v2[1], v1[1]*v2[1] + v1[2]*v2[2]);
end

local function DirectionTo(v1, v2)
	return {v2[1] - v1[1], v2[2] - v1[2]}
end
  
local function DistanceTo(v1, v2)
	local x, y = v2[1] - v1[1], v2[2] - v1[2]
	return sqrt(x*x + y*y)
end

local function SlopeIntercept(v1, v2)
	local a = v2[2] - v1[2]
	local b = v1[1] - v2[1]
	local c = (a * v1[1]) + (b * v1[2])
	return a, b, c
end

local function Intersection(v1, d1, v2, d2)
	local a1, b1, c1 = SlopeIntercept(v1, Add(v1, d1))
	local a2, b2, c2 = SlopeIntercept(v2, Add(v2, d2))
	local delta = a1 * b2 - b1 * a2
	if delta == 0 then
	  return nil
	end
	return {((b2 * c1) - (b1 * c2)) / delta, ((a1 * c2) - (a2 * c1)) / delta}
end

-- Spring.GetHeadingFromVector is actually broken at angles close to pi/4 and reflections
local function AngleSpringHeaving(x, z)
	if z then
		return -Spring.GetHeadingFromVector(x, z)/2^15*pi + pi/2
	else
		return -Spring.GetHeadingFromVector(x[1], x[2])/2^15*pi + pi/2
	end
end

local function GetAngleBetweenUnitVectors(u, v)
	return math.acos(Dot(u, v))
end

local function PolarToCart(mag, dir)
	return {mag*cos(dir), mag*sin(dir)}
end

local function InverseBasis(a, b, c, d)
	local det = a*d - b*c
	return d/det, -b/det, -c/det, a/det
end

local function ChangeBasis(v, a, b, c, d)
	return {v[1]*a + v[2]*b, v[1]*c + v[2]*d}
end

local function GetBoundedLineIntersection(line1, line2)
	local x1, y1, x2, y2 = line1[1][1], line1[1][2], line1[2][1], line1[2][2]
	local x3, y3, x4, y4 = line2[1][1], line2[1][2], line2[2][1], line2[2][2]
	
	local denominator = ((x1 - x2)*(y3 - y4) - (y1 - y2)*(x3 - x4))
	if denominator == 0 then
		return false
	end
	local first = ((x1 - x3)*(y3 - y4) - (y1 - y3)*(x3 - x4))/denominator
	local second = -1*((x1 - x2)*(y1 - y3) - (y1 - y2)*(x1 - x3))/denominator
	
	if first < 0 or first > 1 or (second < 0 or second > 1) then
		return false
	end
	
	local px = x1 + first*(x2 - x1)
	local py = y1 + first*(y2 - y1)
	
	return {px, py}
end

local function IsPositiveIntersect(lineInt, lineMid, lineDir)
	return Dot(Subtract(lineInt, lineMid), lineDir) > 0
end

local function DistanceToBoundedLineSq(point, line)
	local startToPos = Subtract(point, line[1])
	local startToEnd = Subtract(line[2], line[1])
	local normal, projection = Normal(startToPos, startToEnd)
	local projFactor = Dot(projection, startToEnd)
	local normalFactor = Dot(normalFactor, startToEnd)
	if projFactor < 0 then
		return Dist(line[1], point)
	end
	if projFactor > 1 then
		return Dist(line[2], point)
	end
	return AbsValSq(Subtract(startToPos, normal)), normalFactor
end

local function DistanceToBoundedLine(point, line)
	local distSq, normalFactor = DistanceToBoundedLineSq(point, line)
	return sqrt(distSq), normalFactor
end

local function DistanceToLineSq(point, line)
	local startToPos = Subtract(point, line[1])
	local startToEnd = Subtract(line[2], line[1])
	local normal, projection = Normal(startToPos, startToEnd)
	return AbsValSq(normal)
end

local function AngleSubtractShortest(angleA, angleB)
	local dist = angleA - angleB
	if dist > 0 then
		if dist < pi then
			return dist
		end
		return dist - 2*pi
	else
		if dist > -pi then
			return dist
		end
		return dist + 2*pi
	end
end

local function AngleAverageShortest(angleA, angleB)
	local diff = AngleSubtractShortest(angleA, angleB)
	return angleA - diff/2
end

Spring.Utilities.Vector = {
	New3 = New3,
	DistSq = DistSq,
	Dist3D = Dist3D,
	Mult = Mult,
	AbsVal = AbsVal,
	Negative = Negative,
	Mag = Mag,
	Unit = Unit,
	Clone = Clone,
	Dot = Dot,
	Cross = Cross,
	Norm = Norm,
	Angle = Angle,
	Project = Project,
	Normal = Normal,
	AngleTo = AngleTo,
	DirectionTo = DirectionTo,
	DistanceTo = DistanceTo,
	SlopeIntercept = SlopeIntercept,
	Intersection = Intersection,
	PolarToCart = PolarToCart,
	Add = Add,
	Subtract = Subtract,
	GetAngleBetweenUnitVectors = GetAngleBetweenUnitVectors,
	InverseBasis = InverseBasis,
	ChangeBasis = ChangeBasis,
	GetBoundedLineIntersection = GetBoundedLineIntersection,
	IsPositiveIntersect = IsPositiveIntersect,
	DistanceToBoundedLineSq = DistanceToBoundedLineSq,
	DistanceToBoundedLine = DistanceToBoundedLine,
	DistanceToLineSq = DistanceToLineSq,
	AngleSubtractShortest = AngleSubtractShortest,
	AngleAverageShortest = AngleAverageShortest,
}
