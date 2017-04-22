local FUDGE_FACTOR = 1.5

local weaponArray = {}
local unitArray = {}

-- weapons to track
local weapons = {
	corshad_bogus_bomb = true,
	corshad_shield_check = true,
	bomberdive_bogus_bomb = true,
	bomberdive_shield_check = true,
}

-- bombers to track
local units = {
	corshad = {
		diveDamage = 600,
		diveHeight = 25,
		diveRate = 1.55,
		altPerFlightFrame = 6.25,
		orgHeight = UnitDefNames["corshad"].wantedHeight*FUDGE_FACTOR,
	},
	bomberdive = {
		diveDamage = 600,
		diveHeight = 25,
		diveRate = 1.55,
		altPerFlightFrame = 6.25,
		orgHeight = UnitDefNames["bomberdive"].wantedHeight*FUDGE_FACTOR,
	},
}

for i=1,#WeaponDefs do
	for weapon, data in pairs(weapons) do
		if WeaponDefs[i].name == weapon then 
			weaponArray[i] = data 
		end
	end
end

for i=1,#UnitDefs do
	for unit, data in pairs(units) do
		if UnitDefs[i].name == unit then 
			unitArray[i] = data 
		end
	end
end

return weapons, weaponArray, unitArray