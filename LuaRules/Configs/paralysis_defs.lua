local array = {}

local weapons = {
	armzeus_lightning = {damage = 240},
	panther_armlatnk_weapon = {damage = 160},
	armbanth_lightning = {damage = 240},
}

for i=1,#WeaponDefs do
	for weapon, data in pairs(weapons) do
		if WeaponDefs[i].name == weapon then array[i] = data end
	end
end

return array