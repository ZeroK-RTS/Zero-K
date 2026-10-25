
local flamerWeaponDefs = {}
local fireproof = {}

local function cpv(value)
	return value and tonumber(value)
end

local DEFAULT_BURN_TIME = 450
local DEFAULT_BURN_TIME_RANDOMNESS = 0.3
local DEFAULT_BURN_DAMAGE = 0.5

-- NOTE: fireStarter is divided by 100 somewhere in the engine between weapon defs and here.
for i = 1, #WeaponDefs do
	local wcp = WeaponDefs[i].customParams or {}
	if (wcp.setunitsonfire) then -- stupid tdf
		--// (fireStarter-tag: 1.0->always flame trees, 2.0->always flame units/buildings too) -- citation needed
	
		flamerWeaponDefs[i] = {
			burnTime = cpv(wcp.burntime) or WeaponDefs[i].fireStarter*DEFAULT_BURN_TIME,
			burnTimeRand = cpv(wcp.burntimerand) or DEFAULT_BURN_TIME_RANDOMNESS,
			burnTimeBase = 1 - (cpv(wcp.burntimerand) or DEFAULT_BURN_TIME_RANDOMNESS),
			burnChance = cpv(wcp.burnchance) or WeaponDefs[i].fireStarter/10,
			burnDamage = cpv(wcp.burndamage) or DEFAULT_BURN_DAMAGE,
		}
		
		flamerWeaponDefs[i].maxDamage = flamerWeaponDefs[i].burnDamage*flamerWeaponDefs[i].burnTime
	end
end

for i = 1, #UnitDefs do
	fireproof[i] = (UnitDefs[i].customParams.fireproof == "1")
end

return flamerWeaponDefs, fireproof
