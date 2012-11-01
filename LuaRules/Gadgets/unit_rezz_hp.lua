-- $Id: unit_terraform.lua 3299 2008-11-25 07:25:57Z google frog $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Rezz Hp changer",
    desc      = "Sets rezzed units to full hp",
    author    = "Google Frog, modified by Rafal",
    date      = "Nov 30, 2008",
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Speedups

local spSetUnitHealth = Spring.SetUnitHealth
local spGetUnitHealth = Spring.GetUnitHealth
local CMD_RESURRECT   = CMD.RESURRECT

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local units = {}
local unitsCount = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Engine multiplies rezzed unit HP by 0.05 just after UnitCreated so their HP has to be changed 1 frame later

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
  if (builderID) then
    local command = Spring.GetCommandQueue(builderID, 1)[1]

    if (command and command.id == CMD_RESURRECT) then
      --spSetUnitHealth(unitID, maxHealth)  -- does nothing, hp overwritten by engine
      unitsCount = unitsCount + 1
      units[unitsCount] = unitID
      if GG.Awards then
        GG.Awards.UnitResurrected (unitDefID, teamID)
      end
    end
  end
end

function gadget:GameFrame(n)
  if (unitsCount ~= 0) then
    for i = 1, unitsCount do
      local health, maxHealth = spGetUnitHealth(units[i])
      if maxHealth then
        spSetUnitHealth(units[i], maxHealth)
      end

      units[i] = nil
    end
    unitsCount = 0
  end
end