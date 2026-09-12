
local effectUnitDefs = include("Configs/lupsUnitFXs.lua")

local migratedDefs = {}

for unitname, effects in pairs(effectUnitDefs) do
	for i = 1, #effects do
		local effect = effects[i]
		if effect.class == "Ribbon" then
			local def = effect.options
			local ud = UnitDefNames[unitname]
			local unitDefID = ud.id
			if not migratedDefs[unitDefID] then
				migratedDefs[unitDefID] = {
					emitPieces = {},
					maxSpeed = ud.speed or 1,
					color = def.color or {1, 1, 1},
					trailAlpha = def.color and def.color[4] or 1,

					trailWidth   = def.width * 3,
					trailSeconds = 0.7,
				}
			end
			migratedDefs[unitDefID].emitPieces[#migratedDefs[unitDefID].emitPieces + 1] = def.piece
		end
	end
end

return migratedDefs
