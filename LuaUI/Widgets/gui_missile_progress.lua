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
  [39610] = true,
  [39611] = true,
  [39612] = true,
  [39613] = true,
  [39614] = true,
  [39615] = true,
  [39616] = true,
}

local UPDATE_FREQUENCY = 0.25
local timer = UPDATE_FREQUENCY + 1
local buttonCache = {}

local function findButtonsByCommand()
  local screen = WG.Chili.Screen0
  if not screen then return end

  local function searchChildren(control)
    if not control then return end

    if control.cmdID and missileCommands[control.cmdID] then
      buttonCache[control.cmdID] = control
    end

    if control.children then
      for _, child in ipairs(control.children) do
        searchChildren(child)
      end
    end
  end

  if screen.children then
    for _, child in ipairs(screen.children) do
      searchChildren(child)
    end
  end
end

function widget:Update(dt)
  timer = timer + dt
  if timer < UPDATE_FREQUENCY then
    return
  end
  timer = 0

  findButtonsByCommand()

  for cmdID in pairs(missileCommands) do
    local progress = WG.missileProgress and WG.missileProgress[cmdID] or 0
    local button = buttonCache[cmdID]

    if button and button.SetProgressBar then
      button:SetProgressBar(progress)
    end
  end
end
