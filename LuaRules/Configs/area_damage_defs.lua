local array = {}

local DAMAGE_PERIOD = 2 -- how often damage is applied

for id, data in pairs(WeaponDefs) do
	local cp = data.customParams
	if cp.area_damage then
		array[id] = {
			damage = tonumber(cp.area_damage_dps) *DAMAGE_PERIOD/30,
			radius = tonumber(cp.area_damage_radius),
			impulse = (cp.area_damage_is_impulse == "1"),
			duration = tonumber(cp.area_damage_duration) * 30,
			rangeFall = tonumber(cp.area_damage_range_falloff),
			timeFall = tonumber(cp.area_damage_time_falloff),
			heightMax = tonumber(cp.area_damage_height_max),
			heightInt = tonumber(cp.area_damage_height_int),
			heightReduce = tonumber(cp.area_damage_height_reduce),
		}
		array[id].timeLoss = array[id].damage * array[id].timeFall * DAMAGE_PERIOD/array[id].duration
	end
end

return DAMAGE_PERIOD, array
