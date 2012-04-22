-- $Id: ca_layout.lua 4099 2009-03-16 05:18:45Z jk $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    ca_layout.lua
--  brief:   CA LayoutButtons() routines heavily based on trepan default handler
--  author:  jK (heavily based on code by trepan)
--
--  Copyright (C) 2008,2009,2010.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "CALayout",
    desc      = "Adds LuaUI buttons (used by retreat and transportAI widget)",
    author    = "jK",
    date      = "2008,2009,2010",
    license   = "GNU GPL, v2 or later",
    layer     = 10,
    enabled   = false,
    handler   = true,
    alwaysStart = false,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.h.lua")

local langSuffix = Spring.GetConfigString('Language', 'fr')
local l10nName = 'L10N/commands_' .. langSuffix .. '.lua'
local success, translations = pcall(VFS.Include, l10nName)
if (not success) then
  translations = nil
end


local ecoTex     = ":n:bitmaps/icons/frame_eco.png"
local consTex    = ":n:bitmaps/icons/frame_cons.png"
local unitTex    = ":n:bitmaps/icons/frame_unit.png"
local diffTex    = ":n:bitmaps/icons/frame_diff.png"
local frameTex   = ":n:bitmaps/icons/frame_slate.png"
local FrameScale = "&0.091x0.1213&"
local PageNumTex = ":n:bitmaps/icons/frame_slate.png"

local PageNumCmd = {
  name    = "1",
  texture = PageNumTex,
  tooltip = "Active Page Number\n(click to toggle buildiconsfirst)",
  actions = { "buildiconsfirst", "firstmenu" }
}

local DGUNCmd = {
  id      = CMD.DGUN,
  type    = CMDTYPE.ICON_UNIT_OR_MAP,
  name    = 'DGun',
  tooltip = "DGun: Attacks using the units special weapon",
  cursor  = 'DGun',
  action  = 'dgun',
  pos     = {CMD.ATTACK},
}

local ToggleBuildOptsCmd = {
  name    = "Toggle\nBuild\nOptions",
  texture = frameTex,
  tooltip = "Hides/Shows BuildOptions\n\255\128\001\001(Please test the GestureMenu before you reenable those,\nto do so select a con and press [b])",
  actions = { "layout buildopt" }
}

local hideCmds = {
  [CMD.AISELECT]=true, [CMD.SELFD]=true, [CMD.AUTOREPAIRLEVEL]=false,
}

