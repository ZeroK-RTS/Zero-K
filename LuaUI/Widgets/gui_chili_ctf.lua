--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local version = "0.0.4" -- you may find changelog in capture_the_flag.lua gadget

function widget:GetInfo()
  return {
    name      = "Chili CTF GUI",
    desc      = "GUI for Capture The Flag game mode. Version: "..version,
    author    = "Tom Fyuri",
    date      = "Feb 2014",
    license   = "GPL v2 or later",
    layer     = 1, 
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- TODO Figure out everything i dont need here...
-- most of the code is simple copy paste from takeover widget

local Chili
local Button
local Label
local Window
local Panel
local StackPanel
local ScrollPanel
local TextBox
local Image
local Progressbar
local Control
local Font
local color2incolor
local incolor2color

local blue	= {0,0,1,1}
local green	= {0,1,0,1}
local red	= {1,0,0,1}
local orange 	= {1,0.4,0,1}
local yellow 	= {1,1,0,1}
local cyan 	= {0,1,1,1}
local white 	= {1,1,1,1}

local GL_LINE_STRIP         = GL.LINE_STRIP

local glVertex		= gl.Vertex
local glDepthTest	= gl.DepthTest
local glColor		= gl.Color
local glBeginEnd	= gl.BeginEnd
local glLineWidth	= gl.LineWidth
local glDrawFuncAtUnit  = gl.DrawFuncAtUnit
local glRotate		= gl.Rotate
local glTranslate	= gl.Translate
local glBillboard	= gl.Billboard
local glPopMatrix       = gl.PopMatrix
local glPushMatrix      = gl.PushMatrix
local glScale           = gl.Scale
local glText            = gl.Text
local glAlphaTest       = gl.AlphaTest
local glTexture         = gl.Texture
local glTexRect         = gl.TexRect
local GL_GREATER        = GL.GREATER
local glUnitMultMatrix  = gl.UnitMultMatrix
local glUnitPieceMultMatrix = gl.UnitPieceMultMatrix

local overheadFont	= "LuaUI/Fonts/FreeSansBold_16"
local hudfont = "LuaUI/Fonts/FreeSansBold_30"

local random	= math.random
local floor	= math.floor
local abs	= math.abs
local sqrt	= math.sqrt
local PI	= math.pi
local cos	= math.cos
local sin	= math.sin
local max	= math.max

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local myTeam --= Spring.GetMyTeamID()
local myAllyTeam --= Spring.GetMyAllyTeamID()
local myOldAllyTeam
local RedAllyTeam --= nil
local timer = 0
local UPDATE_FREQUENCY = 0.6	-- seconds
local CAP_RADIUS = 250

local respawn_button
local respawn_info
local respawn_timer
local blue_score
local red_score
local blue_income
local red_income
local blue_stolen
local red_stolen
local status_window
local stack_panel
local red_team
local blue_team
local extra_com
local mid_stack
local blue_defeat
local red_defeat
local contest_text
local contest_timer
-- FIXME defeat timer is slightly faster/slower compared to real time, will tweak in future (just like takeover timer)

local vsx, vsy = widgetHandler:GetViewSizes()
function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end
local spawn_mode = false
local spawn_text = "Press Left Mouse Button where you want (in LoS) your new commander to be spawned."
local spawn_text2 = "Press Right Mouse Button to exit spawn mode!"

local iconsize   = 40
local iconhsize  = iconsize * 0.5
local iconsize2   = 60
local iconhsize2  = iconsize2 * 0.5

local sfx_stolen = "sounds/ctf/stolen.wav"
local sfx_return = "sounds/ctf/return.wav"
local sfx_blue_score = "sounds/ctf/capture-blue.wav"
local sfx_red_score = "sounds/ctf/capture-red.wav"

local bs,rs
local memo_bs = -1
local memo_rs = -1 -- used in clever way to detect capture/stolen/return

local CommandCenters = {}
local Rotation = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function FigureOutRed(myAllyTeam)
  for _,allyTeam in ipairs(Spring.GetAllyTeamList()) do
    if (allyTeam ~= myAllyTeam) and (Spring.GetGameRulesParam("ctf_flags_team"..allyTeam) ~= nil) then
      return allyTeam
    end
  end
  return nil
end
function GetTimeFormatted(time)
  local delay_minutes = floor(time/60) -- TODO optimise this, this can be done lot better and faster
  local delay_seconds = time-delay_minutes*60
  local time_text = "DEFEAT"
  if (time > 0) then
    if (0 == delay_seconds) and (delay_minutes > 0) then
      time_text = delay_minutes.."m"
    elseif (delay_minutes == 0) then
      time_text = delay_seconds.."s"
    else
      time_text = delay_minutes.."m"..delay_seconds.."s"
    end -- should be possible to do this much faster
  end
  return time_text
end

function UpdateTeamData()
  myTeam = Spring.GetMyTeamID()
  myAllyTeam = Spring.GetMyAllyTeamID()
  if (myAllyTeam ~= myOldAllyTeam) then
    memo_bs = nil
    memo_rs = nil
    -- remove all status effects if there are any
    -- such roundabout way huh
    if (respawn_button) then
      mid_stack:RemoveChild(respawn_button)
      respawn_button = nil
    end
    if (red_stolen) then
      red_team:RemoveChild(red_stolen)
      red_stolen = nil
    end
    if (blue_stolen) then
      blue_team:RemoveChild(blue_stolen)
      blue_stolen = nil
    end
    if (contest_timer) then
      status_window:RemoveChild(contest_text)
      status_window:RemoveChild(contest_timer)
    end
    if (blue_defeat) then
      blue_team:RemoveChild(blue_defeat)
      blue_defeat = nil	
    end
    if (red_defeat) then
      red_team:RemoveChild(red_defeat)
      red_defeat = nil	
    end
    if (respawn_info) then
      mid_stack:RemoveChild(respawn_info)
      respawn_info = nil
    end
    if (respawn_timer) then
      mid_stack:RemoveChild(respawn_timer)
      respawn_timer = nil
    end
    myOldAllyTeam = myAllyTeam
  end
  if (Spring.GetGameRulesParam("ctf_flags_team"..myAllyTeam) == nil) then
    return false
  end
  -- FIXME hardcoded to 2 teams naturally TODO remake all widget to support more than 2 allyteams
  RedAllyTeam = FigureOutRed(myAllyTeam)
  if (RedAllyTeam == nil) then
    return false
  end
  return true
end

function widget:Update(s)
  Rotation=Rotation+1
  if (Rotation > 360) then
    Rotation = 0
  end
  timer = timer + s
  if timer > UPDATE_FREQUENCY then
    timer = 0
    UpdateTeamData()
    if (myTeam == nil) or (myAllyTeam == nil) or (RedAllyTeam == nil) then return end
    bs = Spring.GetGameRulesParam("ctf_flags_team"..myAllyTeam)
    rs = Spring.GetGameRulesParam("ctf_flags_team"..RedAllyTeam)
    -- update labels
    blue_score:SetCaption(bs)
    red_score:SetCaption(rs)
    -- income
    local bt_inc = Spring.GetGameRulesParam("ctf_income_team"..myAllyTeam)
    local rt_inc = Spring.GetGameRulesParam("ctf_income_team"..RedAllyTeam)
    if (bt_inc ~= nil) then
      bt_inc = bt_inc*0.01
      blue_income:SetCaption(string.format("+%.2f/s",bt_inc))
    end
    if (rt_inc ~= nil) then
      rt_inc = rt_inc*0.01
      red_income:SetCaption(string.format("+%.2f/s",rt_inc))
    end
    -- can i respawn?
    local spawn_tickets = Spring.GetGameRulesParam("ctf_orbit_tickets"..myTeam)
    if (spawn_tickets ~= nil) then
      if (spawn_tickets > 0) and (respawn_button == nil) then
	respawn_button = Button:New {
	  width = 50,
	  height = 50,
	  padding = {0, 0, 0, 0},
	  margin = {15, 0, 0, 0},
-- 	  backgroundColor = {1, 1, 1, 0.4},
	  caption = "";
	  tooltip = "Orbital drop! Press and select place where to respawn your commander!";
	  children = {
	    extra_com, 
	  },
	  OnMouseDown = {
	    function()
	      if (not Spring.GetSpectatingState()) then
		spawn_mode = not(spawn_mode)
	      end
	    end
	  }
	}
	mid_stack:AddChild(respawn_button)
      elseif (spawn_tickets == 0) and (respawn_button ~= nil) then
	mid_stack:RemoveChild(respawn_button)
	respawn_button = nil
      end
    end
    -- respawn timer update
    if (spawn_tickets ~= nil) then
      -- sup
      if (spawn_tickets == 0) and (respawn_info == nil) then
	respawn_info = Label:New {
	  autosize = false;
	  align = "center";
	  caption = "Extra com in:";
	  height = 20,
	  width = "100%";
	  fontsize = 11;
	}
	mid_stack:AddChild(respawn_info)
      elseif (respawn_info ~= nil) and (spawn_tickets > 0) then
	mid_stack:RemoveChild(respawn_info)
	respawn_info = nil
      end
    end
    local spawn_time = Spring.GetGameRulesParam("ctf_orbit_timer"..myTeam)
    local spawn_pool = Spring.GetGameRulesParam("ctf_orbit_pool"..myTeam)
    if (spawn_time ~= nil) then
      if (respawn_timer == nil) then--and (spawn_pool > spawn_tickets) then
	respawn_timer = Label:New {
	  autosize = false;
	  align = "center";
	  caption = GetTimeFormatted(spawn_time);
	  height = 10,
	  width = "100%";
	  fontsize = 10;
	  textColor = green;
	}
	mid_stack:AddChild(respawn_timer)
      end
      if (spawn_pool == spawn_tickets) then
	respawn_timer:SetCaption("Full ("..spawn_tickets.."/"..spawn_pool..")")
	respawn_timer.font:SetColor(white)
      else
	respawn_timer:SetCaption(GetTimeFormatted(spawn_time).." ("..spawn_tickets.."/"..spawn_pool..")")
	respawn_timer.font:SetColor(green)
      end
    end
    -- stolen?
    local bf_stolen = Spring.GetGameRulesParam("ctf_unit_stole_team"..myAllyTeam)
    local rf_stolen = Spring.GetGameRulesParam("ctf_unit_stole_team"..RedAllyTeam)
    if (bf_stolen ~= nil) then
      if (bf_stolen > 0) and (blue_stolen == nil) then
	blue_stolen = Label:New {
	  autosize = false;
	  align = "center";
	  caption = "STOLEN";
	  height = 10,
	  width = "100%";
	  fontsize = 13;
	  textColor = red;
	}
	blue_team:AddChild(blue_stolen)
	if (memo_bs ~= nil) and (bs < memo_bs) then
	  Spring.PlaySoundFile(sfx_stolen)
	end
      elseif (bf_stolen == 0) and (blue_stolen ~= nil) then
	if (memo_bs ~= nil) and (bs == (memo_bs+1)) then
	  Spring.PlaySoundFile(sfx_return)
	elseif (memo_rs ~= nil) and (rs == (memo_rs+1)) then
	  Spring.PlaySoundFile(sfx_red_score)
	end
	blue_team:RemoveChild(blue_stolen)
	blue_stolen = nil
      end
    end
    if (rf_stolen ~= nil) then
      if (rf_stolen > 0) and (red_stolen == nil) then
	red_stolen = Label:New {
	  autosize = false;
	  align = "center";
	  caption = "TAKEN";
	  height = 10,
	  width = "100%";
	  fontsize = 13;
	  textColor = green;
	}
	if (memo_rs ~= nil) and (rs < memo_rs) then
	  Spring.PlaySoundFile(sfx_stolen)
	end
	red_team:AddChild(red_stolen)
      elseif (rf_stolen == 0) and (red_stolen ~= nil) then
	if (memo_rs ~= nil) and (rs == (memo_rs+1)) then
	  Spring.PlaySoundFile(sfx_return)
	elseif (memo_bs ~= nil) and (bs == (memo_bs+1)) then
	  Spring.PlaySoundFile(sfx_blue_score)
	end
	red_team:RemoveChild(red_stolen)
	red_stolen = nil
      end
    end
    -- maybe it's contest instead...? uhuh
    local ct = Spring.GetGameRulesParam("ctf_contest_time_team"..myAllyTeam)
    if (blue_stolen) and (red_stolen) and (ct ~= nil) then
      if (contest_timer == nil) then
	contest_timer = Label:New {
	  autosize = false;
	  y = 65;
	  align = "center";
	  caption = GetTimeFormatted(ct);
	  height = 20,
	  width = "100%";
	  fontsize = 13;
	  textColor = green;
	}
	status_window:AddChild(contest_text)
	status_window:AddChild(contest_timer)
      else
	contest_timer:SetCaption(GetTimeFormatted(ct))
      end
    elseif (contest_timer ~= nil) then
      status_window:RemoveChild(contest_text)
      status_window:RemoveChild(contest_timer)
      contest_timer = nil
    end
    -- is it time to die?
    local blue_sd = Spring.GetGameRulesParam("ctf_defeat_time_team"..myAllyTeam)
    local red_sd = Spring.GetGameRulesParam("ctf_defeat_time_team"..RedAllyTeam)
    if (blue_sd ~= nil) and (bf_stolen == 0) then
      if (blue_defeat == nil) and (bs == 0) then
	local color = white
	if (blue_sd <= 30) then color = red end
	blue_defeat = Label:New {
	  autosize = false;
	  align = "center";
	  caption = GetTimeFormatted(blue_sd);
	  height = 10,
	  width = "100%";
	  fontsize = 13;
	  textColor = color;
	}
	blue_team:AddChild(blue_defeat)
      elseif (bs > 0) then
	blue_team:RemoveChild(blue_defeat)
	blue_defeat = nil	
      else -- bs == 0 and blue_defeat ~= nil
	local color = white
	if (blue_sd <= 30) then color = red end
	blue_defeat:SetCaption(GetTimeFormatted(blue_sd))
	blue_defeat.font:SetColor(color)
      end
    end
    if (red_sd ~= nil) and (rf_stolen == 0)then
      if (red_defeat == nil) and (rs == 0) then
	local color = white
	if (red_sd <= 30) then color = red end
	red_defeat = Label:New {
	  autosize = false;
	  align = "center";
	  caption = GetTimeFormatted(red_sd);
	  height = 10,
	  width = "100%";
	  fontsize = 13;
	  textColor = color;
	}
	red_team:AddChild(red_defeat)
      elseif (rs > 0) then
	red_team:RemoveChild(red_defeat)
	red_defeat = nil	
      else
	local color = white
	if (red_sd <= 30) then color = red end
	red_defeat:SetCaption(GetTimeFormatted(red_sd))
	red_defeat.font:SetColor(color)
      end
    end
    memo_bs = bs
    memo_rs = rs
  end
end

function widget:UnitFinished(unitID, unitDefID)
  SpotCC(unitID, unitDefID)
end

function widget:UnitFinished(unitID, unitDefID)--, team)
  SpotCC(unitID, unitDefID)
