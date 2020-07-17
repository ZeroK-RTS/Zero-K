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
	return (pureSlowWeapons[weaponID] and true) or false
end

function Spring.Utilities.IsCaptureWeapon(weaponID)
	return (captureWeapons[weaponID] and true) or false
end

function Spring.Utilities.IsPureDisarmWeapon(weaponID)
	return (pureDisarmWeapons[weaponID] and true) or false
end

function Spring.Utilities.GetWeaponHasStatusEffect(weaponID) -- Single call for checking all three
	return (pureDisarmWeapons[weaponID] and true) or (captureWeapons[weaponID] and true) or (pureSlowWeapons[weaponID] and true)
end