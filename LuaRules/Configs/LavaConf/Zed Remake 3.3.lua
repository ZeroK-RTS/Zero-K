
local conf = {
	damage = 75, -- damage per second
	uVscale = 1.5, -- How many times to tile the  texture across the entire map
	colorCorrection = {1.5, 0.09, 3.5}, -- final colorcorrection on all  + shore coloring
	planeLightMult = 0.8,
	coastColor = {0.5, 0.03, 0.8}, -- the color of the  coast
	fogColor = {0.60, 0.10, 1.1}, -- the color of the fog light
	coastLightMult = 1.2, -- how much extra brightness should coastal areas get
	tideamplitude = 1.5, -- how much  should rise up-down on static level
	tideperiod = 150, -- how much time between live rise up-down
	tideRythm = {{target = 0, speed = 0.3, period = 5*6000}},
	doBursts = false,
}

return conf
