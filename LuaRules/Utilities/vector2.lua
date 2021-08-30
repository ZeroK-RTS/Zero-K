local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin
local atan2 = math.atan2

local Vector2 = {}
Vector2.__index = Vector2

function Vector2.Zero()
  local instance = {0, 0}
  setmetatable(instance, Vector2)
  return instance
end

function Vector2.New(x,y)
  local instance = {x, y}
  setmetatable(instance, Vector2)
  return instance
end

function Vector2.New3(x,y,z)
  local instance = {x, z}
  setmetatable(instance, Vector2)
  return instance, y
end

function Vector2:Add(x)
  return Vector2.New(self[1] + x, self[2] + x)
end

function Vector2:Sub(x)
  return Vector2.New(self[1] - x, self[2] - x)
end

function Vector2:Multi(x)
  return Vector2.New(self[1] * x, self[2] * x)
end

function Vector2:Div(x)
  return Vector2.New(self[1] / x, self[2] / x)
end

function Vector2:Equal(x, y)
  return self[1] == x and self[2] == y
end

function Vector2:DirectionTo(v)
  return Vector2.New(v[1] - self[1], v[2] - self[2])
end

function Vector2:DistanceTo(v)
  local x, y = v[1] - self[1], v[2] - self[2]
  return sqrt(x*x + y*y)
end

function Vector2:Mag()
  return sqrt(self[1] * self[1] + self[2] * self[2])
end

function Vector2:Dot(v)
  return self[1]*v[1] + self[2]*v[2]
end

function Vector2:Rotate(radians)
  local s = sin(radians)
  local c = cos(radians)
  return Vector2.New((c * self[1]) + (s * self[2]), -(s * self[1]) + (c * self[2]))
end

function Vector2:AngleTo(v)
  return atan2(self[1]*v[2] - self[2]*v[1], self[1]*v[1] + self[2]*v[2]);
end

function Vector2:Normalize()
  local mag = sqrt(self[1] * self[1] + self[2] * self[2])
  if mag == 0 then
    return Vector2.New(0, 0)
  end
  return Vector2.New(self[1] / mag, self[2] / mag)
end

function Vector2:Negative()
  return Vector2.New(-self[1], -self[2])
end

function Vector2:Reflect(n)
  local dot = (self[1] * n[1]) + (self[2] * n[2])
  return Vector2.New(2* n[1] * dot - self[1], 2 * n[2] * dot - self[2])
end

function Vector2:SlopeIntercept(v)
  local a = v[2] - self[2]
  local b = self[1] - v[1]
  local c = (a * self[1]) + (b * self[2])
  return a, b, c
end

function Vector2:Clone()
  return Vector2.New(self[1], self[2])
end

function Vector2:Unpack()
  return self[1], self[2]
end

function Vector2.Intersection(v1, d1, v2, d2)
  local a1, b1, c1 = v1:SlopeIntercept(v1 + d1)
  local a2, b2, c2 = v2:SlopeIntercept(v2 + d2)
  local delta = a1 * b2 - b1 * a2
  if delta == 0 then
    return nil
  end
  return Vector2.New(((b2 * c1) - (b1 * c2)) / delta, ((a1 * c2) - (a2 * c1)) / delta)
end

function Vector2.__add(a, b)
  return Vector2.New(a[1] + b[1], a[2] + b[2])
end

function Vector2.__sub(a, b)
  return Vector2.New(a[1] - b[1], a[2] - b[2])
end

function Vector2.__mul(a, b)
  return Vector2.New(a[1] * b[1], a[2] * b[2])
end

function Vector2.__div(a, b)
  return Vector2.New(a[1] / b[1], a[2] / b[2])
end

function Vector2.__eq(a, b)
  return a[1] == b[1] and a[2] == b[2]
end

return Vector2