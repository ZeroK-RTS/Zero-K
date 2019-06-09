local weaponArray = {}
local unitArray = {}

for i=1, #WeaponDefs do
	if WeaponDefs[i].customParams.is_capture == '1' then
		weaponArray[i] = {
			captureDamage = WeaponDefs[i].damages[0],
			scaleDamage = (WeaponDefs[i].customParams.capture_scaling == '1'), -- falloff, armor, etc
			baseDamage = WeaponDefs[i].customParams.shield_damage,
		}
	end
end

for i=1, #UnitDefs do
	if UnitDefs[i].customParams.post_capture_reload then
		unitArray[i] = {
			postCaptureReload = tonumber(UnitDefs[i].customParams.post_capture_reload), -- in frames
		}
	end
end

return weaponArray, unitArray
