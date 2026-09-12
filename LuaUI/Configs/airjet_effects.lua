
local effectUnitDefs = include("Configs/lupsUnitFXs.lua")

local migratedDefs = {}

for unitname, effects in pairs(effectUnitDefs) do
	for i = 1, #effects do
		local effect = effects[i]
		if effect.class == "AirJet" then
			migratedDefs[unitname] = migratedDefs[unitname] or {}
			migratedDefs[unitname][#migratedDefs[unitname] + 1] = {
				color = effect.options.color,
				width = effect.options.width,
				length = effect.options.length,
				piece = effect.options.piece,
				texture2 = effect.options.texture2 or ":c:bitmaps/gpl/lups/jet2.bmp",
				light = 1,
			}
		end
	end
end

return migratedDefs
