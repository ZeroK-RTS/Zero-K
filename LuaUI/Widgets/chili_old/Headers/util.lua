--//=============================================================================

function IsTweakMode()
  return widgetHandler.tweakMode
end

--//=============================================================================

function unpack4(t)
  if t then
    return t[1], t[2], t[3], t[4]
  else
    return 1, 2, 3, 4
  end
end

function clamp(min,max,num)
  if (num<min) then
    return min
  elseif (num>max) then
    return max
  end
  return num
end

function ExpandRect(rect,margin)
  return {
    rect[1] - margin[1],              --//left
    rect[2] - margin[2],              --//top
    rect[3] + margin[1] + margin[3], --//width
    rect[4] + margin[2] + margin[4], --//height
  }
end

function InRect(rect,x,y)
  return x>=rect[1]         and y>=rect[2] and
         x<=rect[1]+rect[3] and y<=rect[2]+rect[4]
end

function ProcessRelativeCoord(code, total)
  local num = tonumber(code)

  if (type(code) == "string") then
    local percent = tonumber(code:sub(1,-2)) or 0
    if (percent<0) then
      percent = 0
    elseif (percent>100) then
      percent = 100
    end
    return math.floor(total * percent/100)
  elseif (num)and((1/num)<0) then
    return math.floor(total + num)
  else
    return math.floor(num or 0)
  end
end

function IsRelativeCoord(code)
  local num = tonumber(code)

  if (type(code) == "string") then
    return true
  elseif (num)and((1/num)<0) then
    return true
  else
    return false
  end
end

function IsRelativeCoordType(code)
  local num = tonumber(code)

  if (type(code) == "string") then
    return "relative"
  elseif (num)and((1/num)<0) then
    return "negative"
  else
    return "default"
  end
end

--//=============================================================================

function IsObject(v)
  return ((type(v)=="metatable")or(type(v)=="userdata")) and(v.classname)
end


function IsNumber(v)
  return (type(v)=="number")
end

function isnumber(v)
  return (type(v)=="number")
end

function istable(v)
  return (type(v)=="table")
end

function isstring(v)
  return (type(v)=="string")
end

function isindexable(v)
  local t = type(v)
  return (t=="table")or(t=="metatable")or(t=="userdata")
end

function isfunc(v)
  return (type(v)=="function")
end

--//=============================================================================

local curScissor = {0,0,1e9,1e9}
local stack = {curScissor}
local stackN = 1

function PushScissor(x,y,w,h)
  local right = x+w
  local bottom = y+h
  if (right  > curScissor[3]) then right  = curScissor[3] end
  if (bottom > curScissor[4]) then bottom = curScissor[4] end
  if (x < curScissor[1]) then x = curScissor[1] end
  if (y < curScissor[2]) then y = curScissor[2] end
	
  curScissor = {x,y,right,bottom}
  stackN = stackN + 1
  stack[stackN] = curScissor
  
  local width = right  - x
  local height = bottom - y
  if (width < 0) or (height < 0) then
    --// scissor is null space -> don't render at all
    return false
  end
  gl.Scissor(x,y,width,height)
end


function PopScissor()
  stack[stackN] = nil
  stackN = stackN - 1
  curScissor = stack[stackN]
  if (stackN == 1) then
    gl.Scissor(false)
  else
    local x,y, right,bottom = unpack4(curScissor)
	local w = right  - x
	local h = bottom - y
	if w >= 0 and h >= 0 then
      gl.Scissor(x,y,w,h)
	end
  end
end

--//=============================================================================

function AreRectsOverlapping(rect1,rect2)
	return
		(rect1[1] <= rect2[1] + rect2[3]) and
		(rect1[1] + rect1[3] >= rect2[1]) and
		(rect1[2] <= rect2[2] + rect2[4]) and
		(rect1[2] + rect1[4] >= rect2[2])
end

--//=============================================================================

local oldPrint = print
function print(...)
  oldPrint(...)
  io.flush()
end

--//=============================================================================

function _ParseColorArgs(r,g,b,a)
  local t = type(r)

  if (t == "table") then
    return r
  else
    return {r,g,b,a}
  end
end

--//=============================================================================

