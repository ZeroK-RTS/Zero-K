local weaponArray = {}
local unitArray = {}

-- various weapons on a unit can deal different damages
local weapons = {
	capturecar_captureray = {captureDamage = 2.25, scaleDamage = false},
}

-- capture damage	- how much damage capture damage is dealt to the unit per hit
-- scaleDamage		- if true scales capture damage to take into account range falloff, armour etc..

-- all units with capture weapons must have a unit entry
local units = {
	capturecar = { 
		unitLimit = 1,
		},
}
-- unitLimit		- the max number of units it can control. False for infinite

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

return weaponArray, unitArray