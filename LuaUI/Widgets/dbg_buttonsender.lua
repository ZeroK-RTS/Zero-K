--THIS GOES IN WIDGET FOLDER
function widget:GetInfo()
  return {
    name      = "button sender R1 w volume type",
    desc      = "send keys presses",
    author    = "knorke, modified by Google Frog (volume type)",
    date      = "dec 1010",
    license   = "push button magic",
    layer     = 0,
    enabled   = false,
  }
end

local KP0 = 256
local KP1 = 257
local KP2 = 258
local KP3 = 259
local KP4 = 260
local KP5 = 261
local KP6 = 262
local KP7 = 263
local KP8 = 264
local KP9 = 265
local W = 119
local S = 115
local A = 97
local D = 100
local E = 101
local Q = 113


local euID = nil
local boxxy = nil

function widget:GameFrame(frame)
	if (euID) then
		--boxxy[1]=5
		--Spring.SetUnitCollisionVolumeData  (euID, boxxy)
		boxxy[1]=math.abs ((math.sin(frame/10)*100) + 20)
		boxxy[2]=math.abs ((math.cos(frame/10)*100) + 20)
		Spring.SetUnitCollisionVolumeData  (euID, unpack(boxxy))
	end
end

function widget:KeyRelease(key)
	--Spring.Echo ("key=" .. key)
	if (key == KP8) then 
		Spring.Echo ("taller")
		Spring.SendLuaRulesMsg ("boxxy|8")
	end
	if (key == KP2) then
		Spring.Echo ("shrink")
		Spring.SendLuaRulesMsg ("boxxy|2")
	end
	if (key == KP4) then 
		Spring.Echo ("narrow")
		Spring.SendLuaRulesMsg ("boxxy|4")
	end
	if (key == KP6) then 
		Spring.Echo ("wider")
		Spring.SendLuaRulesMsg ("boxxy|6")
	end
	if (key == KP7) then 
		Spring.Echo ("shorter")
		Spring.SendLuaRulesMsg ("boxxy|7")
	end
	if (key == KP9) then
		Spring.Echo ("longer")
		Spring.SendLuaRulesMsg ("boxxy|9")
	end
	if (key == W) then
		Spring.Echo ("to front")
		Spring.SendLuaRulesMsg ("boxxy|W")
	end
	if (key == S) then
		Spring.Echo ("to back")
		Spring.SendLuaRulesMsg ("boxxy|S")
	end
	if (key == A) then
		Spring.Echo ("to left")
		Spring.SendLuaRulesMsg ("boxxy|A")
	end
	if (key == D) then
		Spring.Echo ("to right")
		Spring.SendLuaRulesMsg ("boxxy|D")
	end

	if (key == E) then
		Spring.Echo ("to up")
		Spring.SendLuaRulesMsg ("boxxy|E")
	end
	if (key == Q) then
		Spring.Echo ("to lower")
		Spring.SendLuaRulesMsg ("boxxy|Q")
	end
	if (key == KP1) then
		Spring.Echo ("cycle volume type")
		Spring.SendLuaRulesMsg ("boxxy|1")
	end
	if (key == KP3) then
		Spring.Echo ("cycle volume type")
		Spring.SendLuaRulesMsg ("boxxy|3")
	end
	if (key == KP5) then
		Spring.Echo ("changing d!")
		Spring.SendLuaRulesMsg ("boxxy|5")
	end
	if (key == KP0) then
		Spring.Echo ("toggle volume test")
		Spring.SendLuaRulesMsg ("boxxy|0")
	end
end



function marker_on_unit (_uID, _text)
	if (_uID == nil) then return end
	if (_text == nil) then return end
	local x,y,z=Spring.GetUnitPosition (_uID)
	if (x == nil or y == nil or z == nil) then return end
	--Spring.MarkerAddPoint (x,y,z, _text .. "id:" .. _uID)
	Spring.MarkerAddPoint (x,y,z, _text)
end


function widget:AddConsoleLine(msg, priority)
if (string.find (msg, "helpboxxy") ~= nil) or string.find (msg, "helpboxxy") ~= nil then
	Spring.Echo ("SCALING: 2/8  4/6  7/9 (numpad!) MOVING: w/s a/d q/e STEPSIZE TOGGLE: 5")
	end	
end