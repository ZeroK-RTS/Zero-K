local array = {}

------------------------
-- Config

local MAX_SLOW_FACTOR = 0.5
-- Max slow damage on a unit = MAX_SLOW_FACTOR * current health
-- Slowdown of unit = slow damage / current health
-- So MAX_SLOW_FACTOR is the limit for how much units can be slowed

local DEGRADE_TIMER = 0.5
-- Time in seconds before the slow damage a unit takes starts to decay

local DEGRADE_FACTOR = 0.04
-- Units will lose DEGRADE_FACTOR*(current health) slow damage per second

local UPDATE_PERIOD = 15 -- I'd prefer if this was not changed


local weapons = {
	slowmort_slowbeam = { slowDamage = 200, onlySlow = true, smartRetarget = 0.5, scaleSlow = true},
	cormak_blast = { slowDamage = 36, noDeathBlast = true, scaleSlow = true },
	slowmissile_weapon = { slowDamage = 1, onlySlow = true, scaleSlow = true },
	raveparty_violet_slugger = { slowDamage = 2500, noDeathBlast = true, scaleSlow = true },
	chicken_spidermonkey_web = { slowDamage = 30, onlySlow = true, smartRetarget = 0.5, scaleSlow = true},
}

-- reads from customParams and copies to weapons as appropriate - needed for procedurally generated comms
-- as always, need better way to handle if upgrades are desired!
local presets = {
	commrecon_slowbeam = { slowDamage = 450, onlySlow = true, smartRetarget = 0.5, scaleSlow = true},
	
	commrecon2_slowbeam = { slowDamage = 600, onlySlow = true, smartRetarget = 0.5, scaleSlow = true},
	commrecon2_slowbomb = { slowDamage = 1250, scaleSlow = true },
	
	commrecon3_slowbeam = { slowDamage = 750, onlySlow = true, smartRetarget = 0.5, scaleSlow = true},
	commrecon3_slowbomb = { slowDamage = 1500, scaleSlow = true },
	
	module_disruptorbeam = { slowDamage = 450, smartRetarget = 0.5, scaleSlow = true},
	module_disruptorbomb = { slowDamage = 1250, scaleSlow = true },
}

------------------------
-- Send the Config

for name,data in pairs(WeaponDefNames) do
	local custom = {scaleSlow = true}
	local cp = data.customParams
	if cp.timeslow_preset then
		weapons[name] = Spring.Utilities.CopyTable(presets[cp.timeslow_preset])
	elseif cp.timeslow_damagefactor then
		custom.slowDamage = cp.timeslow_damagefactor * (data.damages and data.damages[0] or 0)
		custom.onlySlow = (cp.timeslow_onlyslow == "1") or false
		custom.smartRetarget = cp.timeslow_smartretarge and tonumber(cp.timeslow_smartretarget) or nil
		weapons[name] = custom
	end
	if weapons[name] then array[data.id] = weapons[name] end
end

return array, MAX_SLOW_FACTOR, DEGRADE_TIMER*30/UPDATE_PERIOD, DEGRADE_FACTOR*UPDATE_PERIOD/30, UPDATE_PERIOD