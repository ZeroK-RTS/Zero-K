function widget:GetInfo()
  return {
    name    = "Map Draw Blocker",
    desc    = "blocks map draws from spamers",
    author  = "SirMaverick",
    date    = "2010",
    license = "GNU GPL, v2 or later",
    layer   = 0,
    enabled = false,
  }
end

local GetPlayerList = Spring.GetPlayerList
local GetPlayerInfo = Spring.GetPlayerInfo

-- see rts/System/BaseNetProtocol.h for message ids
local traffic = {
  NETMSG_MAPDRAW = {
    id = 31,
    playerdata = {},
  },
}

-- drawCmds[playerid] = {counters = {point = {}, line = {}, erase = {}}, labels = {...}, blocked = false}
local drawCmds = {}
local drawTypes = { "point", "line", "erase" }
local validTypes = {}
local counterNum = 10
local currentCounter = 1
local timeFrame = 1
local timerCmd = 0
local blocklimit = 5

local action_unblock = "mapdrawunblock"
local action_block = "mapdrawblock"
local action_gui = "mapdrawgui"
local action_list = "mapdrawlistblocked"

local Chili
local Button
local Control
local Label
local Checkbox
local Trackbar
local Window
local ScrollPanel
local StackPanel
local Grid
local TextBox
local Image
local screen0

-- traffic stats
local window0 = nil
-- MapDrawCmd
local window1 = nil

local timer = 0


-- helper functions
local function SetupDrawCounter(p)
  drawCmds[p] = {}
  drawCmds[p].blocked = false
  drawCmds[p].counters = {}
  drawCmds[p].labels = {}
  for j,s in ipairs(drawTypes) do
    drawCmds[p].counters[s] = {}
    for k=1,counterNum do
      drawCmds[p].counters[s][k] = 0
    end
  end
end

local function SetupDrawCounters()

  -- direct mapping
  for j,s in ipairs(drawTypes) do
    validTypes[s] = true
  end

  local playerlist = GetPlayerList()
  -- player ids start at 0
  for i,p in ipairs(playerlist) do
    SetupDrawCounter(p)
  end

end

local function ClearCurrentBuffer()
  local playerlist = GetPlayerList()
  -- player ids start at 0
  for i,p in ipairs(playerlist) do
    for j,s in ipairs(drawTypes) do
      -- FIXME/TODO no info for new players, needs engine change?
      -- even PlayerChanged is not called before you see player in GetPlayerList()
      if not drawCmds[p] then SetupDrawCounter(p) end
      drawCmds[p].counters[s][currentCounter] = 0
    end
  end
end

local function UpdateLabels()
  --if window1 then
    local playerlist = GetPlayerList()
    for i,p in ipairs(playerlist) do
      for j,s in ipairs(drawTypes) do
        local k = currentCounter
        local sum = 0
        for i=1,counterNum do
          sum = sum + drawCmds[p].counters[s][i]
          --[[a = a - 1
          a = (a-1)%counterNum
          a = a + 1]]
        end
        sum = sum / counterNum / timeFrame
        if window1 then
          drawCmds[p].labels[s]:SetCaption(string.format("%.2f", tostring(sum)))
        end
        if sum > blocklimit and s ~= "erase" and not drawCmds[p].blocked then
          drawCmds[p].blocked = true
          local name,_,_,teamid = Spring.GetPlayerInfo(p, false)
          Spring.Echo("Blocking map draw for " .. name .. "(" .. p .. ")")
        end
      end
    end
  --end
end

