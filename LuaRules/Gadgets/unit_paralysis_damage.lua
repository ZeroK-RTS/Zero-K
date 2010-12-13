--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Para for damage weapons",
    desc      = "Adds para damage to some weapons",
    author    = "Google Frog",
    date      = "Apr, 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  no unsynced code
end

local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitHealth = Spring.SetUnitHealth
local spGetUnitDefID  = Spring.GetUnitDefID

local paralysisList = include("LuaRules/Configs/paralysis_defs.lua")
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
	if paralysisList[weaponID] then
		attackerID = attackerID or -1
		Spring.AddUnitDamage(unitID, paralysisList[weaponID].damage, 0, attackerID)
	end
	return damage
end