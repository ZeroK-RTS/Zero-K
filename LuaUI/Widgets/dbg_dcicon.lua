-- $Id: dbg_dcicon.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "DCIcon",
    desc      = "Displays an icon, when the connection is broken/lags.",
    author    = "jK",
    date      = "Oct 02, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local dc_img   = LUAUI_DIRNAME .. "Images/connection_lost.png"
local dc_rec   = {0,0,64,64}
local dc_timer = 0 --in seconds

local iconSize = 64

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:ViewResize(vsx,vsy)
  dc_rec = {
    vsx - iconSize,
    vsy/2 - iconSize/2,
    vsx,
    vsy/2 + iconSize/2
  }
end

widget:ViewResize(widgetHandler:GetViewSizes())

function widget:GetConfigData()
  widgetHandler:RemoveCallIn("ViewResize")
  return dc_rec
end

function widget:SetConfigData(data)
  dc_rec = data
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Shutdown()
  gl.DeleteTexture(dc_img)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DrawIcon()
  gl.BeginEnd(GL.QUADS,function()
    gl.Color(1,1,1,0.95)
    gl.Vertex(dc_rec[1],dc_rec[4])
    gl.Color(1,0.8,0.8,0.95)
    gl.Vertex(dc_rec[3],dc_rec[4])
    gl.Color(0.95,0,0,0.95)
    gl.Vertex(dc_rec[3],dc_rec[2])
    gl.Color(0.95,0.3,0.3,0.95)
    gl.Vertex(dc_rec[1],dc_rec[2])
  end)
  gl.Color(0,0,0,1)
  gl.LineWidth(2)
  gl.BeginEnd(GL.LINE_LOOP,function()
    gl.Vertex(dc_rec[1],dc_rec[4])
    gl.Vertex(dc_rec[3],dc_rec[4])
    gl.Vertex(dc_rec[3],dc_rec[2])
    gl.Vertex(dc_rec[1],dc_rec[2])
  end)
  gl.Color(1,1,1,1)
  gl.LineWidth(1)
  gl.Texture(dc_img)
  gl.TexRect(dc_rec[1],dc_rec[2],dc_rec[3],dc_rec[4])
  gl.Texture(false)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Update(dt)
  if (dc_timer>0) then
    dc_timer = dc_timer - dt
  end
end


function widget:DrawScreen()
  if (Spring.GetHasLag())and(Spring.GetGameFrame()>1) then
    dc_timer = 5
  end
    
  if (dc_timer>0) then
    DrawIcon()
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetTooltip()
  return "You are disconnected from the host.\n"..
         "Check your connection!"
end

function widget:IsAbove(x,y)
  if (dc_timer>0) then
    return (x >= dc_rec[1]) and (x <= dc_rec[3])and
           (y >= dc_rec[2]) and (y <= dc_rec[4])
  end
end

function widget:MousePress(x, y, button)
  if (button~=1) then return false end

  if (self:IsAbove(x,y)) then
    return true
  end
  return false
end

function widget:MouseMove(x, y, dx, dy, button)
  if (button~=1) then return false end

  dc_rec = {
    x - iconSize/2,
    y - iconSize/2,
    x + iconSize/2,
    y + iconSize/2
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:TweakDrawScreen()
  DrawIcon()
end

widget.TweakIsAbove    = widget.IsAbove
widget.TweakMousePress = widget.MousePress
widget.TweakMouseMove  = widget.MouseMove

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
