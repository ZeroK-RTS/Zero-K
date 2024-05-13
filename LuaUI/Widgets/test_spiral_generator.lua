VFS.Include("LuaRules/Utilities/GetSpiralGenerator.lua")

local function test1()
    local spiralWithExtraParameters = Spring.Utilities.GetSpiralGenerator(12, 34, { step = 3, startingDirection = "n",  clockwise = false })
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
end

local function test2()
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
end

function widget:Initialize()
    test1()
    test2()
end

