-- $Id: gui_lups_stats.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  orig-file:    gui_clock.lua
--  orig-file:    gui_lups_stats.lua
--  brief:   displays the current game time
--  author:  jK (on code by trepan)
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "LupsStats",
    desc      = "",
    author    = "jK",
    date      = "Dec, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.h.lua")

local floor = math.floor

local vsx, vsy = widgetHandler:GetViewSizes()

-- the 'f' suffixes are fractions  (and can be nil)
local color  = { 1.0, 1.0, 1.0 }
local xposf  = 0.99
local xpos   = xposf * vsx
local yposf  = 0.010
local ypos   = yposf * vsy + 40
local sizef  = 0.015
local size   = sizef * vsy
local font   = "LuaUI/Fonts/FreeSansBold_14"
local format = "orn"

local fh = (font ~= nil)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Rendering
--

function widget:DrawScreen()
  gl.Color(color)
    local fxcount, fxlayers, fx = WG['Lups'].GetStats()

    local totalParticles = (((fx['SimpleParticles'] or {})[2])or 0) + (((fx['NanoParticles'] or {})[2])or 0) + (((fx['StaticParticles'] or {})[2])or 0)

    gl.Text("-LUPS Stats-", xpos, ypos+112, size, format)
    gl.Text("particles: " .. totalParticles, xpos, ypos+90, size, format)
    gl.Text("layers: " .. fxlayers, xpos, ypos+70, size, format)
    gl.Text("effects: " .. fxcount, xpos, ypos+50, size, format)
  gl.Color(1,1,1,1)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Geometry Management
--

local function UpdateGeometry()
  -- use the fractions if available
  xpos = (xposf and (xposf * vsx)) or xpos
  ypos = (yposf and (yposf * vsy)) or ypos
  size = (sizef and (sizef * vsy)) or size
  -- negative values reference the right/top edges
  xpos = (xpos < 0) and (vsx + xpos) or xpos
  ypos = (ypos < 0) and (vsy + ypos) or ypos
end
UpdateGeometry()


function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
  UpdateGeometry()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Configuration routines
--

local function StoreGeoPair(tbl, fName, fValue, pName, pValue)
  if (fValue) then
    tbl[pName] = nil
    tbl[fName] = fValue
  else
    tbl[pName] = pValue
    tbl[fName] = nil
  end
  return
end


function widget:GetConfigData()
  local tbl = {
    color  = color,
    format = format,
    font   = font
  }
  StoreGeoPair(tbl, 'xposf', xposf, 'xpos', xpos)
  StoreGeoPair(tbl, 'yposf', yposf, 'ypos', ypos)
  StoreGeoPair(tbl, 'sizef', sizef, 'size', size)
  return tbl
end


--------------------------------------------------------------------------------

-- returns a fraction,pixel pair
local function LoadGeoPair(tbl, fName, pName, oldPixelValue)
  if     (tbl[fName]) then return tbl[fName],      1
  elseif (tbl[pName]) then return nil,    tbl[pName]
  else                     return nil, oldPixelValue
  end
end


function widget:SetConfigData(data)
  color  = data.color  or color
  format = data.format or format
  font   = data.font   or font
  if (font) then
    fh = fontHandler.UseFont(font)
  end
  xposf, xpos = LoadGeoPair(data, 'xposf', 'xpos', xpos)
  yposf, ypos = LoadGeoPair(data, 'yposf', 'ypos', ypos)
  sizef, size = LoadGeoPair(data, 'sizef', 'size', size)
  UpdateGeometry()
  return
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
