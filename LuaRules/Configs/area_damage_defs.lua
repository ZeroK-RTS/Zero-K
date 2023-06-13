local array = {}

local DAMAGE_PERIOD = 2 -- how often damage is applied

for id, data in pairs(WeaponDefs) do
	local cp = data.customParams
	if cp.area_damage or cp.area_damage_weapon_name then
		if cp.area_damage_weapon_name then
			local spawnDef = WeaponDefNames[cp.area_damage_weapon_name]
			array[id] = {
				spawnWeaponDefID = spawnDef.id,
				period = tonumber(cp.area_damage_repeat_period),
				periodIncrease = tonumber(cp.area_damage_repeat_period_increase or 0),
				repeats = tonumber(cp.area_damage_repeats),
				instantSpawn = (cp.area_damage_weapon_instant_spawn == "1"),
			}
		elseif cp.area_damage_dps then
			local damageUpdateRate = tonumber(cp.area_damage_update_mult or 1)*DAMAGE_PERIOD
			array[id] = {
				damage = tonumber(cp.area_damage_dps)*damageUpdateRate/30,
				radius = tonumber(cp.area_damage_radius),
				plateauRadius = tonumber(cp.area_damage_plateau_radius),
				impulse = (cp.area_damage_is_impulse == "1"),
				slow = (cp.area_damage_is_slow == "1"),
				duration = tonumber(cp.area_damage_duration) * 30,
				rangeFall = tonumber(cp.area_damage_range_falloff),
				timeFall = tonumber(cp.area_damage_time_falloff),
				heightMax = tonumber(cp.area_damage_height_max),
				heightInt = tonumber(cp.area_damage_height_int),
				heightReduce = tonumber(cp.area_damage_height_reduce),
			}
			array[id].timeLoss = array[id].damage * array[id].timeFall * damageUpdateRate/array[id].duration
			if damageUpdateRate ~= DAMAGE_PERIOD then
				array[id].damageUpdateRate = damageUpdateRate
			end
		end
	end
end

return DAMAGE_PERIOD, array
