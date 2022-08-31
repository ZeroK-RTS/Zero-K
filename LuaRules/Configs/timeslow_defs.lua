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
	slowmissile_weapon = { slowDamage = 1, onlySlow = true, scaleSlow = true },
	vehdisable_disableray = { slowDamage = 30, scaleSlow = false },
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
	if cp.timeslow_damagefactor or cp.timeslow_damage or cp.timeslow_onlyslow then
		custom.slowDamage = cp.timeslow_damage or ((cp.timeslow_damagefactor or (cp.timeslow_onlyslow and 1)) * cp.raw_damage)
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
