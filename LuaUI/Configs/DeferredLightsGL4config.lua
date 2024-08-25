-- This file is for all unit-attached lights. Apparently searchlights and thrusters
-- could be specified here too, but they don't seem to work. Extra widgets might be
-- required.

local exampleLight = {
	lightType = 'point', -- point, cone or beam
	-- if pieceName == nil then the light is treated as WORLD-SPACE
	-- if pieceName == valid piecename, then the light is attached to that piece
	-- if pieceName == invalid piecename, then the light is attached to base of unit
	pieceName = nil,
	-- If you want to make the light be offset from the top of the unit, specify how many elmos above it should be!
	aboveUnit = nil,
	-- Lights that should spawn even if they are outside of view need this set:
	alwaysVisible = nil,
	lightConfig = {
		posx = 0, posy = 0, posz = 0, radius = 100,
		r = 1, g = 1, b = 1, a = 1,
		-- point lights only, colortime in seconds for unit-attached:
			color2r = 1, color2g = 1, color2b = 1, colortime = 15,
		-- cone lights only, specify direction and half-angle in radians:
			dirx = 0, diry = 0, dirz = 1, theta = 0.5,
		-- beam lights only, specifies the endpoint of the beam:
			pos2x = 100, pos2y = 100, pos2z = 100,
		modelfactor = 1, specular = 1, scattering = 1, lensflare = 1,
		lifetime = 0, sustain = 1, 	aninmtype = 0 -- unused
	},
}

-- multiple lights per unitdef/piece are possible, as the lights are keyed by lightname

local unitLights = {
	['energysolar'] = {
		light = {
			lightType = 'point',
			pieceName = 'base',
			lightConfig = { 
			posx = 0, posy = 1000, posz = 0, radius = 1300,
			r = 1, g = 1, b = 1, a = 0.75,
			pos2x = 0, pos2y = -100, pos2z = 0,},
		},
	},
}

-- convert unitname -> unitDefID
local unitDefLights = {}
for unitName, lights in pairs(unitLights) do
	if UnitDefNames[unitName] then
		unitDefLights[UnitDefNames[unitName].id] = lights
	end
end
unitLights = nil

local allLights = {unitEventLights = {}, unitDefLights = unitDefLights, featureDefLights = {}}

return allLights


