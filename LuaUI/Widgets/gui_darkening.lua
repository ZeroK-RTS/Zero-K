-- $Id: gui_darkening.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Darkening",
    desc      = "Adds a new '/luaui darkening %float%' (and '/luaui inc_dark' & '/luaui dec_dark') command.",
    author    = "jK",
    date      = "Nov 22, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  };
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local mapChanged = false;
local darkeningMap;
local darkening = 0;

local LUA_BRIGHT_MAP_FILE = "LuaUI/Config/darkeningMap.lua";

local vsx, vsy;
function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX;
  vsy = viewSizeY;
end
widget:ViewResize(widgetHandler:GetViewSizes());

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdateCallins()
  if (darkening>0) then
    widgetHandler:UpdateCallIn('DrawWorldPreUnit');
  else
    widgetHandler:RemoveCallIn('DrawWorldPreUnit');
  end
end


function SetDarkening(_,_,words)
  mapChanged = true;
  darkening  = tonumber(words[1]);
  darkeningMap[Game.mapName] = darkening;
  UpdateCallins();
end

function IncDarkening()
  mapChanged = true;
  darkening  = darkening + 0.1;
  darkeningMap[Game.mapName] = darkening;
  UpdateCallins();
end

function DecDarkening()
  mapChanged = true;
  darkening  = darkening - 0.1;
  darkeningMap[Game.mapName] = darkening;
  UpdateCallins();
end


function fileexists( file )
    local f = io.open( file, "r" );
    if f then
        io.close( f );
        return true;
    else
        return false;
    end
end

function widget:Initialize()
  if fileexists(LUA_BRIGHT_MAP_FILE) then
    darkeningMap = include("Config/darkeningMap.lua");
  end
  if (brightnessMap) then
    darkening = darkeningMap[Game.mapName];
  else
    darkeningMap = {};
  end
  UpdateCallins();

  local help = " [0..1]:  sets map darkening";
  widgetHandler:AddAction("darkening", SetDarkening, nil, "t");
  widgetHandler:AddAction("inc_dark", IncDarkening, nil, "t");
  widgetHandler:AddAction("dec_dark", DecDarkening, nil, "t");
end


function widget:Shutdown()
  if mapChanged then
    include("savetable.lua");
    table.save(darkeningMap, LUA_BRIGHT_MAP_FILE);
  end

  widgetHandler:RemoveAction("darkening");
  widgetHandler:RemoveAction("inc_dark");
  widgetHandler:RemoveAction("dec_dark");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:DrawWorldPreUnit()
  local drawMode = Spring.GetMapDrawMode()
  if (drawMode=="height") or (drawMode=="path") then return end

  gl.MatrixMode(GL.PROJECTION); gl.PushMatrix(); gl.LoadIdentity()
  gl.MatrixMode(GL.MODELVIEW);  gl.PushMatrix(); gl.LoadIdentity()

  gl.Color(0,0,0,darkening);
  gl.Rect(-1,1,1,-1);

  gl.MatrixMode(GL.PROJECTION); gl.PopMatrix()
  gl.MatrixMode(GL.MODELVIEW);  gl.PopMatrix()
end
