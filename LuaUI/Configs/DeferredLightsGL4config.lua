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
		lifetime = 0, sustain = 1, aninmtype = 0 -- unused
	},
}

local gibLight = {
	lightType = 'point', -- or cone or beam
	pieceName = nil, -- optional
	lightConfig = {
		posx = 0, posy = 0, posz = 0, radius = 120,
		r = 1, g = 0.9, b = 0.5, a = 0.12,
		color2r = 0.9, color2g = 0.75, color2b = 0.25, colortime = 0.3, -- point lights only, colortime in seconds for unit-attache
		modelfactor = 0.4, specular = 0.5, scattering = 0.5, lensflare = 0,
		lifetime = 300, sustain = 3, aninmtype = 0 -- unused
	},
}

local unitEventLights = {}
local unitDefLights = {}
local muzzleFlashLights = {}
local lightFiles = VFS.DirList('LuaUI/Configs/UnitLights')
for i = 1, #lightFiles do
	local fileData = VFS.Include(lightFiles[i])
	for unitName, unitLights in pairs(fileData) do
		local ud = UnitDefNames[unitName]
		if ud then
			local unitDefID = ud.id
			unitDefLights[unitDefID] = unitLights.static
			unitEventLights[unitDefID] = unitLights.event
			muzzleFlashLights[unitDefID] = unitLights.muzzle
		end
	end
	fileData = nil -- This is just copypasta, I assume it does nearly nothing.
end

local allLights = {
	unitEventLights = unitEventLights,
	unitDefLights = unitDefLights,
	featureDefLights = {},
	muzzleFlashLights = muzzleFlashLights,
	projectileDefLights = {},
	explosionLights = {},
	gibLight = gibLight,
}

return allLights


