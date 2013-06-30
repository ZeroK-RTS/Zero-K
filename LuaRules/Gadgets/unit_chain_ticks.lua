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
local spValidUnitID = Spring.ValidUnitID

local ticks_to_pwn = {}
local table_size = 0

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, fullDamage, paralyzer, weaponID, attackerID)
	if ((unitDefID == tickDefID) and (weaponID == tickWeaponID)) then
		table_size = table_size + 1
		ticks_to_pwn[table_size] = unitID
	end
end

function gadget:GameFrame()
	if (table_size > 0) then
		for i = 1, table_size do
			if (spValidUnitID(ticks_to_pwn[i])) then -- one tick could get damaged twice 
				spDestroyUnit(ticks_to_pwn[i], true)
			end
			ticks_to_pwn[i] = nil
		end
		table_size = 0
	end
end