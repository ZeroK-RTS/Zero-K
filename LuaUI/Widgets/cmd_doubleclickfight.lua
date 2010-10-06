-- $Id: cmd_doubleclickfight.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Double-Click Fight",
    desc      = "Binds right double-click to the fight command.",
    author    = "quantum",
    date      = "July 5, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 9999, -- before the custom formations widget
    enabled   = false,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local CMD_FIGHT     = CMD.FIGHT
local CMD_MOVE      = CMD.MOVE
local CMD_OPT_ALT   = CMD.OPT_ALT
local CMD_OPT_CTRL  = CMD.OPT_CTRL
local CMD_OPT_RIGHT = CMD.OPT_RIGHT
local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local CMD_REMOVE    = CMD.REMOVE
local CMD_SET_WANTED_MAX_SPEED = CMD.SET_WANTED_MAX_SPEED

local spDiffTimers           = Spring.DiffTimers
local spGetCommandQueue      = Spring.GetCommandQueue
local spGetConfigInt         = Spring.GetConfigInt
local spGetInvertQueueKey    = Spring.GetInvertQueueKey
local spGetModKeyState       = Spring.GetModKeyState
local spGetMouseMiniMapState = Spring.GetMouseMiniMapState
local spGetSelectedUnits     = Spring.GetSelectedUnits
local spGetTimer             = Spring.GetTimer
local spGiveOrder            = Spring.GiveOrder
local spGiveOrderToUnit      = Spring.GiveOrderToUnit
local spSelectUnitArray      = Spring.SelectUnitArray
local spTraceScreenRay       = Spring.TraceScreenRay

local abs = math.abs


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local tolerance = spGetConfigInt('DoubleClickTime', 200) * 0.001
local mouseTolerance = 4

local timer = spGetTimer()
local mouseX = nil
local mouseY = nil


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetOpts()
  local a,c,m,s = spGetModKeyState()
  s = (s ~= spGetInvertQueueKey())
  a = (a or m) -- GuiHandler capatibility
  local opts = CMD_OPT_RIGHT
      + (a and CMD_OPT_ALT   or 0)
      + (c and CMD_OPT_CTRL  or 0)
      + (s and CMD_OPT_SHIFT or 0)
  return opts
end


local function RemoveMove(unitID)
  local queue = spGetCommandQueue(unitID)
  local qLast = #queue
  if (qLast < 1) then
    return false
  end

  if (queue[qLast].id == CMD_MOVE) then
    spGiveOrderToUnit(unitID, CMD_REMOVE, { queue[qLast].tag }, 0)
    return true
  elseif (queue[qLast].id == CMD_SET_WANTED_MAX_SPEED) then
    if (qLast < 2) then
      return false
    end
    local qMove = (qLast - 1)
    if (queue[qMove].id == CMD_MOVE) then
      spGiveOrderToUnit(
        unitID, CMD_REMOVE, { queue[qLast].tag, queue[qMove].tag }, 0
      )
      return true
    end
  end
  return false
end


local function MinimapCoords(mx, my)
  local px, py, sx, sy, min, max = Spring.GetMiniMapGeometry()
  if ((not min) and
      (mx >= px) and (mx <= (px + sx)) and
      (my >= py) and (my <= (py + sy))) then
    local fx = (mx - px) / sx
    local fz = (my - py) / sy
    local x =      fx  * Game.mapSizeX
    local z = (1 - fz) * Game.mapSizeZ
    local y = Spring.GetGroundHeight(x, z)
    return { x, y, z }
  end
  return nil
end


local function GetGroundCoords(x, y)
  local coords = MinimapCoords(x, y)
  if (coords) then
    return coords
  end
  local category, args = spTraceScreenRay(x, y)
  if (category == 'ground') then
    return args
  end
  return nil
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:MousePress(x, y, button)
  if ((button == 3) or (button == -3)) then -- right mouse button
    local coords = GetGroundCoords(x, y)
    if (coords) then
      local now = spGetTimer()
      if ((spDiffTimers(now, timer) <= tolerance) and
          mouseX and (math.abs(mouseX - x) <= mouseTolerance) and
          mouseY and (math.abs(mouseY - y) <= mouseTolerance)) then
        return true
      else
        timer = now
        mouseX = x
        mouseY = y
      end
    end
  end
  return false
end


function widget:MouseRelease(x, y, button)
  local coords = GetGroundCoords(x, y)
  if (not coords) then
    return
  end

  local units = {}
  local selUnits = spGetSelectedUnits()
  for _, unitID in ipairs(selUnits) do
    if (RemoveMove(unitID)) then
      units[#units + 1] = unitID
    end
  end

  local newSel = (#selUnits ~= #units)
  if (newSel) then
    spSelectUnitArray(units)
  end
  spGiveOrder(CMD_FIGHT, coords, GetOpts())
  if (newSel) then
    spSelectUnitArray(selUnits)
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