end

function widget:UnitEnteredLos(unitID)
  SpotCC(unitID, Spring.GetUnitDefID(unitID))
end

function SpotCC(unitID, unitDefID)
  if Spring.ValidUnitID(unitID) and unitDefID and (UnitDefs[unitDefID].name == "ctf_center") then
    CommandCenters[unitID] = Spring.GetUnitAllyTeam(unitID)
  end  
end

function ReInit()
  for _, unitID in ipairs(Spring.GetAllUnits()) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    SpotCC(unitID, unitDefID)
  end
end

function spGetUnitPieceMap(unitID,piecename)
  local pieceMap = {}
  for piecenum,piecename in pairs(Spring.GetUnitPieceList(unitID)) do
    pieceMap[piecename] = piecenum
  end
  return pieceMap
end

local function PillarVertsBlue(x, y, z)
  glColor(0, 1, 0.5, 1)
  glVertex(x, y, z)
  glColor(0, 1, 0.5, 0)
  glVertex(x, y + 500, z)
end

local function PillarVertsRed(x, y, z)
  glColor(1, 0, 0, 1)
  glVertex(x, y, z)
  glColor(1, 0, 0, 0)
  glVertex(x, y + 500, z)
end

local function BuildVertexList(verts) -- this code was stolen from defence range widget
  local count =  #verts
  for i = 1, count do
    glVertex(verts[i])
  end
  if count > 0 then
    glVertex(verts[1])
  end
