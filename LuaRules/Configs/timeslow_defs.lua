local array = {}

local weapons = {
	slowmort_slowbeam = { slowDamage = 300, onlySlow = true, smartRetarget = true, scaleSlow = true},
	cormak_blast = { slowDamage = 12, noDeathBlast = true, scaleSlow = true },
	slowmissile_weapon = { slowDamage = 1, onlySlow = true, scaleSlow = true },
}

-- reads from customParams and copies to weapons as appropriate - needed for procedurally generated comms
-- as always, need better way to handle if upgrades are desired!
local presets = {
	commsupport_slowbeam = { slowDamage = 750, onlySlow = true, smartRetarget = true, scaleSlow = true},
	commsupport2_slowbeam = { slowDamage = 850, onlySlow = true, smartRetarget = true, scaleSlow = true},
	commsupport2_disruptorbeam = { slowDamage = 8000, scaleSlow = true},
	commrecon2_slowbomb = { slowDamage = 5000, scaleSlow = true },
}

--deep not safe with circular tables! defaults To false
function CopyTable(tableToCopy, deep)
	local copy = {}
		for key, value in pairs(tableToCopy) do
		if (deep and type(value) == "table") then
			copy[key] = CopyTable(value, true)
		else
			copy[key] = value
		end
	end
	return copy
end

for name,data in pairs(WeaponDefNames) do
	if data.customParams.timeslow_preset then
		weapons[name] = CopyTable(presets[data.customParams.timeslow_preset])
		Spring.Echo(name)
	end
	if weapons[name] then array[data.id] = weapons[name] end
end

return array