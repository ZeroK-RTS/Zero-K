-- $Id$
function gadget:GetInfo()
  return {
    name      = "Com-Panion",
    desc      = "Spawns a Fac-In-A-Box alongside the commander.",
    author    = "Evil4Zerggin",
    date      = "6 January 2008",
    license   = "GNU LGPL, v2.1 or later",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

if (not gadgetHandler:IsSyncedCode()) then
  return false
end

local cost = 550
local startFrame = 8

local CreateUnit = Spring.CreateUnit
local GetUnitDefID = Spring.GetUnitDefID
local UseTeamResource = Spring.UseTeamResource
local GetUnitTeam = Spring.GetUnitTeam
local GetUnitPosition = Spring.GetUnitPosition
local GiveOrderToUnit = Spring.GiveOrderToUnit
local SetUnitPosition = Spring.SetUnitPosition

local CMD_IDLEMODE = CMD.IDLEMODE

local strSub = string.sub

function gadget:GameFrame(n)
  if Spring.GetModOptions().startingresourcetype ~= "facinabox" then
    gadgetHandler:RemoveGadget()
    return
  end
  
  if (n < startFrame) then return end
  
  local allUnits = Spring.GetAllUnits()
  
  for i=1,#allUnits do
    local unitID = allUnits[i]
    local unitDefID = GetUnitDefID(unitID)
    local unitDef = UnitDefs[unitDefID]
    if (unitDef.isCommander) then
      local teamID = GetUnitTeam(unitID)
      local x, y, z = GetUnitPosition(unitID)
      local prefix = strSub(unitDef.name, 1, 3)
      UseTeamResource(teamID, "m", cost)
      UseTeamResource(teamID, "e", cost)
      if (prefix == "arm") then
        local facInABox = CreateUnit("armfacinabox", x - 64, y, z, 0, teamID)
        GiveOrderToUnit(facInABox, CMD_IDLEMODE,{0},{})
      elseif (prefix == "cor") then
        local facInABox = CreateUnit("corfacinabox", x - 64, y, z, 0, teamID)
        GiveOrderToUnit(facInABox, CMD_IDLEMODE,{0},{})
      end
    end
  end
  
  gadgetHandler:RemoveGadget()
end
