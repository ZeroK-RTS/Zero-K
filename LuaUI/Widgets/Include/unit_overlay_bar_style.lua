--------------------------------------------------------------------------------
-- Shared bar palette for the GL4 unit overlay (gui_unit_overlay_gl4.lua).
--
-- Single source of truth for the overlay's bar colors so 2D consumers -- the selection /
-- cursortip panel's Chili progressbars -- match the in-world overlay exactly instead of
-- hand-copying its colors. The overlay's barTypeMap references this table directly; 2D
-- consumers read the same colors (and the ramp/string helpers below) for their own bars.
--
-- Colors are {r, g, b, a} in 0..1. `health` and `shield` ramp linearly from `empty` (0%) to
-- `full` (100%); `reload` likewise (its `full` is the lit teal). `jump` is a flat fill color.
--
-- `build` is the flat stand-in color for the overlay's build.png fill art: the overlay draws
-- that bar white-tinted over pre-colored art, so it has no flat color of its own -- 2D consumers
-- with no art use this amber directly. (The overlay itself does not reference style.build.)
--------------------------------------------------------------------------------

local function mix(a, b, t)
	return {
		a[1] + (b[1] - a[1]) * t,
		a[2] + (b[2] - a[2]) * t,
		a[3] + (b[3] - a[3]) * t,
		a[4] + (b[4] - a[4]) * t,
	}
end

local style = {
	health = { empty = {1.0, 0.0, 0.0, 1.0}, full = {0.0, 1.0, 0.0, 1.0} },
	shield = { empty = {1.0, 0.1, 0.1, 1.0}, full = {0.1, 0.1, 1.0, 1.0} },
	reload = { empty = {0.03, 0.4, 0.4, 1.0}, full = {0.05, 0.6, 0.6, 1.0} },
	jump   = {0.4, 0.9, 0.5, 1.0},
	build  = {0.8, 0.8, 0.2, 1.0},
}

-- Linear color at `fraction` (0..1) along a ramp bar's empty->full range.
function style.GetRampColor(bar, fraction)
	return mix(bar.empty, bar.full, fraction)
end

-- Health color at `fraction` (0..1). With returnString, packs it as a Chili text color-code
-- string (the leading 255 is the color-code marker byte) instead of an {r,g,b,a} table.
function style.GetHealthColor(fraction, returnString)
	local c = mix(style.health.empty, style.health.full, fraction)
	if returnString then
		return string.char(255, math.floor(255 * c[1]), math.floor(255 * c[2]), math.floor(255 * c[3]))
	end
	return c
end

-- Shield color at `fraction` (0..1): red(empty) -> blue(full) ramp.
function style.GetShieldColor(fraction)
	return mix(style.shield.empty, style.shield.full, fraction)
end

return style
