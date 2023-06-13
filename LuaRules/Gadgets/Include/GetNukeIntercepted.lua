local atan = math.atan
local cos = math.cos
local sin = math.sin
local pi = math.pi
local sqrt = math.sqrt

-- Unit (antinuke) position, Projectile (nuke silo) position, Target position
local function GetNukeIntercepted(ux, uz, px, pz, tx, tz, radiusSq)

	-- Translate projectile position to the origin.
	ux, uz, tx, tz, px, pz = ux - px, uz - pz, tx - px, tz - pz, 0, 0

	-- Get direction from projectile to target
	local tDir
	if tx == 0 then
		if tz == 0 then
			return ux^2 + uz^2 < radiusSq
		elseif tz > 0 then
			tDir = pi * 0.5
		else
			tDir = pi * 1.5
		end
	elseif tx > 0 then
		tDir = atan(tz/tx)
	else
		tDir = atan(tz/tx) + pi
	end

	-- Rotate space such that direction from projectile to target is 0
	-- The nuke projectile will travel along the positive x-axis
	local cosDir = cos(-tDir)
	local sinDir = sin(-tDir)
	ux, uz = ux*cosDir - uz*sinDir, uz*cosDir + ux*sinDir
	tx, tz = tx*cosDir - tz*sinDir, tz*cosDir + tx*sinDir

	-- Find intersection of antinuke range with x-axis
	-- Quadratic formula, a = 1
	local b = -2*ux
	local c = ux^2 + uz^2 - radiusSq
	local determinate = b^2 - 4*c
	if determinate < 0 then
		-- No real solutions so the circle does not intersect x-axis.
		-- This means that antinuke projectile does not cross intercept
		-- range.
		return false
	end

	determinate = sqrt(determinate)
	local leftInt  = (-b - determinate)/2
	local rightInt = (-b + determinate)/2

	-- IF the nuke does not fall short of coverage
	-- AND the projectile is still within coverage
	return leftInt < tx and rightInt > 0
end

return GetNukeIntercepted