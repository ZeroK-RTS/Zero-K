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
	gunshipkrow_timedistort = { slowDamage = 100, onlySlow = true, scaleSlow = true },
	slowmissile_weapon = { slowDamage = 1, onlySlow = true, scaleSlow = true },
	vehdisable_disableray = { slowDamage = 30, scaleSlow = false },
}

-- reads from customParams and copies to weapons as appropriate - needed for procedurally generated comms
-- as always, need better way to handle if upgrades are desired!
local presets = {
	commrecon_slowbeam = { slowDamage = 450, onlySlow = true, smartRetarget = 0.33, scaleSlow = true},
	
	commrecon2_slowbeam = { slowDamage = 600, onlySlow = true, smartRetarget = 0.33, scaleSlow = true},
	commrecon2_slowbomb = { slowDamage = 1250, scaleSlow = true },
	
	commrecon3_slowbeam = { slowDamage = 750, onlySlow = true, smartRetarget = 0.33, scaleSlow = true},
	commrecon3_slowbomb = { slowDamage = 1500, scaleSlow = true },
	
	module_disruptorbeam = { slowDamage = 450, smartRetarget = 0.33, scaleSlow = true},
	module_disruptorbomb = { slowDamage = 1250, scaleSlow = true },
}

------------------------
-- Send the Config

local function Process(weaponData)
	if weaponData.overslow then
		-- Convert from extra frames into extra slow factor
		weaponData.overslow = weaponData.overslow*DEGRADE_FACTOR/30
	end
	return weaponData
end

local weaponArray = {}

for name, data in pairs(WeaponDefNames) do
	local custom = {scaleSlow = true}
	local cp = data.customParams
	if cp.timeslow_preset then
		weapons[name] = Spring.Utilities.CopyTable(presets[cp.timeslow_preset])
	elseif cp.timeslow_damagefactor or cp.timeslow_damage then
		custom.slowDamage = cp.timeslow_damage or (cp.timeslow_damagefactor * cp.raw_damage)
		custom.overslow = cp.timeslow_overslow_frames
		custom.onlySlow = (cp.timeslow_onlyslow) or false
		custom.smartRetarget = cp.timeslow_smartretarget and tonumber(cp.timeslow_smartretarget) or nil
		custom.smartRetargetHealth = cp.timeslow_smartretargethealth and tonumber(cp.timeslow_smartretargethealth) or nil
		weapons[name] = custom
	end
	
	if weapons[name] then
		weaponArray[data.id] = Process(weapons[name])
		weaponArray[data.id].rawDamage = tonumber(cp.raw_damage)
	end
end

return weaponArray, MAX_SLOW_FACTOR, DEGRADE_TIMER*30/UPDATE_PERIOD, DEGRADE_FACTOR*UPDATE_PERIOD/30, UPDATE_PERIOD
