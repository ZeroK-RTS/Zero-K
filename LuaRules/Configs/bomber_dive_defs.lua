local FUDGE_FACTOR = 1.5

local weaponArray = {}
local unitArray = {}

-- weapons to track
local weapons = {
	bomberprec_bogus_bomb = true,
	bomberprec_shield_check = true,
}

-- bombers to track
local units = {
	bomberprec = {
		diveDamage = 600,
		diveHeight = 25,
		diveDistanceMult = 1.7,
		altPerFlightFrame = 6.25,
		sizeSafetyFactor = 0.75,
		orgHeight = UnitDefNames["bomberprec"].wantedHeight*FUDGE_FACTOR,
	},
}

for i = 1, #WeaponDefs do
	for weapon, data in pairs(weapons) do
		if WeaponDefs[i].name == weapon then 
			weaponArray[i] = data 
		end
	end
end

for i = 1, #UnitDefs do
	for unit, data in pairs(units) do
		if UnitDefs[i].name == unit then 
			unitArray[i] = data 
		end
	end
end

return weapons, weaponArray, unitArray
