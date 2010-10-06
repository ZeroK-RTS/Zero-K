--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_tooltip.lua
--  brief:   recolors some of the tooltip info
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Tooltip Replacement",
    desc      = "A colorful modification of the engine tooltip",
    author    = "trepan",
    date      = "Jan 8, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 12,
    enabled   = false,  --  loaded by default?
    handler   = true,
  }
end

-- modified by quantum to use the mod fonthandler and supress the default 
-- tooltip widget

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local glColor                 = gl.Color
local glText                  = gl.Text
local spGetCurrentTooltip     = Spring.GetCurrentTooltip
local spGetSelectedUnitsCount = Spring.GetSelectedUnitsCount
local spSendCommands          = Spring.SendCommands
local glTexture               = gl.Texture

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.h.lua")

local fontSize = 12
local ySpace   = 4
local yStep    = fontSize + ySpace
local gap      = 4

local fh = true
local fontName  = LUAUI_DIRNAME.."Fonts/FreeSansBold_14"
if (fh) then
  fh = fontHandler.UseFont(fontName)
end
if (fh) then
  fontSize  = fontHandler.GetFontSize()
  yStep     = fontHandler.GetFontYStep() + 2
end

local currentTooltip = ''

local found 

--------------------------------------------------------------------------------

local vsx, vsy = widgetHandler:GetViewSizes()

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end
--[[
local function Replace(widgetName)
  for i, widget in ipairs(widgetHandler.widgets) do
    if (widget:GetInfo().name == widgetName) then
      widgetHandler:RemoveWidget(widget)
      return
    end
  end
end
--]]
--------------------------------------------------------------------------------

function widget:Initialize()
  spSendCommands({"tooltip 0"})
  --if (Spring.GetGameSeconds() > 1) then
    --spSendCommands{"luaui enablewidget Tooltip"}
  --end
end


function widget:Shutdown()
  spSendCommands({"tooltip 1"})
end


--------------------------------------------------------------------------------

local magic = '\001'

function widget:WorldTooltip(ttType, data1, data2, data3)
--  do return end
  if (ttType == 'unit') then
    return magic .. 'unit #' .. data1
  elseif (ttType == 'feature') then
    return magic .. 'feature #' .. data1
  elseif (ttType == 'ground') then
    return magic .. ('ground @ %.1f %.1f %.1f'):format(data1, data2, data3)
  elseif (ttType == 'selection') then
    return magic .. 'selected ' .. spGetSelectedUnitsCount()
  else
    return 'WTF? ' .. '\'' .. tostring(ttType) .. '\''
  end
end


if (true) then
  widget.WorldTooltip = nil
end


--------------------------------------------------------------------------------
local replaced
  
function widget:DrawScreen()
  if ((widgetHandler.knownWidgets.Tooltip or {}).active) then
    Replace"Tooltip"
    spSendCommands{"tooltip 0"}
    replaced = true
  end
  if (Spring.GetGameSeconds() < 0.1 and not replaced) then
    widgetHandler:RemoveWidget(widget)
  end
  if (fh) then
    fh = fontHandler.UseFont(fontName)
    fontHandler.BindTexture()
    glColor(1, 1, 1)
  end
  local white = "\255\255\255\255"
  local bland = "\255\211\219\255"
  local mSub, eSub
  local tooltip = spGetCurrentTooltip()

  if (tooltip:sub(1, #magic) == magic) then
    tooltip = 'WORLD TOOLTIP:  ' .. tooltip
  end

  tooltip, mSub = tooltip:gsub(bland.."Me",   "\255\1\255\255Me")
  tooltip, eSub = tooltip:gsub(bland.."En", "  \255\255\255\1En")
  tooltip = tooltip:gsub("Hotkeys:", "\255\255\128\128Hotkeys:\255\128\192\255")
  tooptip = tooltip:gsub("a", "b")
  local unitTip = ((mSub + eSub) == 2)

  local disableCache = (fh and tooltip:find("^Pos"))
  if (disableCache) then
    fontHandler.DisableCache()
  end

  local i = 0
  for line in tooltip:gmatch("([^\n]*)\n?") do
    if (unitTip and (i == 0)) then
      line = "\255\255\128\255" .. line
    else
      line = "\255\255\255\255" .. line
    end
    
    if (fh) then
      fontHandler.DrawStatic(line, gap, gap + (4 - i) * yStep)
    else
      glText(line, gap, gap + (4 - i) * yStep, fontSize, "o")
    end

    i = i + 1
  end

  if (fh) then
    gl.Texture(false)
  end

  if (disableCache) then
    fontHandler.EnableCache()
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
