
-- Tag things with unreliable if they often deal less damage against targets for which burst makes sense to measure.
-- For example Rogue is perfectly reliable at hitting statics and burst does not make sense against mobiles.
-- Skuttle always deals less than full damage against mobiles but burst is a useful thing to track against mobiles.

local NORMAL = 1
local AA = 2
local EMP_OR_DISARM = 3

local burstDefs = {}
VFS.Include("gamedata/unitdefs_pre.lua", { Shared = burstDefs })

local function processWeapon(weaponDef, targetCats)
	local cp = weaponDef.customParams
	if not cp.burst then
		return
	end

	local projectiles = tonumber(cp.statsprojectiles) or ((tonumber(cp.script_burst) or weaponDef.salvoSize) * weaponDef.projectiles)
	local rawDamage = cp.stats_damage * projectiles
	local burstDef = {
		damage = math.floor(rawDamage + 0.5), -- units often do extra .1 damage which would result in ugliness for 10+ units
		unreliable = (cp.burst == burstDefs.BURST_UNRELIABLE),
		class = (weaponDef.paralyzer or cp.disarmdamagemult) and EMP_OR_DISARM or NORMAL,
	}

	if targetCats then
		local isAA = true
		for cat in pairs (targetCats) do
			if cat ~= "fixedwing" and cat ~= "gunship" then
				isAA = false
				break
			end
		end

		if isAA then
			burstDef.class = AA
		end
	end

	return burstDef
end


local damageDefs = {}

for udid, ud in pairs(UnitDefs) do
	local burstDef
	for i = 1, #ud.weapons do
		local weapon = ud.weapons[i]
		burstDef = burstDef or processWeapon(WeaponDefs[weapon.weaponDef], weapon.onlyTargets)
		if burstDef then
			break
		end
	end

	if not burstDef then
		burstDef = processWeapon(WeaponDefNames[ud.deathExplosion:lower()])
	end

	if burstDef then
		damageDefs[udid] = burstDef
	end
end

return damageDefs