local hideCmds_minimal = {
  [CMD.STOP]=true,     [CMD.GUARD]=true,   [CMD.WAIT]=true,
  [CMD.REPAIR]=true,   [CMD.RECLAIM]=true, 
  [CMD.AISELECT]=true, [CMD.SELFD]=true,   [CMD.AUTOREPAIRLEVEL]=false,
  [CMD.MOVE]=true,     [CMD.PATROL]=true,  [CMD.FIGHT]=true,
  [CMD.ATTACK]=true,   [CMD.DGUN]=true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

WG.Layout = {colorized = true, minimal = false, hideUnits = true}

function widget:GetConfigData()
  return WG.Layout
end

function widget:SetConfigData(data)
  WG.Layout = data
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- speed ups
--

local tinsert = table.insert
local floor   = math.floor
local abs     = math.abs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SortCustomCommands(commands,customCmds,commandsMap)
  local count = #commandsMap
  for i=1,#commands do
    count=count+1
    commandsMap[count] = i
  end

  for i=1,#customCmds do
    local cc = customCmds[i]

    commands[cc.cmdDescID] = cc

    local pos  = cc.pos
    if (pos) then
      local npos = #pos
      for n=1,npos+1 do
        if (n<=npos) then
          local posCmd = pos[n]
          for j=1,#commandsMap do
            if (commands[ commandsMap[j] ].id==posCmd) then
              tinsert(commandsMap,j,cc.cmdDescID)
              posCmd = nil
              break
            end
          end
          if (not posCmd) then break end
        else
          for j=1,#commandsMap+1 do
            if (j>#commandsMap) then
              if (#commandsMap>2) then
                tinsert(commandsMap,#commandsMap-2,cc.cmdDescID)
              end
              break
            end
            if (commands[ commandsMap[j] ].id<0) then
              tinsert(commandsMap,j,cc.cmdDescID)
              break
            end
          end
        end
      end
    end

    --// remove api keys (custom keys are prohibited in the engine handler)
    cc.pos       = nil
    cc.cmdDescID = nil
    cc.params    = nil
  end
end


local function GetBuildIconFrame(udef) 
  if (udef.builder and udef.speed>0) then
    return consTex

  elseif (udef.builder or udef.isFactory) then
    return consTex

  elseif (udef.weapons[1] and udef.isBuilding) then
    return unitTex

  elseif ((udef.totalEnergyOut>0) or (udef.customParams.ismex) or (udef.name=="armwin" or udef.name=="corwin")) then
    return ecoTex

  elseif (udef.weapons[1] or udef.canKamikaze) then
    return unitTex

  else
    return diffTex
  end
end 


local function GetBuildIconBW(udid,udef)
  return FrameScale..":l:unitpics_bw/"..udef.name..".png"..'&'..GetBuildIconFrame(udef)
end


local function GetBuildIconColorized(udid,udef)
  return FrameScale..'#'..(udid)..'&'..GetBuildIconFrame(udef)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CADefaultHandler(xIcons, yIcons, cmdCount, commands)
  widgetHandler.commands   = commands
  widgetHandler.commands.n = cmdCount
  widgetHandler:CommandsChanged()

  if (xIcons == 2 and yIcons == 8) then 
    xIcons = 4 -- if user is using default, set columns to 4
  end 
  
  if (cmdCount <= 0) then
    return "", xIcons, yIcons, {}, {}, {}, {}, {}, {}, {}, {}
  end
  
  local menuName      = ''
  local removeCmds    = {}
  local customCmds    = widgetHandler.customCommands
  local onlyTexCmds   = {}
  local reTexCmds     = {}
  local reNamedCmds   = {}
  local reTooltipCmds = {}
  local reParamsCmds  = {}
  local iconList      = {}

  local hideCmds = (WG.Layout.minimal and hideCmds_minimal) or hideCmds
  local showUnits = not WG.Layout.hideUnits 

  local cmdsFirst = (commands[1].id >= 0)
  local ipp = (xIcons * yIcons)  --// iconsPerPage

  local commandsCleaned = {}
  local cnt = 1
  for cmdSlot = 1, cmdCount do
    local c = commands[cmdSlot]
    if (c.id == CMD.DGUN) then
      --// DGUN FIX
      tinsert(removeCmds,cmdSlot)
      cmdCount = cmdCount - 1
      tinsert(customCmds, DGUNCmd)
    else
      commandsCleaned[cnt] = c
      cnt = cnt + 1
    end
  end
  commands = commandsCleaned

  --// page switching buttons
  local prevCmd = cmdCount - 1
  local nextCmd = cmdCount - 0
  local prevPos = ipp - xIcons
  local nextPos = ipp - 1
  if (prevCmd >= 1) then reTexCmds[prevCmd] = frameTex end
  if (nextCmd >= 1) then reTexCmds[nextCmd] = frameTex end

  --// page indicator ("1","2",etc.)
  local pageNumCmd = -1
  local pageNumPos = (prevPos + nextPos) / 2
  if (xIcons > 2) then
    local color
    if (commands[1].id < 0) then color = GreenStr else color = RedStr end
    local pageNum = '' .. (Spring.GetActivePage() + 1) .. ''
    PageNumCmd.name = color .. '   ' .. pageNum .. '   '
    tinsert(customCmds, PageNumCmd)
    pageNumCmd = cmdCount + #customCmds
  end


  --if (xIcons > 2) then
    tinsert(customCmds, ToggleBuildOptsCmd)
  --end

  --// preprocess the Custom Commands
  for i=1,#customCmds do
    local cc = customCmds[i]
    cc.cmdDescID = cmdCount+i

    if (cc.params) then
      if (not cc.actions) then --// workaround for params
        local params = cc.params
        for i=1,#params+1 do
          params[i-1] = params[i]
        end
        cc.actions = params
      end
      reParamsCmds[cc.cmdDescID] = cc.params
    end
  end

  --// insert custom buttons in the panel
  local commandsMap = {}
  SortCustomCommands(commands,customCmds,commandsMap)

  local hasBuildOpt = false

  local pos = 0;
  local firstSpecial = (xIcons * (yIcons - 1))

  for cmdSlot = 1, #commandsMap do
    local commandIdx = commandsMap[cmdSlot]
    if (commandIdx~=prevCmd and commandIdx~=nextCmd) then

      --// fill the last row with special buttons
      while ((pos%ipp) >= firstSpecial) do
        pos = pos + 1
      end
      local onLastRow = (abs(pos%ipp) < 0.1)

      if (onLastRow) then
        local pageStart = floor(ipp * floor(pos / ipp))
        if (pageStart == ipp) then
          iconList[prevPos] = prevCmd
          iconList[nextPos] = nextCmd
          if (pageNumCmd > 0) then
            iconList[pageNumPos] = pageNumCmd
          end
        end
        if (pageStart > 0) then
          iconList[prevPos + pageStart] = prevCmd
          iconList[nextPos + pageStart] = nextCmd
          if (pageNumCmd > 0) then
            iconList[pageNumPos + pageStart] = pageNumCmd
          end
        end
      end

      --// add the command icons to iconList
      local cmd = commands[commandIdx]

      if (cmd and cmd.id<0) then
         hasBuildOpt = true
      end

      if
        (cmd) and (not cmd.hidden) and (not hideCmds[cmd.id]) and ((cmd.id >= 0) or showUnits )
      then
        iconList[pos] = commandIdx
        pos = pos + 1

        local cmdTex = cmd.texture or ""
        if (#cmdTex > 0) then
          if (cmdTex:byte(1) ~= 38) then  --// '&' == 38
            reTexCmds[commandIdx] = FrameScale..cmdTex..'&'..frameTex
          end
        else
          if (cmd.id >= 0) then
            reTexCmds[commandIdx] = frameTex
          else
            local udef = UnitDefs[-cmd.id]
            if (WG.Layout.colorized) then
              reTexCmds[commandIdx] = GetBuildIconColorized(-cmd.id,udef)
            else
              reTexCmds[commandIdx] = GetBuildIconBW(-cmd.id,udef)
            end
            tinsert(onlyTexCmds, commandIdx)
          end
        end

        if (translations) then
          local trans = translations[cmd.id]
          if (trans) then
            reTooltipCmds[commandIdx] = trans.desc
            if (not trans.params) then
              if (cmd.id ~= CMD.STOCKPILE) then
                reNamedCmds[commandIdx] = trans.name
              end
            else
              local num = tonumber(cmd.params[1])
              if (num) then
                num = (num + 1)
                cmd.params[num] = trans.params[num]
                reParamsCmds[commandIdx] = cmd.params
              end
            end
          end
        end
      end

    end
  end --// for cmdSlot = 1, #commandsMap do

  if (hasBuildOpt) then
    --iconList[#iconList+1] = cmdCount + #customCmds
	-- spring bug prohibits this
	-- http://springrts.com/mantis/view.php?id=1991
  end

  return menuName, xIcons, yIcons,
         removeCmds, customCmds,
         onlyTexCmds, reTexCmds,
         reNamedCmds, reTooltipCmds, reParamsCmds,
         iconList
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function HandleLayoutCommands(_,_,words)
  local state = (words[1]=="1" and true)or(words[1]=="0" and false)or nil
  local cmd = words[1]

  if (cmd == "buildopt") then
    WG.Layout.hideUnits = state or (not WG.Layout.hideUnits)
  elseif (cmd == "minimal") then
    WG.Layout.minimal = state or (not WG.Layout.minimal)
  elseif (cmd == "bw") then
    state = state and (not state)
    WG.Layout.colorized = state or (not WG.Layout.colorized)
  end

  Spring.ForceLayoutUpdate()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  widgetHandler:ConfigLayoutHandler(CADefaultHandler)
  Spring.ForceLayoutUpdate()

  WG.GetBuildIconFrame = GetBuildIconFrame
  --widgetHandler:RemoveWidget(self)

  widgetHandler.actionHandler:AddAction(widget,"layout", HandleLayoutCommands, nil, "t");
end


function widget:Shutdown()
  widgetHandler:ConfigLayoutHandler(nil)
  Spring.ForceLayoutUpdate()
  widgetHandler.actionHandler:RemoveAction(widget,"layout")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
