local spawn_defs = {}

for i = 1, #WeaponDefs do
	local cp = WeaponDefs[i].customParams
	if cp.spawns_name then
		spawn_defs[i] = {
			name = cp.spawns_name,
			expire = tonumber(cp.spawns_expire or 0),
			feature = (cp.spawns_feature == 1),
		}
	end
end

return spawn_defs
