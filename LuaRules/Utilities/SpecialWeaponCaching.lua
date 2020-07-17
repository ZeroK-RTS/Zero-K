local pureDisarmWeapons = {}
local pureSlowWeapons = {}
local captureWeapons = {}

for i = 1, #WeaponDefs do
	if WeaponDefs[i].customParams.disarmdamageonly == '1' then
		pureDisarmWeapons[i] = true
	end
	if WeaponDefs[i].customParams.timeslow_onlyslow == '1' then
		pureSlowWeapons[i] = true
	end
	if WeaponDefs[i].customParams.is_capture == '1' then
		captureWeapons[i] = true
	end
end

function Spring.Utilities.IsPureSlowWeapon(weaponID)
	if pureSlowWeapons[weaponID] then
		return true
	else
		return false
	end
end

function Spring.Utilities.IsCaptureWeapon(weaponID)
	if captureWeapons[weaponID] then
		return true
	else
		return false
	end
end

function Spring.Utilities.IsPureDisarmWeapon(weaponID)
	if pureDisarmWeapons[weaponID] then
		return true
	else
		return false
	end
end
