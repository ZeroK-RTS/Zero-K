function widget:GetInfo()
  return {
    name      = "Missile Command Progress",
    desc      = "Displays visual progress bars for missile building",
    author    = "Amnykon",
    date      = "2026",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true,
    handler   = true,
  }
end

local missileCommands = {
  [39610] = true, -- EOS
  [39611] = true, -- Seismic
  [39612] = true, -- Shockley
  [39613] = true, -- Inferno
  [39614] = true, -- Reef
  [39615] = true, -- Trinity
  [39616] = true, -- Slow
}

local UPDATE_FREQUENCY = 0.25
local timer = UPDATE_FREQUENCY + 1

local function getMissileProgress(cmdID)
  local progressMap = {
    [39610] = {"tacnuke", "subtacmissile"},
    [39611] = {"seismic"},
    [39612] = {"empmissile"},
    [39613] = {"napalmmissile"},
    [39614] = {"shipcarrier"},
    [39615] = {"staticnuke"},
    [39616] = {"missileslow"},
  }

  local unitNames = progressMap[cmdID]
  if not unitNames then return 0 end

  local maxProgress = 0
  local teamUnits = Spring.GetTeamUnits(Spring.GetMyTeamID()) or {}

  for _, unitID in ipairs(teamUnits) do
    if not Spring.GetUnitIsDead(unitID) then
      local unitDefID = Spring.GetUnitDefID(unitID)
      if unitDefID then
        local unitDef = UnitDefs[unitDefID]
        if unitDef then
          for _, unitName in ipairs(unitNames) do
            if unitDef.name == unitName then
              local _, _, _, _, buildProgress = Spring.GetUnitHealth(unitID)
              if buildProgress and buildProgress < 1 then
                maxProgress = math.max(maxProgress, buildProgress)
              end
              break
            end
          end
        end
      end
    end
  end

  return maxProgress
end

function widget:Update(dt)
  timer = timer + dt
  if timer < UPDATE_FREQUENCY then
    return
  end
  timer = 0

  local integralMenu = widgetHandler:FindWidget("Chili Integral Menu")
  if not integralMenu then return end

  for cmdID in pairs(missileCommands) do
    local progress = getMissileProgress(cmdID)
    if progress > 0 and integralMenu.SetCmdButtonProgress then
      integralMenu:SetCmdButtonProgress(cmdID, progress)
    end
  end
end
