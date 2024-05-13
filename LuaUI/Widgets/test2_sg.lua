VFS.Include("LuaRules/Utilities/GetSpiralGenerator.lua")

local defaultSpiral = Spring.Utilities.GetSpiralGenerator()
local spiralWithDefaultsExplicitlySpecified = Spring.Utilities.GetSpiralGenerator(0, 0, { step = 1, startingDirection = "n",  clockwise = false })

for i = 1, 20 do
  local xD, zD = defaultSpiral.get()
  local xE, zE = spiralWithDefaultsExplicitlySpecified.get()
  if xD ~= xE or zD ~= zE then
    error("fail")
  end
end
Spring.Echo("OK 2")