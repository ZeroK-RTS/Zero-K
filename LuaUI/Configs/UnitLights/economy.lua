
local function ArrangeLights(positions, base)
	local lights = {}
	for i = 1, #positions do
		local light = Spring.Utilities.CopyTable(base, true)
		light.lightConfig.posx = positions[i][1]
		light.lightConfig.posy = positions[i][2]
		light.lightConfig.posz = positions[i][3]
		lights[#lights + 1] = light
	end
	return lights
end


local unitLights = {
	energysolar = {
		static = ArrangeLights(
			{
				{-24.6, 5, 6},
				{-24.6, 5, -6},
				{24.6, 5, 6},
				{24.6, 5, -6},
				{6, 5, 24.6},
				{6, 5, -24.6},
				{-6, 5, 24.6},
				{-6, 5, -24.6},
			},
			{
				lightType = 'point',
				pieceName = 'base',
				lightConfig = {
					posx = -24, posy = 5, posz = 6, radius = 18,
					color2r = 1, color2g = 0.2, color2b = 0.2, colortime = 0,
					r = 0.9, g = 0.95, b = 1, a = 0.06,
					modelfactor = 0.8, specular = 0, scattering = 0.9, lensflare = 0,
					lifetime = 0, sustain = 0, animtype = 0
				},
			}
		)
	},
	energysingu = {
		static = {
			{
				lightType = 'point',
				pieceName = 'base',
				lightConfig = {
					-- Excessive radius looks weird when scouted, since the light suddenly appears when the unit enters LOS
					posx = 0, posy = 60, posz = 0, radius = 350,
					color2r = 1, color2g = 0.2, color2b = 0.2, colortime = 0,
					r = 1, g = 0.8, b = 0, a = 0.16,
					modelfactor = 0.45, specular = 0.8, scattering = 0.1, lensflare = 0,
					lifetime = 0, sustain = 0, animtype = 0
				},
			},
		}
	},
	energypylon = {
		static = {
			{
				lightType = 'point',
				pieceName = 'base',
				lightConfig = {
					posx = 0, posy = 35, posz = 0, radius = 60,
					color2r = 1, color2g = 0.2, color2b = 0.2, colortime = 0,
					r = 1, g = 0.8, b = 0, a = 0.03,
					modelfactor = 0.5, specular = 0.8, scattering = 0.1, lensflare = 0,
					lifetime = 0, sustain = 0, animtype = 0
				},
			},
			{
				lightType = 'cone',
				pieceName = 'base',
				lightConfig = {
					posx = 10, posy = 8, posz = 10, radius = 100,
					dirx = 1, diry = -0.65, dirz = 1, theta = 0.8,
					r = 0.9, g = 0.9, b = 0, a = 0.5,
					modelfactor = 0.1, specular = 0, scattering = 0, lensflare = 0,
					lifetime = 0, sustain = 0, animtype = 0
				},
			},
			{
				lightType = 'cone',
				pieceName = 'base',
				lightConfig = {
					posx = 10, posy = 8, posz = -10, radius = 100,
					dirx = 1, diry = -0.65, dirz = -1, theta = 0.8,
					r = 0.9, g = 0.9, b = 0, a = 0.5,
					modelfactor = 0.1, specular = 0, scattering = 0, lensflare = 0,
					lifetime = 0, sustain = 0, animtype = 0
				},
			},
			{
				lightType = 'cone',
				pieceName = 'base',
				lightConfig = {
					posx = -10, posy = 8, posz = 10, radius = 100,
					dirx = -1, diry = -0.65, dirz = 1, theta = 0.8,
					r = 0.9, g = 0.9, b = 0, a = 0.5,
					modelfactor = 0.1, specular = 0, scattering = 00, lensflare = 0,
					lifetime = 0, sustain = 0, animtype = 0
				},
			},
			{
				lightType = 'cone',
				pieceName = 'base',
				lightConfig = {
					posx = -10, posy = 8, posz = -10, radius = 100,
					dirx = -1, diry = -0.65, dirz = -1, theta = 0.8,
					r = 0.9, g = 0.9, b = 0, a = 0.5,
					modelfactor = 0.1, specular = 0, scattering = 0, lensflare = 0,
					lifetime = 0, sustain = 0, animtype = 0
				},
			},
			{
				lightType = 'cone',
				pieceName = 'base',
				lightConfig = {
					posx = 4, posy = 8, posz = 4, radius = 100,
					dirx = 1, diry = 0.2, dirz = 1, theta = 0.9,
					r = 0.9, g = 0.9, b = 0, a = 0.4,
					modelfactor = 0.35, specular = 0, scattering = 0, lensflare = 0,
					lifetime = 0, sustain = 0, animtype = 0
				},
			},
			{
				lightType = 'cone',
				pieceName = 'base',
				lightConfig = {
					posx = 4, posy = 8, posz = -4, radius = 100,
					dirx = 1, diry = 0.2, dirz = -1, theta = 0.9,
					r = 0.9, g = 0.9, b = 0, a = 0.4,
					modelfactor = 0.35, specular = 0, scattering = 0, lensflare = 0,
					lifetime = 0, sustain = 0, animtype = 0
				},
			},
			{
				lightType = 'cone',
				pieceName = 'base',
				lightConfig = {
					posx = -4, posy = 8, posz = 4, radius = 100,
					dirx = -1, diry = 0.2, dirz = 1, theta = 0.9,
					r = 0.9, g = 0.9, b = 0, a = 0.4,
					modelfactor = 0.35, specular = 0, scattering = 0, lensflare = 0,
					lifetime = 0, sustain = 0, animtype = 0
				},
			},
			{
				lightType = 'cone',
				pieceName = 'base',
				lightConfig = {
					posx = -4, posy = 8, posz = -4, radius = 100,
					dirx = -1, diry = 0.2, dirz = -1, theta = 0.9,
					r = 0.9, g = 0.9, b = 0, a = 0.4,
					modelfactor = 0.35, specular = 0, scattering = 0, lensflare = 0,
					lifetime = 0, sustain = 0, animtype = 0
				},
			},
		},
	},
}

return unitLights
