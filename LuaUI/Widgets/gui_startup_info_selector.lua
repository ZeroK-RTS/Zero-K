function widget:GetInfo()
  return {
    name     = "Startup Info and Selectior",
    desc     = "Shows important information and options on startup.",
    author   = "SirMaverick",
    date     = "2009,2010",
    license  = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

local vsx, vsy

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end

local Chili
local Window
local screen0
local Image
local Button

local modoptions = Spring.GetModOptions()

local mainWindow

local actionShow = "showstartupinfoselector"

local optionData = include("Configs/startup_info_selector.lua")

--local gameDate = os.date(t)
--if (gameDate.month == 4) and (gameDate.day == 1) then optionData.communism.sound = "LuaUI/Sounds/communism/tetris.wav" end

-- set poster size (3/4 ratio)
local function posterSize(num)
  if num < 2 then
    local a,b = 450, 600
    -- for those who play with 800x600; but consider card upgrade!
    if b > 0.8*vsy then
      local scale = 0.8*vsy/b
      a = scale * a
      b = scale * b
    end
    return a, b, 60
  else
    -- scale to 80% of screen width
    local spacex = vsx * 0.8 / num
    if spacex < 300 then
      return spacex, spacex*4/3, 60
    else
      return 300, 400, 60
    end
  end
end

function widget:Initialize()

  if (not WG.Chili) then
    widgetHandler:RemoveWidget()
    return
  end

  -- chili setup
  Chili = WG.Chili
  Window = Chili.Window
  screen0 = Chili.Screen0
  Image = Chili.Image
  Button = Chili.Button

  vsx, vsy = widgetHandler:GetViewSizes()

  BindCallins()

  widgetHandler:AddAction(actionShow, CreateWindow, nil, "t")

  -- create the window
  CreateWindow()

end

function CreateWindow()

  -- count otpions
  local actived = 0
  for name,option in pairs(optionData) do
    if option:enabled() then
      actived = actived + 1
    end
  end

  local posterx, postery, buttonspace = posterSize(actived)

  -- create window if necessarey
  if actived > 0 then

    mainWindow = Window:New{
      resizable = false,
      draggable = false,
      clientWidth  = posterx*actived,
      clientHeight = postery + buttonspace,
      x = (vsx - posterx*actived)/2,
      y = (vsy - postery - buttonspace)/2,
      parent = screen0,
      caption = "Mod Options Reminder",
    }

    -- add posters
    local i = 0
    for name,option in pairs(optionData) do
      if option:enabled() then
        local image = Image:New{
          parent = mainWindow,
          file = option.poster,
          tooltip = option.tooltip,
          width = posterx,
          height = postery,
          x = i*posterx,
          padding = {1,1,1,1},
          OnClick = {option.button}
        }
        local buttonWidth = posterx*2/3
        if (option.button ~= nil) then 
          local button = Button:New {
            parent = mainWindow,
            x = i*posterx + (posterx - buttonWidth)/2,
            y = postery,
            caption = option.tooltip,
            width = buttonWidth,
            height = 30,
            padding={1,1,1,1},
            OnMouseUp = {option.button},
          }
        end 
        i = i + 1
      end
    end

    local cbWidth = posterx*actived*0.75
    local closeButton = Button:New{
      parent = mainWindow,
      caption = "close",
      width = cbWidth,
      height = 30,
      x = (posterx*actived - cbWidth)/2,
      y = postery + (buttonspace)/2,
      OnMouseUp = {Close}
	}

  end
end

function Close()
	mainWindow:Dispose()
end
 
 
function widget:Shutdown()

  if mainWindow then
    mainWindow:Dispose()
  end

  widgetHandler:RemoveAction(actionShow)

end

function widget:GameStart()
  if mainWindow then
    mainWindow:Dispose()
  end
end

function UpdateCallins()
  widgetHandler:UpdateCallIn('DrawScreen')
  widgetHandler:UpdateCallIn('DrawScreen')
end

function BindCallins()
  widget.DrawScreen = _DrawScreen
  UpdateCallins()
end

function UnbindCallins()
  widget.DrawScreen = nil
  UpdateCallins()
end

-- use to play communism (always enabled) sound only at game start
function _DrawScreen()
  if Spring.GetGameSeconds() < 0.1 then
    Spring.PlaySoundFile("LuaUI/Sounds/communism/sovnat1.wav", 1)
  end
  UnbindCallins()
end

