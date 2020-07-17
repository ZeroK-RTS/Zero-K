local pureDisarmWeapons = {}
local pureSlowWeapons = {}
local captureWeapons = {}

for i = 1, #WeaponDefs do
	local cp = WeaponDefs[i].customParams
	pureDisarmWeapons[i] = (cp.disarmdamageonly  == '1')
	pureSlowWeapons  [i] = (cp.timeslow_onlyslow == '1')
	captureWeapons   [i] = (cp.is_capture        == '1')
end

function Spring.Utilities.IsPureSlowWeapon(weaponID)
	return pureSlowWeapons[weaponID]
end

function Spring.Utilities.IsCaptureWeapon(weaponID)
	return captureWeapons[weaponID]
end

function Spring.Utilities.IsPureDisarmWeapon(weaponID)
	return pureDisarmWeapons[weaponID]
end

function Spring.Utilities.IsWeaponPureStatusEffect(weaponID) -- Single call for checking all three
	return pureDisarmWeapons[weaponID] or captureWeapons[weaponID] or pureSlowWeapons[weaponID]
end