local array = {}

local weapons = {
	slowmort_slowbeam = { slowDamage = 300, onlySlow = true, smartRetarget = true, scaleSlow = true},
	cormak_blast = { slowDamage = 12, noFF = true, noDeathBlast = true, scaleSlow = true },
	slowmissile_weapon = { slowDamage = 1, onlySlow = true, scaleSlow = true },
	
	commsupport_slowbeam = { slowDamage = 750, onlySlow = true, smartRetarget = true, scaleSlow = true},
	commadvsupport_slowbeam = { slowDamage = 850, onlySlow = true, smartRetarget = true, scaleSlow = true},
	commadvsupport_disruptorbeam = { slowDamage = 8000, scaleSlow = true},
	commadvrecon_slowbomb = { slowDamage = 5000, scaleSlow = true },
}

for i=1,#WeaponDefs do
	for weapon, data in pairs(weapons) do
		if WeaponDefs[i].name == weapon then array[i] = data end
	end
end

return array