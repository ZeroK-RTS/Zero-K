function gadget:GetInfo()
  return {
    name      = "Empirical DPS",
    desc      = "Tool for determining real DPS values",
    author    = "Google Frog",
    date      = "12 Sep 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Spawn two units of opposing teams, set one to hold fire.

local last
local start, damage

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, unitDamage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
    --Spring.SetUnitExperience(attackerID,0.001)
    local frame = Spring.GetGameFrame()
    -- delay
    if last then
        --Spring.Echo(frame-last)
    end
    last = frame
    -- dps
    if start then
        --Spring.Echo(damage/(frame-start)*30)
        damage = damage + unitDamage
    else
        start = frame
        damage = unitDamage
    end
	Spring.Echo("Damage: " .. damage)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
    local frame = Spring.GetGameFrame()
    if start then
        Spring.Echo("Total DPS: " .. UnitDefs[unitDefID].health/(frame - start)*30)
        start = nil
    end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
    damage = 0
    start = nil
end
