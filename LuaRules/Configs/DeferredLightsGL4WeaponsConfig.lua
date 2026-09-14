
local gibLight = {
	lightType = 'point', -- or cone or beam
	pieceName = nil, -- optional
	lightConfig = {
		posx = 0, posy = 0, posz = 0, radius = 52,
		r = 1, g = 0.9, b = 0.5, a = 0.08,
		color2r = 0.9, color2g = 0.75, color2b = 0.25, colortime = 0.3, -- point lights only, colortime in seconds for unit-attache
		modelfactor = 0.4, specular = 0.5, scattering = 0.5, lensflare = 0,
		lifetime = 300, sustain = 3, selfshadowing = 0 
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local baseLightDefs = VFS.Include("LuaUI/Configs/projectileLightDefs.lua")
local projLights = {}

for weaponDefID = 1, #WeaponDefs do
	local wep = baseLightDefs[weaponDefID]
	if wep then
		if wep.beam then
			local lightTime = (wep.fadeTime or 0) + 15
			projLights[weaponDefID] = {
				lightType = 'beam', -- or cone or beam
				lightConfig = {
					posx = 0, posy = 0, posz = 0, radius = wep.radius,
					colortime = lightTime,
					r = wep.r, g = wep.g, b = wep.b, a = wep.a,
					pos2x = 100, pos2y = 1000, pos2z = 100, -- beam lights only, specifies the endpoint of the beam
					modelfactor = 1, specular = 0.5, scattering = 2.5, lensflare = 1,
					lifetime = lightTime, sustain = lightTime*0.1, selfshadowing = 0, 
				}
			}
		else
			projLights[weaponDefID] = {
				lightType = 'point', -- or cone or beam
				lightConfig = {
					posx = 0, posy = wep.elevation or 10, posz = 0, radius = wep.radius,
					r = wep.r, g = wep.g, b = wep.b, a = wep.a,
					modelfactor = 0.5, specular = 0.6, scattering = 0.5, lensflare = 0,
					lifetime = 0, sustain = 0, selfshadowing = 0, 
				}
			}
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return {muzzleFlashLights = {}, projectileDefLights = projLights, explosionLights = {}, gibLight = gibLight}
