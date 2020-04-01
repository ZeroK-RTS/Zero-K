--- JARVIS MARCH
-- https://github.com/kennyledet/Algorithm-Implementations/blob/master/Convex_hull/Lua/Yonaba/convex_hull.lua

-- Convex hull algorithms implementation
-- See : http://en.wikipedia.org/wiki/Convex_hull

-- Calculates the signed area
local function cross(p, q, r)
	return (q.z - p.z) * (r.x - q.x)
		 - (q.x - p.x) * (r.z - q.z)
end

-- Checks if points p, q, r are oriented counter-clockwise
local function isCCW(p, q, r) return cross(p, q, r) < 0 end

-- Returns the convex hull using Jarvis' Gift wrapping algorithm).
-- It expects an array of points as input. Each point is defined
-- as : {x = <value>, y = <value>}.
-- See : http://en.wikipedia.org/wiki/Gift_wrapping_algorithm
-- points  : an array of points
-- returns : the convex hull as an array of points
local function JarvisMarch(points, benchmark)
	benchmark:Enter("JarvisMarch")
	-- We need at least 3 points
	local numPoints = #points
	if numPoints < 3 then return end

	-- Find the left,bottom-most point
	local lbMostPointIndex = 1
		for i = 1, numPoints do
		if points[i].x < points[lbMostPointIndex].x then
			lbMostPointIndex = i
		elseif points[i].x == points[lbMostPointIndex].x then
			if points[i].z < points[lbMostPointIndex].z then
				lbMostPointIndex = i
			end
		end
	end

	local p = lbMostPointIndex
	local hull = {} -- The convex hull to be returned

	-- Process CCW from the left-most point to the start point
	repeat
		-- Find the next point q such that (p, i, q) is CCW for all i
		q = points[p + 1] and p + 1 or 1
		for i = 1, numPoints, 1 do
		  if isCCW(points[p], points[i], points[q]) then q = i end
		end

		table.insert(hull, points[q]) -- Save q to the hull
		p = q  -- p is now q for the next iteration
	until (p == lbMostPointIndex)

	benchmark:Leave("JarvisMarch")
	return hull
end
--- JARVIS MARCH

--- MONOTONE CHAIN
-- https://gist.githubusercontent.com/sixFingers/ee5c1dce72206edc5a42b3246a52ce2e/raw/b2d51e5236668e5408d24b982eec9c339dc94065/Lua%2520Convex%2520Hull

-- Andrew's monotone chain convex hull algorithm
-- https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain
-- Direct port from Javascript version

function MonotoneChain(points, benchmark)
	benchmark:Enter("MonotoneChain")
	local numPoints = #points
	if numPoints < 3 then return end

	table.sort(points,
		function(a, b)
			return a.x == b.x and a.z > b.z or a.x > b.x
		end
	)

    local lower = {}
    for i = 1, numPoints do
        while (#lower >= 2 and cross(lower[#lower - 1], lower[#lower], points[i]) <= 0) do
            table.remove(lower, #lower)
        end

        table.insert(lower, points[i])
    end

    local upper = {}
    for i = numPoints, 1, -1 do
        while (#upper >= 2 and cross(upper[#upper - 1], upper[#upper], points[i]) <= 0) do
            table.remove(upper, #upper)
        end

        table.insert(upper, points[i])
    end

    table.remove(upper, #upper)
    table.remove(lower, #lower)
    for _, point in ipairs(lower) do
        table.insert(upper, point)
    end

	benchmark:Leave("MonotoneChain")
    return upper
end


--- MONOTONE CHAIN

return {
	JarvisMarch = JarvisMarch,
	MonotoneChain = MonotoneChain,
}