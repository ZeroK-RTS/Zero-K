
local conf = {
	level = 120,
	damage = 150, -- damage per second
	colorCorrection = {1.1, 1.0, 0.88}, -- final colorcorrection on all  + shore coloring
	planeLightMult = 2,
	
	coastColor = {2.2, 0.4, 0.0}, -- the color of the  coast
	coastLightBoost = 0.7,
	
	fogColor = {2.0, 0.31, 0.0}, -- the color of the fog light
	fogFactor = 0.08, -- how dense the fog is
	fogHeight = 85,
	fogAbove = 0.18,
	
	tideamplitude = 3,
	tideperiod = 95,
	tideRythm = {{speed = 0.3, period = 5*6000}},
}

return conf


