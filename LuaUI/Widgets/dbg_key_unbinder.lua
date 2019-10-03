--------------------------------------------------------------------------------
-- use this to force-unbind user's hotkeys where needed
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Key Unbinder 1", -- change name every time different keys need unbinding
    desc      = "Single-shot key unbinder",
    author    = "KingRaptor",
    date      = "2016.06.05",
    license   = "PD/CC0",
    layer     = math.huge,
    enabled   = true,
  }
end

local toUnbind = {"screenshot"}

function widget:Update()
  for i,action in ipairs(toUnbind) do
    Spring.Echo("[" .. widget:GetInfo().name .. "] Unbinding keys for action " .. action)
    WG.crude.SetHotkey(action,"")
  end
  Spring.SendCommands("luaui disablewidget " .. widget:GetInfo().name)
end
