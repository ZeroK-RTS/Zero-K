local array = {}

local weapons = {
	zeus_lightning = {damage = 250},
	panther_lightning = {damage = 160},
	bantha_lightning = {damage = 240},
	commadvsupport = {damage = 1600},
}

for i=1,#WeaponDefs do
	for weapon, data in pairs(weapons) do
		if WeaponDefs[i].name == weapon then array[i] = data end
	end
end

return array