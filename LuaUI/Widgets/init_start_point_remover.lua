-- $Id: init_start_point_remover.lua 3171 2008-11-06 09:06:29Z det $
function widget:GetInfo()
  return {
    name      = "Start Point Remover",
    desc      = "Deletes your start point once the game begins",
    author    = "TheFatController and jK",
    date      = "Jul 11, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

function widget:Initialize()
  if (CheckForSpec()) then return false end
end

function CheckForSpec()
  if Spring.GetSpectatingState() or Spring.IsReplay() then
    widgetHandler:RemoveWidget()
    return true
  end
end

function widget:Update()
  local t = Spring.GetGameSeconds()
  if (t < 0.1) then return end

  local teamUnits = Spring.GetTeamUnits(Spring.GetMyTeamID())
  for _,unitID in ipairs(teamUnits) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    local unitDef   = UnitDefs[unitDefID]
    if (unitDef.isCommander) then
      local x, y, z = Spring.GetUnitPosition(unitID)
      Spring.MarkerErasePosition(x, y, z)
    end
  end
  widgetHandler:RemoveWidget()
end