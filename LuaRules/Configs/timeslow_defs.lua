local array = {}

local weapons = {
	slowmort_slowbeam = { slowDamage = 600, onlySlow = true, smartRetarget = true, scaleSlow = true},
	cormak_blast = { slowDamage = 80, noFF = true, noDeathBlast = true, scaleSlow = true },
	slowmissile_weapon = { slowDamage = 1, onlySlow = true, scaleSlow = true },
	commadvrecon_slowbomb = { slowDamage = 5000, scaleSlow = true },
}

for i=1,#WeaponDefs do
	for weapon, data in pairs(weapons) do
		if WeaponDefs[i].name == weapon then array[i] = data end
	end
end

return array