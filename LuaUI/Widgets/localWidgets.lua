function widget:GetInfo()
  return {
    -- widget handler needs update when changing name
    name    = "Local Widgets Config",
    desc    = "GUI to enable/disable local widgets",
    author  = "SirMaverick",
    date    = "2009",
    license = "GNU GPL, v2 or later",
    layer   = 0,
    enabled = true,
  }
end

local Chili
local window0

local check1, check2

local vsx, vsy

local settings = {}

local localWidgetsAction = "localwidgetsconfig"

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end

function widget:Initialize()

  if (not WG.Chili) then
    widgetHandler:RemoveWidget()
    return
  end

  vsx, vsy = widgetHandler:GetViewSizes()
  Chili = WG.Chili
  window0 = nil

  widgetHandler:AddAction(localWidgetsAction, CreateWindow, nil, "t")

  if settings.localWidgets == nil then
    settings.localWidgets = false
  end
  if settings.localWidgetsFirst == nil then
    settings.localWidgetsFirst = false
  end

end

function widget:Shutdown()
  Close()
  widgetHandler:RemoveAction(localWidgetsAction)
end

function CreateWindow()

  if window0 ~= nil then return end

  local sizex, sizey = 250, 300

  window0 = Chili.Window:New({
    resizable = false,
    draggable = true,
    clientWidth  = sizex,
    clientHeight = sizey,
    x = (vsx - sizex)/2,
    y = (vsy - sizey)/2,
    parent = Chili.Screen0,
    caption = "Local Widgets Config",
   })

  local contentPane = Chili.StackPanel:New({
    width  = sizex,
    height = sizey,
    rows = 1,
    weightedResize = true,
    itemMargin  = {10, 15, 15, 10},
  })
  window0:AddChild(contentPane)
  local label = Chili.TextBox:New{
    text = "\255\255\1\1Enabling local widgets might break ZK's interface.\nDon't do it unless you know what you are doing.\nTo take effect you need to reload LuaUI.",
    fontsize = 14,
    weight = 1.5,
  }
  contentPane:AddChild(label)
  check1 = Chili.Checkbox:New{
    caption = "Enable local widgets",
    checked = settings.localWidgets,
  }
  check2 = Chili.Checkbox:New{
    caption = "Load local widgets first",
    checked = settings.localWidgetsFirst,
  }
  contentPane:AddChild(check1)
  contentPane:AddChild(check2)

  local button = Chili.Button:New({
    caption = "close",
    OnMouseUp = {Close}
  })
  contentPane:AddChild(button)

end

function Close()

  if window0 ~= nil then

    settings.localWidgets = check1.checked
    settings.localWidgetsFirst = check2.checked

    window0:Dispose()
    window0 = nil
  end
end

function widget:SetConfigData(data)
  settings = data
end

function widget:GetConfigData()
  return settings
end

