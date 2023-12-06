function gadget:GetInfo()
	return {
		name      = "Invincibility",
		desc      = "Implements invicibility and neutrality that persists over luarules reload and save/load (thanks to the unitRulesParam).",
		author    = "GoogleFrog",
		date      = "5 August 2017",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return --NO UNSYNCED
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local invincibleUnits = {}
local LOS_ACCESS = {inlos = true}

local function SetUnitInvincible(unitID, newInvincible)
	invincibleUnits[unitID] = newInvincible
	Spring.SetUnitRulesParam(unitID, "invincible", newInvincible and 1 or nil, LOS_ACCESS)
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if invincibleUnits[unitID] then
		return 0
	end
	return damage
end

function gadget:UnitDestroyed(unitID)
	if invincibleUnits[unitID] then
		invincibleUnits[unitID] = nil
	end
end

function gadget:Initialize(unitID)
	GG.SetUnitInvincible = SetUnitInvincible
	local unitList = Spring.GetAllUnits()
	for i = 1, #unitList do
		if Spring.GetUnitRulesParam(unitList[i], "invincible") then
			SetUnitInvincible(unitList[i], true)
		end
	end
end
