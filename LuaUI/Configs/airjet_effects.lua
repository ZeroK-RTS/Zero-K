
local effectUnitDefs = include("Configs/lupsUnitFXs.lua")

local migratedDefs = {}

for unitname, effects in pairs(effectUnitDefs) do
	for i = 1, #effects do
		local effect = effects[i]
		if effect.class == "AirJet" then
			local col = effect.options.color
			migratedDefs[unitname] = migratedDefs[unitname] or {}
			migratedDefs[unitname][#migratedDefs[unitname] + 1] = {
				color = {col[1]*0.9, col[2]*0.9, col[3]*0.9},
				width = effect.options.width,
				length = effect.options.length,
				piece = effect.options.piece,
				texture2 = effect.options.texture2 or ":c:bitmaps/gpl/lups/jet2.bmp",
				distortLength = effect.options.distortLength,
				light = 1,
			}
		end
	end
end

return migratedDefs --or {}