local function CreateDrawCmdWindow()
  local playerlist = GetPlayerList()

  window1 = Window:New{
    x = 500,
    y = 300,
    minWidth = 500,
	minHeight = 150,
    width  = 500,
    height = 100 + 50*(#playerlist),
    caption = "user map draw activity",
    parent = screen0,
  }

  local contentPane = Chili.StackPanel:New({
    parent = window1,
    width  = "100%",
    height = "100%",
    itemMargin  = {5, 5, 5, 5},
  })

  for p, data in pairs(drawCmds) do


      local name,_,_,teamid = Spring.GetPlayerInfo(p)

      local counters = data.counters

      local subpane = Chili.LayoutPanel:New({
        parent = contentPane,
        width  = "100%",
        --height = 20,
	rows = 1,
        horientation = "horizontal",
      })

      local label = Chili.Label:New{
        parent = subpane,
        caption = name,
        width = 200,
        autosize = false,
        fontsize = 12,
        font = {color = {Spring.GetTeamColor(teamid)},}
      }

    for i,s in ipairs(drawTypes) do
      local labelc = Chili.Label:New{
        parent = subpane,
        caption = "0",
        width = 50,
        autosize = false,
        fontsize = 12,
      }
      data.labels[s] = labelc
    end

  end

end


local function CreateTrafficWindow()
  local playerlist = GetPlayerList()

  window0 = Window:New{
    x = 500,
    y = 300,
    minWidth = 400,
	minHeight = 150,
    width  = 400,
    height = 100 + 50*(#playerlist),
    caption = "map draw statistic",
    parent = screen0,
  }

  local contentPane = Chili.StackPanel:New({
    parent = window1,
    width  = "100%",
    height = "100%",
    itemMargin  = {5, 5, 5, 5},
  })

  for msg, data in pairs(traffic) do
    local id = data.id

    for i,p in ipairs(playerlist) do

      local name,_,_,teamid = Spring.GetPlayerInfo(p, false)

      data.playerdata[p] = {}
      data.playerdata[p]["counters"] = {}
      local counters = data.playerdata[p].counters

      local subpane = Chili.LayoutPanel:New({
        parent = contentPane,
        width  = "100%",
        height = 50,
        rows = 1,
        horientation = "horizontal",
      })

      local label = Chili.Label:New{
        parent = subpane,
        caption = name,
        clientWidth = 200,
        autosize = false,
        fontsize = 12,
        font = {color = {Spring.GetTeamColor(teamid)},}
      }

      -- counter setup
      for i=1,5 do
        counters[i] = Spring.GetPlayerTraffic(p, data.id)
      end
      local labelc = Chili.Label:New{
        parent = subpane,
        caption = "0.00 B/s",
        --width = 50,
        autosize = false,
        fontsize = 12,
      }
      data.playerdata[p]["label"] = labelc
    end
  end
end


local function Output()

  if window0 then
    -- update traffic window
    local playerlist = GetPlayerList()
    for i,p in ipairs(playerlist) do
      local name,_,_,teamid = Spring.GetPlayerInfo(p, false)
      if name then
        for name, data in pairs(traffic) do
          local ret = Spring.GetPlayerTraffic(p, data.id)
          if ret > 0 then

            -- update counters
            local counters = data.playerdata[p].counters
            for i=5,2,-1 do
              counters[i] = counters[i-1]
            end
            counters[1] = ret

            local label = data.playerdata[p].label
            local sum = counters[1] - counters[5]
            label:SetCaption(string.format("%.2f B/s", tostring(sum/5)))

          end
        end
      end
    end
  end -- window0

end

function ActionUnBlock(_,_,parms)
  local p = tonumber(parms[1])
  if not p then return end
  local name = Spring.GetPlayerInfo(p, false)
  if name then
    drawCmds[p].blocked = false
    Spring.Echo("unblocking map draw for " .. name)
  end
end

function ActionBlock(_,_,parms)
  local p = tonumber(parms[1])
  if not p then return end
  local name = Spring.GetPlayerInfo(p, false)
  if name then
    drawCmds[p].blocked = true
    Spring.Echo("blocking map draw for " .. name)
  end
end

function ActionGUI()
  if window1 then
    window1:Dispose()
    window1 = nil
  else
    CreateDrawCmdWindow()
  end
end

function ActionList()
  local playerlist = GetPlayerList()
  for i,p in ipairs(playerlist) do
    if drawCmds[p].blocked then
      name = GetPlayerInfo(p, false)
      if name then
        Spring.Echo(name .. " (" .. p .. ")")
      end
    end
  end
end

-- callins


function widget:Initialize()

  SetupDrawCounters()

  if WG.Chili then

    Chili = WG.Chili
    Button = Chili.Button
    Control = Chili.Control
    Label = Chili.Label
    Checkbox = Chili.Checkbox
    Trackbar = Chili.Trackbar
    Window = Chili.Window
    ScrollPanel = Chili.ScrollPanel
    StackPanel = Chili.StackPanel
    Grid = Chili.Grid
    TextBox = Chili.TextBox
    Image = Chili.Image
    screen0 = Chili.Screen0

    --CreateTrafficWindow()

    --CreateDrawCmdWindow()

  end

  widgetHandler:AddAction(action_unblock, ActionUnBlock, nil, "t")
  widgetHandler:AddAction(action_block, ActionBlock, nil, "t")
  widgetHandler:AddAction(action_gui, ActionGUI, nil, "t")
  widgetHandler:AddAction(action_list, ActionList, nil, "t")

end


function widget:Shutdown()
  if window0 ~= nil then
    window0:Dispose()
  end
  if window1 ~= nil then
    window1:Dispose()
  end

  widgetHandler:RemoveAction(action_unlock)
  widgetHandler:RemoveAction(action_block)
  widgetHandler:RemoveAction(action_gui)
  widgetHandler:RemoveAction(action_list)

end


function widget:Update(dt)
  timer = timer + dt
  if timer > 1 then
    timer = 0
    Output()
  end

  timerCmd = timerCmd + dt
  if timerCmd > timeFrame then
    timerCmd = 0
    -- flip buffer
    currentCounter = currentCounter%counterNum+1
    ClearCurrentBuffer()
    UpdateLabels() -- window1
  end

end


--[[
point x y z str
line x y z x y z
erase: x y z r
]]
function widget:MapDrawCmd(playerID, cmdType, a, b, c, d, e, f)
  if drawCmds[playerID] and validTypes[cmdType] then    
    local val = drawCmds[playerID].counters[cmdType][currentCounter]
    val = val + 1
    drawCmds[playerID].counters[cmdType][currentCounter] = val
  end
  return drawCmds[playerID].blocked
end