end

local function GetRange2D(range, yDiff) -- this code was stolen from defence range widget
  local root1 = range * range - yDiff * yDiff
  if ( root1 < 0 ) then
    return 0
  else
    return sqrt( root1 )
  end
end

function DrawCircle(x, y, z, range) -- thanks defence range widget
  local rangeLineStrip = {}
  local yGround = Spring.GetGroundHeight(x,z)
  for i = 1,40 do
    local radians = 2.0 * PI * i / 40
    local rad = range

    local sinR = sin( radians )
    local cosR = cos( radians )

    local posx = x + sinR * rad
    local posz = z + cosR * rad
    local posy = Spring.GetGroundHeight( posx, posz )

    local heightDiff = ( posy - yGround) / 2.0	-- maybe y has to be getGroundHeight(x,z) cause y is unit center and not aligned to ground

--     rad = rad - heightDiff * slope
    local adjRadius = GetRange2D( range, 0) --heightDiff * 0.0)
    local adjustment = rad / 2.0
    local yDiff = 0.0

    for j = 0, 49 do
      if ( abs( adjRadius - rad ) + yDiff <= 0.01 * rad ) then
	break
      end

      if ( adjRadius > rad ) then
	rad = rad + adjustment
      else
	rad = rad - adjustment
	adjustment = adjustment / 2.0
      end
      posx = x + ( sinR * rad )
      posz = z + ( cosR * rad )
      local newY = Spring.GetGroundHeight( posx, posz )
      yDiff = abs( posy - newY )
      posy = newY
      posy = max( posy, 0.0 )  --hack
      heightDiff = ( posy - yGround )	--maybe y has to be Ground(x,z)
      adjRadius = GetRange2D( range, heightDiff * 0.0)
    end

    posx = x + ( sinR * adjRadius )
    posz = z + ( cosR * adjRadius )
    posy = Spring.GetGroundHeight( posx, posz ) + 5.0
    posy = max( posy, 0.0 )   --hack
    
    table.insert( rangeLineStrip, { posx, posy, posz } )
  end
  return rangeLineStrip
