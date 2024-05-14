VFS.Include("LuaRules/Utilities/GetSpiralGenerator.lua")

local spiralWithExtraParameters = Spring.Utilities.GetSpiralGenerator(12, 34, step = 3, startingDirection = "n",  clockwise = false)
local x1, z1 = spiralWithExtraParameters.get()
local x2, z2 = spiralWithExtraParameters.get()
local x3, z3 = spiralWithExtraParameters.get()

if  x1 == 12 and z1 == 34
and x2 == 12 and z2 == 31
and x3 ==  9 and z3 == 31 then
  Spring.Echo("OK")
else
  error("fail")
end