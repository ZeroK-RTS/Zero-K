local weaponArray = {}
local unitArray = {}

for i=1, #WeaponDefs do
	if WeaponDefs[i].customParams.is_capture == '1' then
		weaponArray[i] = {
			captureDamage = WeaponDefs[i].damages[0],
			scaleDamage = (WeaponDefs[i].customParams.capture_scaling == '1'), -- falloff, armor, etc
			baseDamage = WeaponDefs[i].customParams.shield_damage,
			captureToDroneController = WeaponDefs[i].customParams.capture_to_drone_controller and true or false,
		}
	end
end

for i=1, #UnitDefs do
	local cp = UnitDefs[i].customParams
	if cp.post_capture_reload or cp.capture_via_drones then
		unitArray[i] = {
			postCaptureReload = cp.post_capture_reload and tonumber(cp.post_capture_reload), -- in frames
			captureFromDrones = cp.capture_via_drones and true or false,
		}
	end
end

return weaponArray, unitArray
