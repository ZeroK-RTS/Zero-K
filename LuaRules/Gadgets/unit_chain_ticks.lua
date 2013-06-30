function gadget:GetInfo() return {
	name    = "chaining ticks",
	desc    = "secret buffs to sprung for being awesome (acuelly is chaining ticks)",
	author  = "sprung",
	date    = "2013",
	license = "PD",
	layer   = 0,
	enabled = false
} end

if (not gadgetHandler:IsSyncedCode()) then return end

local tickDefID = UnitDefNames.armtick.id
local tickWeaponID = WeaponDefNames.armtick_death.id
local spDestroyUnit = Spring.DestroyUnit

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, fullDamage, paralyzer, weaponID, attackerID)
	if((unitDefID == tickDefID) and (weaponID == tickWeaponID)) then
		spDestroyUnit(unitID, true, attackerID or nil)
	end
end