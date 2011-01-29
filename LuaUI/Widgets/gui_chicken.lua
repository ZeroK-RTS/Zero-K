--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chicken Panel",
    desc      = "Shows stuff",
    author    = "quantum",
    date      = "May 04, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = -9, 
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not Spring.GetGameRulesParam("difficulty")) then
  return false
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Spring          = Spring
local gl, GL          = gl, GL
local widgetHandler   = widgetHandler
local math            = math
local table           = table

local displayList
local panelFont       = LUAUI_DIRNAME.."Fonts/KOMTXT___16"
local waveFont        = LUAUI_DIRNAME.."Fonts/Skrawl_40"
local panelTexture    = ":n:"..LUAUI_DIRNAME.."Images/panel.tga"

local viewSizeX, viewSizeY = 0,0
local w               = 300
local h               = 210
local x1              = - w - 50
local y1              = - h - 50
local panelMarginX    = 30
local panelMarginY    = 40
local panelSpacingY   = 7
local waveSpacingY    = 7
local moving
local capture
local gameInfo
local waveY           = 800
local waveSpeed       = 0.2
local waveCount       = 0
local waveTime
local enabled

local guiPanel --// a displayList
local updatePanel

local red             = "\255\255\001\001"
local white           = "\255\255\255\255"

local VFSMODE      		= VFS.RAW_FIRST
local file 				= LUAUI_DIRNAME .. 'Configs/chickengui_config.lua'
local configs 			= VFS.Include(file, nil, VFSMODE)
local difficulties 		= configs.difficulties
local roostName 		= configs.roostName
local chickenColorSet 	= configs.colorSet

local rules = {
  "queenTime",
  "lagging",
  "difficulty",
  roostName .. "Count",
  roostName .. "Kills",
}