function string:findlast(str)
  local i
  local j = 0
  repeat
    i = j
    j = self:find(str,i+1,true)
  until (not j)
  return i
end

function string:GetExt()
  local i = self:findlast('.')
  if (i) then
    return self:sub(i)
  end
end

--//=============================================================================

local type  = type
local pairs = pairs

function table:clear()
  for i,_ in pairs(self) do
    self[i] = nil
  end
end

function table:map(fun)
  local newTable = {}
  for key, value in pairs(self) do
    newTable[key] = fun(key, value)
  end
  return newTable
end

function table:shallowcopy()
  local newTable = {}
  for k, v in pairs(self) do
    newTable[k] = v
  end
  return newTable
end

function table:arrayshallowcopy()
  local newArray = {}
  for i=1, #self do
    newArray[i] = self[i]
  end
  return newTable
end

function table:arrayappend(t)
  for i=1, #t do
    self[#self+1] = t[i]
  end
end

function table:arraymap(fun)
  for i=1, #self do
    newTable[i] = fun(self[i])
  end
end

function table:fold(fun, state)
  for key, value in pairs(self) do
    fun(state, key, value)
  end
end

function table:arrayreduce(fun)
  local state = self[1]
  for i=2, #self do
    state = fun(state , self[i])
  end
  return state
end

-- removes and returns element from array
-- array, T element -> T element
function table:arrayremovefirst(element)
  for i=1, #self do
    if self[i] == element then
      return self:remove(i)
    end
  end
end

function table:ifind(element)
  for i=1, #self do
    if self[i] == element then
      return i
    end
  end
  return false
end

function table:sum()
  local r = 0
  for i=1, #self do
    r = r + self[i]
  end
  return r
end

function table:merge(table2)
  for i,v in pairs(table2) do
    if (type(v)=='table') then
      local sv = type(self[i])
      if (sv == 'table')or(sv == 'nil') then
        if (sv == 'nil') then self[i] = {} end
        table.merge(self[i],v)
      end
    elseif (self[i] == nil) then
      self[i] = v
    end
  end
end

function table:iequal(table2)
  for i,v in pairs(self) do
    if (table2[i] ~= v) then
      return false
    end
  end

  for i,v in pairs(table2) do
    if (self[i] ~= v) then
      return false
    end
  end

  return true
end

function table:iequal(table2)
  local length = #self
  if (length ~= #table2) then
    return false
  end

  for i=1,length do
    if (self[i] ~= table2[i]) then
      return false
    end
  end

  return true
end

function table:size()
  local cnt = 0
  for _ in pairs(self) do
    cnt = cnt + 1
  end
  return cnt
end

--//=============================================================================

local weak_meta = {__mode='v'}
function CreateWeakTable()
  local m = {}
  setmetatable(m, weak_meta)
  return m
end

--//=============================================================================

function math.round(num,idp)
  if (not idp) then
    return math.floor(num+.5)
  else
    return ("%." .. idp .. "f"):format(num)
    --local mult = 10^(idp or 0)
    --return math.floor(num * mult + 0.5) / mult
  end
end

--//=============================================================================

function InvertColor(c)
  return {1 - c[1], 1 - c[2], 1 - c[3], c[4]}
end

function math.mix(x, y, a)
	return y * a + x * (1 - a)
end

function mulColor(c, s)
  return {s * c[1], s * c[2], s * c[3], c[4]}
end

function mulColors(c1, c2)
  return {c1[1] * c2[1], c1[2] * c2[2], c1[3] * c2[3], c1[4] * c2[4]}
end

function mixColors(c1, c2, a)
	return {
		math.mix(c1[1], c2[1], a),
		math.mix(c1[2], c2[2], a),
		math.mix(c1[3], c2[3], a),
		math.mix(c1[4], c2[4], a)
	}
end

function color2incolor(r,g,b,a)
	if type(r) == 'table' then
		r,g,b,a = unpack4(r)
	end

	local inColor = '\255\255\255\255'
	if r then
		inColor = string.char(255, r*255, g*255, b*255)
	end
	return inColor
end

function incolor2color(inColor)
	local a = 255
	local r,g,b = inColor:sub(2,4):byte(1,3)
	return r/255, g/255, b/255, a/255
end

--//=============================================================================
