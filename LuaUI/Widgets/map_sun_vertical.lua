
function widget:GetInfo()
	return {
		name      = "Sun Vertical",
		desc      = "Sets the sun to high noon.",
		author    = "GoogleFrog",
		date      = "1 March 2017",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false
	}
end

function widget:Initialize()
	local x, y, z = 0.01, 1, 0.01 -- 0/1/0 breaks shadows.
	local dist = math.sqrt(x*x + y*y + z*z)
	x, y, z = x/dist, y/dist, z/dist
	Spring.SetSunDirection(x, y, z)
end
