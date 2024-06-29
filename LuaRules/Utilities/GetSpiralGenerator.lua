-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Authors: IcarusRTS, Niarteloc

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function CalculateXAndZ(x, z, unitRadius, movesLeft, isClockwise)
    local k, r, theta = 0, 0, 0
    local nx, nz

    if isClockwise == true then
        k = unitRadius / (2 * math.pi)
    else
        k = -(unitRadius / (2 * math.pi))
    end

    while (movesLeft > 0)
    do
        r = k * theta
        nx = x + (r * math.cos(theta))
        nz = z + (r * math.sin(theta))
        theta = theta + math.min(2*math.pi, unitRadius/math.abs(r))
        movesLeft = movesLeft - 1
    end

    return nx, nz
end
 
function Spring.Utilities.GetSpiralGenerator(x, z, params)
    -- Defaults
    x = x or 0
    z = z or 0
    params = params or {}
    params.radius = params.radius or 16
    params.step = params.step or 1
    params.clockwise = params.clockwise

    -- Table Parameters
    local unitRadius = params.radius
    local movesLeft = params.step
    local isClockwise = params.clockwise

    local nx, nz

    local function get()
        nx, nz = CalculateXAndZ(x, z, unitRadius, movesLeft, isClockwise)
        return nx, nz
    end

    return get
end