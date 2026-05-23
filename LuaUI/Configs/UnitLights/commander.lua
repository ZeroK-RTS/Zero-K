
local unitLights = {}

for i = 1, #UnitDefs do
	local cp = UnitDefs[i].customParams
	if cp.commtype or cp.dynamic_comm then
		local name = UnitDefs[i].name
		
		unitLights[name] = {
			static = {
				{
					lightType = 'point',
					pieceName = 'base',
					lightConfig = {
						-- Excessive radius looks weird when scouted, since the light suddenly appears when the unit enters LOS
						posx = 0, posy = 60, posz = 0, radius = 5,
						color2r = 0, color2g = 0, color2b = 0, colortime = 0,
						r = 1, g = 0.8, b = 0, a = 0,
						modelfactor = 0.45, specular = 0.8, scattering = 0.1, lensflare = 0,
						lifetime = 0, sustain = 0, animtype = 0
					}
				}
			}
		}
	end
end

return unitLights