for chickenName,_ in pairs(chickenColorSet) do
  rules[#rules + 1] = chickenName .. 'Count'
  rules[#rules + 1] = chickenName .. 'Kills'
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


fontHandler.UseFont(panelFont)
local panelFontSize  = fontHandler.GetFontSize()
fontHandler.UseFont(waveFont)
local waveFontSize   = fontHandler.GetFontSize()


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--broken for some reason; saves wildly offscreen values
--[[
function widget:GetConfigData(data)
  return {
    position_x = x1,
    position_y = y1,
  }
end

function widget:SetConfigData(data)
	x1 = data.position_x or x1
	y1 = data.position_y or y1
end
--]]
local function MakeCountString(type)
  local t = {}
  local total = 0
  for chickenName,colorInfo in pairs(chickenColorSet) do
    local subTotal = gameInfo[chickenName..type]
    table.insert(t, colorInfo..subTotal)
    total = total + subTotal
  end
  local breakDown =  table.concat(t, white.."/")..white
  return ("Chicken %s: %d (%s)"):format(type, total, breakDown)
end


local function PanelRow(n)
  return panelMarginX, h-panelMarginY-(n-1)*(panelFontSize+panelSpacingY)
end


local function WaveRow(n)
  return n*(waveFontSize+waveSpacingY)
end


local function CreatePanelDisplayList()
  gl.PushMatrix()
  gl.Translate(x1, y1, 0)
  gl.CallList(displayList)
  fontHandler.DisableCache()
  fontHandler.UseFont(panelFont)
  fontHandler.BindTexture()
  local techLevel = ("Hive Anger : %d%%"):format(Spring.GetGameSeconds()/gameInfo.queenTime*100)
  fontHandler.DrawStatic(white..techLevel, PanelRow(1))
  fontHandler.DrawStatic(white..gameInfo.unitCounts, PanelRow(2))
  fontHandler.DrawStatic(white.."Burrow Count: "..gameInfo[roostName .. 'Count'], PanelRow(3))
  fontHandler.DrawStatic(white..gameInfo.unitKills, PanelRow(4))
  fontHandler.DrawStatic(white.."Burrow Kills: "..gameInfo[roostName .. 'Kills'], PanelRow(5))
  if (gameInfo.lagging == 1) then
    fontHandler.DrawStatic(red.."Anti-Lag Enabled", 120, h-170)
  else
    local s = white.."Mode: "..difficulties[gameInfo.difficulty]
    fontHandler.DrawStatic(s, 120, h-170)
  end
  gl.Texture(false)
  gl.PopMatrix()
end


local function Draw()
  if (not enabled)or(not gameInfo) then
    return
  end

  if (updatePanel) then
    if (guiPanel) then gl.DeleteList(guiPanel); guiPanel=nil end
    guiPanel = gl.CreateList(CreatePanelDisplayList)
    updatePanel = false
  end

  if (guiPanel) then
    gl.CallList(guiPanel)
  end

  if (waveMessage)  then
    local t = Spring.GetTimer()
    fontHandler.UseFont(waveFont)
    local waveY = viewSizeY - Spring.DiffTimers(t, waveTime)*waveSpeed*viewSizeY
    if (waveY > 0) then
      for i, message in ipairs(waveMessage) do
        fontHandler.DrawCentered(message, viewSizeX/2, waveY-WaveRow(i))
      end
    else
      waveMessage = nil
      waveY = viewSizeY
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function UpdateRules()
  if (not gameInfo) then
    gameInfo = {}
  end

  for _, rule in ipairs(rules) do
    gameInfo[rule] = Spring.GetGameRulesParam(rule) or 0
  end
  gameInfo.unitCounts = MakeCountString("Count")
  gameInfo.unitKills  = MakeCountString("Kills")

  updatePanel = true
end


local function MakeLine(chicken, n)
  if (n <= 0) then
    return
  end
  local humanName = UnitDefNames[chicken].humanName
  local color = chickenColorSet[chicken] or ""
  return color..n.." "..humanName.."s"
end

function ChickenEvent(chickenEventArgs)
  if (chickenEventArgs.type == "wave") then
    local chicken1Name       = chickenEventArgs[1]
    local chicken2Name       = chickenEventArgs[2]
    local chicken1Number     = chickenEventArgs[3]
    local chicken2Number     = chickenEventArgs[4]
    if (gameInfo[roostName .. 'Count'] < 1) then
      return
    end
    waveMessage    = {}
    waveCount      = waveCount + 1
    waveMessage[1] = "Wave "..waveCount 
    if (chicken1Name and chicken2Name and chicken1Name == chicken2Name) then
      if (chicken2Number and chicken2Number) then
        waveMessage[2] = 
          MakeLine(chicken1Name, (chicken2Number+chicken1Number)*gameInfo[roostName .. 'Count'])
      else
        waveMessage[2] =
          MakeLine(chicken1Name, chicken1Number*gameInfo[roostName .. 'Count'])
      end
    elseif (chicken1Name and chicken2Name) then
      waveMessage[2] = MakeLine(chicken1Name, chicken1Number*gameInfo[roostName .. 'Count'])
      waveMessage[3] = MakeLine(chicken2Name, chicken2Number*gameInfo[roostName .. 'Count'])
    end
    
    waveTime = Spring.GetTimer()
    
  -- table.foreachi(waveMessage, print)
  -- local t = Spring.GetGameSeconds() 
  -- print(string.format("time %d:%d", t/60, t%60))
  -- print""
  elseif (chickenEventArgs.type == "burrowSpawn") then
    UpdateRules()
  elseif (chickenEventArgs.type == "miniQueen") then
    waveMessage    = {}
    waveMessage[1] = "Here be dragons!"
	waveTime = Spring.GetTimer()
  elseif (chickenEventArgs.type == "queen") then
    waveMessage    = {}
    waveMessage[1] = "The Hive is angered!"
    waveTime = Spring.GetTimer()
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  displayList = gl.CreateList( function()
    gl.Color(1, 1, 1, 1)
    gl.Texture(panelTexture)
    gl.TexRect(0, 0, w, h)
  end)

  widgetHandler:RegisterGlobal("ChickenEvent", ChickenEvent)

  UpdateRules()
end


function widget:Shutdown()
  fontHandler.FreeFont(panelFont)
  fontHandler.FreeFont(waveFont)

  if (guiPanel) then gl.DeleteList(guiPanel); guiPanel=nil end

  gl.DeleteList(displayList)
  gl.DeleteTexture(panelTexture)
  widgetHandler:DeregisterGlobal("ChickenEvent")
end


local queenAngerOld = 0
function widget:GameFrame(n)
  if (n%60< 1) then
    UpdateRules()

    if (not enabled and n > 0) then
      enabled = true
    end

    local queenAnger = (Spring.GetGameSeconds()/gameInfo.queenTime*100)%2
    if (queenAnger~=queenAngerOld) then
      queenAngerOld = queenAnger
      updatePanel = true
    end
  end
end


function widget:DrawScreen()
  x1 = math.floor(x1 - viewSizeX)
  y1 = math.floor(y1 - viewSizeY)
  viewSizeX, viewSizeY = gl.GetViewSizes()
  x1 = viewSizeX + x1
  y1 = viewSizeY + y1

  Draw()
end


function widget:MouseMove(x, y, dx, dy, button)
  if (enabled and moving) then
    x1 = x1 + dx
    y1 = y1 + dy
    updatePanel = true
  end
end


function widget:MousePress(x, y, button)
  if (enabled and 
       x > x1 and x < x1 + w and
       y > y1 and y < y1 + h) then
    capture = true
    moving  = true
  end
  return capture
end

 
function widget:MouseRelease(x, y, button)
  if (not enabled) then
    return
  end
  capture = nil
  moving  = nil
  return capture
end


function widget:ViewResize(vsx, vsy)
  x1 = math.floor(x1 - viewSizeX)
  y1 = math.floor(y1 - viewSizeY)
  viewSizeX, viewSizeY = vsx, vsy
  x1 = viewSizeX + x1
  y1 = viewSizeY + y1
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