end

function widget:DrawWorld()
  if not Spring.IsGUIHidden() then
    local redHolder, blueHolder
    local fx,fy,fz
    glDepthTest(true)
    glAlphaTest(GL_GREATER, 0)
    -- blue flag stolen by
    if (myAllyTeam ~= nil) then
      blueHolder = Spring.GetGameRulesParam("ctf_unit_stole_team"..myAllyTeam)
      if (blueHolder ~= nil) and (blueHolder > 0) and (Spring.ValidUnitID(blueHolder)) then
	local unitID = blueHolder
	fx,fy,fz = Spring.GetUnitPosition(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	glPushMatrix()
	glLineWidth(20)
	glColor(1,1,1,1)
	glBeginEnd(GL_LINE_STRIP, PillarVertsBlue, fx, fy, fz)
	glLineWidth(1)
	glPopMatrix()
	if (UnitDefs[unitDefID].name ~= "ctf_flag") then
	  glTexture('LuaUI/Images/ctf_blue_flag.png')
	  glPushMatrix()
	  glUnitMultMatrix(unitID)
	  glTranslate(0, UnitDefs[unitDefID].height + 10, 0)
	  glRotate(Rotation,0,1,0)
	  glColor(1,1,1,1)
	  glTexRect(-iconhsize, 0, iconhsize, iconsize)
	  glPopMatrix()
	end
      end
    end
    -- red flag stolen by
    if (RedAllyTeam ~= nil) then
      redHolder = Spring.GetGameRulesParam("ctf_unit_stole_team"..RedAllyTeam)
      if (redHolder ~= nil) and (redHolder > 0) and (Spring.ValidUnitID(redHolder)) then
	local unitID = redHolder
	fx,fy,fz = Spring.GetUnitPosition(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	glPushMatrix()
	glLineWidth(20)
	glColor(1,1,1,1)
	glBeginEnd(GL_LINE_STRIP, PillarVertsRed, fx, fy, fz)
	glLineWidth(1)
	glPopMatrix()
	if (UnitDefs[unitDefID].name ~= "ctf_flag") then
	  glTexture('LuaUI/Images/ctf_red_flag.png')
	  glPushMatrix()
	  glUnitMultMatrix(unitID)
	  glTranslate(0, UnitDefs[unitDefID].height + 10, 0)
	  glRotate(Rotation,0,1,0)
	  glColor(1,1,1,1)
	  glTexRect(-iconhsize, 0, iconhsize, iconsize)
	  glPopMatrix()
	end
      end
    end
    for unitID,allyTeam in pairs(CommandCenters) do
      fx,fy,fz = Spring.GetUnitPosition(unitID)
      if (allyTeam == myAllyTeam) then
	local unitDefID = Spring.GetUnitDefID(unitID)
	if (blue_stolen == nil) then
	  glPushMatrix()
	  glTexture(false)
	  glLineWidth(20)
	  glColor(1,1,1,1)
	  glBeginEnd(GL_LINE_STRIP, PillarVertsBlue, fx, fy, fz)
	  glLineWidth(2.5)
	  glColor(0, 1, 0.5, 0.3)
	  glBeginEnd(GL_LINE_STRIP, BuildVertexList, DrawCircle(fx, fy, fz, CAP_RADIUS))
	  glLineWidth(1)
	  glPopMatrix()
	end
	if (bs ~= nil) and (bs > 0) then
	  glPushMatrix()
	  glTexture('LuaUI/Images/ctf_blue_flag.png')
	  glUnitMultMatrix(unitID)
	  glTranslate(0, UnitDefs[unitDefID].height + 20, 0)
	  glRotate(Rotation,0,1,0)
	  glColor(1,1,1,1)
	  glTexRect(-iconhsize2, 0, iconhsize2, iconsize2)
	  glPopMatrix()
	end
      elseif (allyTeam == RedAllyTeam) then
	local unitDefID = Spring.GetUnitDefID(unitID)
	if (red_stolen == nil) then
	  glPushMatrix()
	  glTexture(false)
	  glLineWidth(20)
	  glColor(1,1,1,1)
	  glBeginEnd(GL_LINE_STRIP, PillarVertsRed, fx, fy, fz)
	  glLineWidth(2.5)
	  glColor(1, 0, 0, 0.3)
	  glBeginEnd(GL_LINE_STRIP, BuildVertexList, DrawCircle(fx, fy, fz, CAP_RADIUS))
	  glLineWidth(1)
	  glPopMatrix()
	end
	if (rs ~= nil) and (rs > 0) then
	  glPushMatrix()
	  glTexture('LuaUI/Images/ctf_red_flag.png')
	  glUnitMultMatrix(unitID)
	  glTranslate(0, UnitDefs[unitDefID].height + 20, 0)
	  glRotate(Rotation,0,1,0)
	  glColor(1,1,1,1)
	  glTexRect(-iconhsize2, 0, iconhsize2, iconsize2)
	  glPopMatrix()
	end
      end
    end
    -- done
    glAlphaTest(false)
    glColor(1,1,1,1)
    glTexture(false)
    glDepthTest(false)
  end
end

function widget:DrawScreen()
  if (spawn_mode) then
    local msg = spawn_text
    glPushMatrix()
    glTranslate((vsx * 0.5), (vsy * 0.5) + 50, 0)
    glScale(1.5, 1.5, 1)
    -- glRotate(5 * math.sin(math.pi * 0.5 * timer), 0, 0, 1)
    if (fh) then
      fh = fontHandler.UseFont(hudfont)
      fontHandler.DrawCentered(msg)
    else
      glText(msg, 0, 0, 20, "oc")
    end

    --if endmode then
    msg = spawn_text2,
    glTranslate(0, -50, 0)
    glText(msg, 0, 0, 14, "oc")
    --end
    glPopMatrix()
  end
end

function widget:MousePress(mx, my, mb)
  if (spawn_mode) then
    if (mb == 3) then
      spawn_mode = false
    elseif (mb == 1) then
      _, cursorWorldCoors = Spring.TraceScreenRay(mx, my, true)
      local x, y, z = cursorWorldCoors[1], cursorWorldCoors[2], cursorWorldCoors[3]
      Spring.SendLuaRulesMsg("ctf_respawn "..x.." "..y.." "..z)
      spawn_mode = false
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  local ctf = (Spring.GetModOptions().zkmode) == "ctf"
  
  if (ctf == false) then
    widgetHandler:RemoveWidget()
    return
  end
  
  -- setup Chili
  Chili = WG.Chili
  Button = Chili.Button
  Label = Chili.Label
  TextBox = Chili.TextBox
  Colorbars = Chili.Colorbars
  Window = Chili.Window
  Panel = Chili.Panel
  StackPanel = Chili.StackPanel
  ScrollPanel = Chili.ScrollPanel
  Image = Chili.Image
  Progressbar = Chili.Progressbar
  Control = Chili.Control
  screen0 = Chili.Screen0
  color2incolor = Chili.color2incolor
  incolor2color = Chili.incolor2color
	
  local screenWidth,screenHeight = Spring.GetWindowGeometry()
  local minWidth = 260;
  local minHeight = 90;
  
  extra_com = Image:New {
    file = "LuaUI/Images/startup_info_selector/selecticon.png";
    height = 50;
    width = 50;
  }
  mid_stack = StackPanel:New {
    width = 80;
    height = "100%";
    centerItems = false,
    resizeItems = false;
    orientation = "vertical";
    padding = {0, 2, 0, 0},
    itemMargin  = {0, 0, 0, 0},
    children = {
      Label:New {
	autosize = false;
	align = "center";
	caption = "CTF stats";
	height = 20,
	width = "100%";
	fontsize = 11;
      },
    },
  }
  red_score = Label:New {
    autosize = false;
    align = "center";
    caption = "?";
    height = 25,
    width = "100%";
    fontsize = 16;
    textColor = red;
  }
  red_income = Label:New {
    autosize = false;
    align = "center";
    caption = "+0/s";
    height = 10,
    width = "100%";
    fontsize = 11;
    textColor = red;
  }
  red_team = StackPanel:New {
    width = 70;
    height = "100%";
    centerItems = false,
    resizeItems = false;
    orientation = "vertical";
    padding = {0, 5, 0, 0},
    itemMargin  = {0, 0, 0, 2},
    children = {
      Label:New {
	y = 10;
	autosize = false;
	width = "100%";
	align = "center";
	valign = "center";
	height = 20;
	textColor = red;
	fontsize=13;
	caption = "Red Team";
      },
      red_income,
      red_score,
    },
  }
  blue_score = Label:New {
    autosize = false;
    align = "center";
    caption = "?";
    height = 25,
    width = "100%";
    fontsize = 16;
    textColor = cyan;
  }
  blue_income = Label:New {
    autosize = false;
    align = "center";
    caption = "+0/s";
    height = 10,
    width = "100%";
    fontsize = 11;
    textColor = cyan;
  }
  blue_team = StackPanel:New {
    width = 70;
    height = "100%";
    centerItems = false,
    resizeItems = false;
    orientation = "vertical";
    padding = {0, 5, 0, 0},
    itemMargin  = {0, 0, 0, 2},
    children = {
      Label:New {
	y = 10;
	autosize = false;
	width = "100%";
	align = "center";
	valign = "center";
	height = 20;
	textColor = cyan; -- wow such lies
	fontsize=13;
	caption = "Blue Team"; -- you are always team blue
      },
      blue_income,
      blue_score,
    },
  }
  contest_text = Label:New {
    y = 55;
    autosize = false;
    align = "center";
    caption = "Flags returning in...";
    height = 20,
    width = "100%";
    fontsize = 11;
    textColor = white;
  }
  stack_panel = StackPanel:New {
    centerItems = true,
    resizeItems = false;
    orientation = "horizontal";
    width = "100%";
    height = 90;
    padding = {0, 0, 0, 0},
    itemMargin  = {5, 0, 0, 0},
    children = {
      blue_team,
      mid_stack,
      red_team,
    },
  }
  status_window = Window:New {
    name = 'ctf_status_window';
    color = {nil, nil, nil, 0.5},
    width = minWidth;
    height = minHeight;
    x = screenWidth/2-minWidth/2;
    y = screenHeight/5-minHeight/2;
    dockable = true;
    minimizable = true,
    draggable = true,
    resizable = false,
    tweakDraggable = true,
    tweakResizable = true,
    padding = {0, 0, 0, 0},
    minWidth = minWidth, 
    minHeight = minHeight,
    children = {
      stack_panel,
--       extra_com,
    },
  }
  screen0:AddChild(status_window)
  ReInit()
end

function widget:Shutdown()
  if (status_window) then
    status_window:Dispose()
  end
  if (vote_window) then
    vote_window:Dispose()
  end
  if (nominate_window) then
    nominate_window:Dispose()
  end
  if (help_window) then
    help_window:Dispose()
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------