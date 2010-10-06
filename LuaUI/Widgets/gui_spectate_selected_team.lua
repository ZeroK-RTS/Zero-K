function widget:GetInfo()
  return {
    name     = "Spectate Selected Team",
    desc     = "Automatically spectate team base on selected units.",
    author   = "SirMaverick",
    date     = "2010",
    license  = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

local spGetUnitTeam = Spring.GetUnitTeam
local spSendCommands = Spring.SendCommands

local specOld = false
local spec = false

function widget:Initialize()
  specOld = spec
  spec = Spring.GetSpectatingState()
  if spec == false then
    widgetHandler:RemoveCallIn("SelectionChanged")
  end
end

function widget:PlayerChanged()
  specOld = spec
  spec = Spring.GetSpectatingState()
  if not spec and specOld then
    widgetHandler:RemoveCallIn("SelectionChanged")
  elseif spec and not specOld then
    widgetHandler:UpdateCallIn("SelectionChanged")
  end
end

function widget:SelectionChanged(selection)
  if selection and #selection > 0 then
    -- I cannot read users mind, use first unit
    team = spGetUnitTeam(selection[1])
    if team then
      spSendCommands("specteam "..team)
    end
  end
end

