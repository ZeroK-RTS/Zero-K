-- $Id: unit_noselfpwn.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "No Self Pwn",
    desc      = "Prevents units from damaging themselves.",
    author    = "quantum",
    date      = "Feb 1, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Spring = Spring

local GetUnitHealth = Spring.GetUnitHealth
local SetUnitHealth = Spring.SetUnitHealth

local exceptionList = {
  "armsilo",
  "corsilo",
  "armemp",
  "cortron",
}
  
  
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

  
local exceptionMap  = {}
for _, unitName in pairs(exceptionList) do
  exceptionMap[UnitDefNames[unitName].id] = true
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
  if (unitID == attackerID and not exceptionMap[unitDefID]) then
    local health, _, paralyzeDamage = GetUnitHealth(unitID)
    if (paralyzer) then
      SetUnitHealth(unitID, {paralyze = paralyzeDamage + damage})
    else
      SetUnitHealth(unitID, health + damage)
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------