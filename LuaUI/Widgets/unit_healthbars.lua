-- $Id: unit_healthbars.lua 4481 2009-04-25 18:38:05Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  author:  jK
--
--  Copyright (C) 2007,2008,2009.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "HealthBars",
    desc      = "Gives various informations about units in form of bars.",
    author    = "jK",
    date      = "2009",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local barHeight = 3
local barWidth  = 14  --// (barWidth)x2 total width!!!
local barAlpha  = 0.9

local featureBarHeight = 3
local featureBarWidth  = 10
local featureBarAlpha  = 0.6

local drawBarTitles = true
local drawBarPercentages = true 
local titlesAlpha   = 0.3*barAlpha

local drawFullHealthBars = false

local drawFeatureHealth  = false
local featureTitlesAlpha = featureBarAlpha * titlesAlpha/barAlpha
local featureHpThreshold = 0.85

local infoDistance = 700000

local minReloadTime = 4 --// in seconds

local drawStunnedOverlay = true
local drawUnitsOnFire    = Spring.GetGameRulesParam("unitsOnFire")
local drawJumpJet        = Spring.GetGameRulesParam("jumpJets")

--// this table is used to shows the hp of perimeter defence, and filter it for default wreckages
local walls = {dragonsteeth=true,dragonsteeth_core=true,fortification=true,fortification_core=true,spike=true,floatingteeth=true,floatingteeth_core=true,spike=true}

local stockpileH = 24
local stockpileW = 12

local captureReloadTime = 240

--------------------------------------------------------------------------------
-- OPTIONS
--------------------------------------------------------------------------------
local function OptionsChanged() 
	drawFeatureHealth = options.drawFeatureHealth.value
	drawBarPercentages = options.drawBarPercentages.value
end 

options_path = 'Settings/View/Healthbars'
options_order = { 'showhealthbars', 'drawFeatureHealth', 'drawBarPercentages'}
options = {
	
	showhealthbars = {
		name = 'Show Healthbars',
		type = 'bool',
		value = true,
		--OnChange = function() Spring.SendCommands{'showhealthbars'} end,
	},
	drawFeatureHealth = {
		name = 'Draw health of features (corpses)',
		type = 'bool',
		value = false,
		desc = 'Shows healthbars on corpses',
		OnChange = OptionsChanged,
	},
	
	drawBarPercentages = {
		name = 'Draw percentages',
		type = 'bool',
		value = true,
		desc = 'Shows percentages next to bars',
		OnChange = OptionsChanged,
	},
	
	

}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function lowerkeys(t)
  local tn = {}
  for i,v in pairs(t) do
    local typ = type(i)
    if type(v)=="table" then
      v = lowerkeys(v)
    end
    if typ=="string" then
      tn[i:lower()] = v
    else
      tn[i] = v
    end
  end
  return tn
end

local paralyzeOnMaxHealth = ((lowerkeys(VFS.Include"gamedata/modrules.lua") or {}).paralyze or {}).paralyzeonmaxhealth

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// colors
local bkBottom   = { 0.40,0.40,0.40,barAlpha }
local bkTop      = { 0.10,0.10,0.10,barAlpha }
local hpcolormap = { {0.8, 0.0, 0.0, barAlpha},  {0.8, 0.6, 0.0, barAlpha}, {0.0,0.70,0.0,barAlpha} }
local bfcolormap = {}

local fbkBottom   = { 0.40,0.40,0.40,featureBarAlpha }
local fbkTop      = { 0.06,0.06,0.06,featureBarAlpha }
local fhpcolormap = { {0.8, 0.0, 0.0, featureBarAlpha},  {0.8, 0.6, 0.0, featureBarAlpha}, {0.0,0.70,0.0,featureBarAlpha} }

local barColors = {
  emp     = { 0.50,0.50,1.00,barAlpha },
  emp_p   = { 0.40,0.40,0.80,barAlpha },
  emp_b   = { 0.60,0.60,0.90,barAlpha },
  capture = { 1.00,0.50,0.00,barAlpha },
  build   = { 0.75,0.75,0.75,barAlpha },
  stock   = { 0.50,0.50,0.50,barAlpha },
  reload  = { 0.00,0.60,0.60,barAlpha },
  jump    = { 0.00,0.60,0.60,barAlpha },
  sheath  = { 0.00,0.20,1.00,barAlpha },
  fuel    = { 0.70,0.30,0.00,barAlpha },
  slow    = { 0.50,0.10,0.70,barAlpha },
  goo     = { 0.50,0.50,0.50,barAlpha },
  shield  = { 0.20,0.60,0.60,barAlpha },

  resurrect = { 1.00,0.50,0.00,featureBarAlpha },
  reclaim   = { 0.75,0.75,0.75,featureBarAlpha },
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local blink = false;
local gameFrame = 0;

local empDecline = 32/30/40;

local cx, cy, cz = 0,0,0;  --// camera pos

local paraUnits   = {};
local onFireUnits = {};
local UnitMorphs  = {};

local barShader;
local barDList;
local barFeatureDList;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// speedup (there are a lot more localizations, but they are in limited scope cos we are running out of upvalues)
local glColor         = gl.Color
local glMyText        = gl.FogCoord
local floor           = math.floor

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

do
  local deactivated = false
  function showhealthbars(cmd, line, words)
    if ((words[1])and(words[1]~="0"))or(deactivated) then
      widgetHandler:UpdateCallIn('DrawWorld')
      deactivated = false
    else
      widgetHandler:RemoveCallIn('DrawWorld')
      deactivated = true
    end
  end
  options.showhealthbars.OnChange = function(self) showhealthbars(_,_,{self.value and '1' or '0'}) end
end --//end do

function widget:Initialize()

  --// catch f9
  Spring.SendCommands({"showhealthbars 0"})
  Spring.SendCommands({"showrezbars 0"})
  widgetHandler:AddAction("showhealthbars", showhealthbars)
  Spring.SendCommands({"unbind f9 showhealthbars"})
  Spring.SendCommands({"bind f9 luaui showhealthbars"})

  --// find real primary weapon and its reloadtime
  for _,ud in pairs(UnitDefs) do
    ud.reloadTime    = 0;
    ud.primaryWeapon = 0;
    ud.shieldPower   = 0;

    for i=1,ud.weapons.n do
      local WeaponDefID = ud.weapons[i].weaponDef;
      local WeaponDef   = WeaponDefs[ WeaponDefID ];
      if (WeaponDef.reload>ud.reloadTime) then
        ud.reloadTime    = WeaponDef.reload;
        ud.primaryWeapon = i;
      end
    end
    local shieldDefID = ud.shieldWeaponDef
    ud.shieldPower = ((shieldDefID)and(WeaponDefs[shieldDefID].shieldPower))or(-1)
  end

  --// link morph callins
  widgetHandler:RegisterGlobal('MorphUpdate', MorphUpdate)
  widgetHandler:RegisterGlobal('MorphFinished', MorphFinished)
  widgetHandler:RegisterGlobal('MorphStart', MorphStart)
  widgetHandler:RegisterGlobal('MorphStop', MorphStop)

  --// deactivate cheesy progress text
  widgetHandler:RegisterGlobal('MorphDrawProgress', function() return true end)

  --// wow, using a buffered list can give 1-2 frames in extreme(!) situations :p
  for hp=0,100 do
    bfcolormap[hp] = {GetColor(hpcolormap,hp*0.01)}
  end

  --// create bar shader
  if (gl.CreateShader) then
    barShader = gl.CreateShader({
      vertex = [[
        #define barColor gl_MultiTexCoord1
        #define progress gl_MultiTexCoord2.x
        #define offset   gl_MultiTexCoord2.y

        void main()
        {
           // switch between font rendering and bar rendering
           if (gl_FogCoord>0.5f) {
             gl_TexCoord[0]= gl_TextureMatrix[0]*gl_MultiTexCoord0;
             gl_FrontColor = gl_Color;
             gl_Position   = ftransform();
             return;
           }

           if (gl_Vertex.w>0) {
             gl_FrontColor = gl_Color;
             if (gl_Vertex.z>0.0) {
               gl_Vertex.x -= (1.0-progress)*gl_Vertex.z;
               gl_Vertex.z  = 0.0;
             }
           }else{
             if (gl_Vertex.y>0.0) {
               gl_FrontColor = vec4(barColor.rgb*1.5,barColor.a);
             }else{
               gl_FrontColor = barColor;
             }
             if (gl_Vertex.z>1.0) {
               gl_Vertex.x += progress*gl_Vertex.z;
               gl_Vertex.z  = 0.0;
             }
             gl_Vertex.w  = 1.0;
           }

           gl_Vertex.y += offset;
           gl_Position  = gl_ModelViewProjectionMatrix*gl_Vertex;
         }
      ]],
    });

    if (barShader) then
      barDList = gl.CreateList(function()
        gl.BeginEnd(GL.QUADS,function()
          gl.Vertex(-barWidth,0,        0,0);
          gl.Vertex(-barWidth,0,        barWidth*2,0);
          gl.Vertex(-barWidth,barHeight,barWidth*2,0);
          gl.Vertex(-barWidth,barHeight,0,0);

          gl.Color(bkBottom);
          gl.Vertex(barWidth,0,        0,         1);
          gl.Vertex(barWidth,0,        barWidth*2,1);
          gl.Color(bkTop);
          gl.Vertex(barWidth,barHeight,barWidth*2,1);
          gl.Vertex(barWidth,barHeight,0,         1);
        end)
      end)

      barFeatureDList = gl.CreateList(function()
        gl.BeginEnd(GL.QUADS,function()
          gl.Vertex(-featureBarWidth,0,               0,0);
          gl.Vertex(-featureBarWidth,0,               featureBarWidth*2,0);
          gl.Vertex(-featureBarWidth,featureBarHeight,featureBarWidth*2,0);
          gl.Vertex(-featureBarWidth,featureBarHeight,0,0);

          gl.Color(fbkBottom);
          gl.Vertex(featureBarWidth,0,               0,         1);
          gl.Vertex(featureBarWidth,0,               featureBarWidth*2,1);
          gl.Color(fbkTop);
          gl.Vertex(featureBarWidth,featureBarHeight,featureBarWidth*2,1);
          gl.Vertex(featureBarWidth,featureBarHeight,0,         1);
        end)
      end)
    end
  end

end

function widget:Shutdown()
  --// catch f9
  widgetHandler:RemoveAction("showhealthbars", showhealthbars)
  Spring.SendCommands({"unbind f9 luaui"})
  Spring.SendCommands({"bind f9 showhealthbars"})
  Spring.SendCommands({"showhealthbars 1"})
  Spring.SendCommands({"showrezbars 1"})

  widgetHandler:DeregisterGlobal('MorphUpdate', MorphUpdate)
  widgetHandler:DeregisterGlobal('MorphFinished', MorphFinished)
  widgetHandler:DeregisterGlobal('MorphStart', MorphStart)
  widgetHandler:DeregisterGlobal('MorphStop', MorphStop)

  widgetHandler:DeregisterGlobal('MorphDrawProgress')

  if (barShader) then
    gl.DeleteShader(barShader)
  end
  if (barDList) then
    gl.DeleteList(barDList)
    gl.DeleteList(barFeatureDList)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function GetColor(colormap,slider)
  local coln = #colormap
  if (slider>=1) then
    local col = colormap[coln]
    return col[1],col[2],col[3],col[4]
  end
  if (slider<0) then slider=0 elseif(slider>1) then slider=1 end
  local posn  = 1+(coln-1) * slider
  local iposn = floor(posn)
  local aa    = posn - iposn
  local ia    = 1-aa

  local col1,col2 = colormap[iposn],colormap[iposn+1]

  return col1[1]*ia + col2[1]*aa, col1[2]*ia + col2[2]*aa,
         col1[3]*ia + col2[3]*aa, col1[4]*ia + col2[4]*aa
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DrawUnitBar
local DrawFeatureBar
local DrawStockpile

do
  --//speedup
  local GL_QUADS        = GL.QUADS
  local glVertex        = gl.Vertex
  local glBeginEnd      = gl.BeginEnd
  local glMultiTexCoord = gl.MultiTexCoord
  local glTexRect       = gl.TexRect
  local glTexture       = gl.Texture
  local glCallList      = gl.CallList
  local glText          = gl.Text

  local function DrawGradient(left,top,right,bottom,topclr,bottomclr)
    glColor(bottomclr)
    glVertex(left,bottom)
    glVertex(right,bottom)
    glColor(topclr)
    glVertex(right,top)
    glVertex(left,top)
  end

  local brightClr = {}
  function DrawUnitBar(offsetY,percent,color)
    if (barShader) then
      glMultiTexCoord(1,color)
      glMultiTexCoord(2,percent,offsetY)
      glCallList(barDList)
      return;
    end

    brightClr[1] = color[1]*1.5; brightClr[2] = color[2]*1.5; brightClr[3] = color[3]*1.5; brightClr[4] = color[4]
    local progress_pos= -barWidth+barWidth*2*percent-1
    local bar_Height  = barHeight+offsetY
    if percent<1 then glBeginEnd(GL_QUADS,DrawGradient,progress_pos, bar_Height, barWidth, offsetY, bkTop,bkBottom) end
    glBeginEnd(GL_QUADS,DrawGradient,-barWidth, bar_Height, progress_pos, offsetY,brightClr,color)
  end

  function DrawFeatureBar(offsetY,percent,color)
    if (barShader) then
      glMultiTexCoord(1,color)
      glMultiTexCoord(2,percent,offsetY)
      glCallList(barFeatureDList)
      return;
    end

    brightClr[1] = color[1]*1.5; brightClr[2] = color[2]*1.5; brightClr[3] = color[3]*1.5; brightClr[4] = color[4]
    local progress_pos = -featureBarWidth+featureBarWidth*2*percent
    glBeginEnd(GL_QUADS,DrawGradient,progress_pos, featureBarHeight+offsetY, featureBarWidth, offsetY, fbkTop,fbkBottom)
    glBeginEnd(GL_QUADS,DrawGradient,-featureBarWidth, featureBarHeight+offsetY, progress_pos, offsetY, brightClr,color)
  end

  function DrawStockpile(numStockpiled,numStockpileQued)
    --// DRAW STOCKPILED MISSLES
    glColor(1,1,1,1)
    glTexture("LuaUI/Images/nuke.png")
    local xoffset = barWidth+16
    for i=1,((numStockpiled>3) and 3) or numStockpiled do
      glTexRect(xoffset,-(11*barHeight-2)-stockpileH,xoffset-stockpileW,-(11*barHeight-2))
      xoffset = xoffset-8
    end
    glTexture(false)

    glText(numStockpiled..'/'..numStockpileQued,barWidth+1.7,-(11*barHeight-2)-16,6.5,"cno")
  end

end --//end do


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local AddBar
local DrawBars
local barsN = 0

do
  --//speedup
  local glColor      = gl.Color
  local glText       = gl.Text

  local maxBars = 20
  local bars    = {}
  local barHeightL = barHeight + 2
  local barStart   = -(barWidth + 1)
  local fBarHeightL = featureBarHeight + 2
  local fBarStart   = -(featureBarWidth + 1)

  for i=1,maxBars do bars[i] = {} end

  function AddBar(title,progress,color_index,text,color)
    barsN = barsN + 1
    local barInfo    = bars[barsN]
    barInfo.title    = title
    barInfo.progress = progress
    barInfo.color    = color or barColors[color_index]
    barInfo.text     = text
  end

  function DrawBars(fullText)
    local yoffset = 0
    for i=1,barsN do
      local barInfo = bars[i]
      DrawUnitBar(yoffset,barInfo.progress,barInfo.color)
      if (fullText) then
        if (barShader) then glMyText(1) end
        if (drawBarPercentages) then 
			glColor(1,1,1,barAlpha)
			glText(barInfo.text,barStart,yoffset,4,"r")
		end 
        if (drawBarTitles) then
          glColor(1,1,1,titlesAlpha)
          glText(barInfo.title,0,yoffset,2.5,"cd")
        end
        if (barShader) then glMyText(0) end
      end
      yoffset = yoffset - barHeightL
    end

    barsN = 0 --//reset!
  end

  function DrawBarsFeature(fullText)
    local yoffset = 0
    for i=1,barsN do
      local barInfo = bars[i]
      DrawFeatureBar(yoffset,barInfo.progress,barInfo.color)
      if (fullText) then
        if (barShader) then glMyText(1) end
        if (drawBarPercentages) then 
			glColor(1,1,1,featureBarAlpha)
			glText(barInfo.text,fBarStart,yoffset,4,"r")
		end
        if (drawBarTitles) then
          glColor(1,1,1,featureTitlesAlpha)
          glText(barInfo.title,0,yoffset,2.5,"cd")
        end
        if (barShader) then glMyText(0) end
      end
      yoffset = yoffset - fBarHeightL
    end

    barsN = 0 --//reset!
  end

end --//end do


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DrawUnitInfos

do
  --//speedup
  local glTranslate     = gl.Translate
  local glPushMatrix    = gl.PushMatrix
  local glPopMatrix     = gl.PopMatrix
  local glBillboard     = gl.Billboard
  local GetUnitIsStunned     = Spring.GetUnitIsStunned
  local GetUnitHealth        = Spring.GetUnitHealth
  local GetUnitWeaponState   = Spring.GetUnitWeaponState
  local GetUnitShieldState   = Spring.GetUnitShieldState
  local GetUnitViewPosition  = Spring.GetUnitViewPosition
  local GetUnitStockpile     = Spring.GetUnitStockpile
  local GetUnitRulesParam    = Spring.GetUnitRulesParam

  local fullText
  local ux, uy, uz
  local dx, dy, dz, dist
  local health,maxHealth,paralyzeDamage,capture,build
  local hp, hp100, emp, morph
  local reload,reloaded,reloadFrame
  local numStockpiled,numStockpileQued

  local customInfo = {}
  local ci

  function DrawUnitInfos(unitID,unitDefID, ud)
    if (not customInfo[unitDefID]) then
      customInfo[unitDefID] = {
        height        = ud.height+14,
        canJump       = (ud.customParams.canjump=="1")or(GetUnitRulesParam(unitID,"jumpReload")),
        maxShield     = ud.shieldPower,
        canStockpile  = ud.canStockpile,
        reloadTime    = ud.reloadTime,
        primaryWeapon = ud.primaryWeapon-1,
      }
    end
    ci = customInfo[unitDefID]

    fullText = true
    ux, uy, uz = GetUnitViewPosition(unitID)
    dx, dy, dz = ux-cx, uy-cy, uz-cz
    dist = dx*dx + dy*dy + dz*dz
    if (dist > infoDistance) then
      if (dist > 9000000) then
        return
      end
      fullText = false
    end

    --// GET UNIT INFORMATION
    health,maxHealth,paralyzeDamage,capture,build = GetUnitHealth(unitID)
    --if (not health)    then health=-1   elseif(health<1)    then health=1    end
    if (not maxHealth)or(maxHealth<1) then maxHealth=1 end
    if (not build)     then build=1   end

    local empHP = (not paralyzeOnMaxHealth) and health or maxHealth
    emp = (paralyzeDamage or 0)/empHP
    hp  = (health or 0)/maxHealth
    morph = UnitMorphs[unitID]

    if (drawUnitsOnFire)and(GetUnitRulesParam(unitID,"on_fire")==1) then
      onFireUnits[#onFireUnits+1]=unitID
    end

    --// BARS //-----------------------------------------------------------------------------
      --// Shield
      if (ci.maxShield>0) then
        local shieldOn,shieldPower = GetUnitShieldState(unitID)
        if (shieldOn)and(build==1)and(shieldPower<ci.maxShield) then
          shieldPower = shieldPower / ci.maxShield
          AddBar("shield",shieldPower,"shield",(fullText and floor(shieldPower*100)..'%') or '')
        end
      end

      --// HEALTH
      if (health) and ((drawFullHealthBars)or(hp<1)) and ((build==1)or(build-hp>=0.01)) then
        hp100 = hp*100; hp100 = hp100 - hp100%1; --//same as floor(hp*100), but 10% faster
        if (hp100<0) then hp100=0 elseif (hp100>100) then hp100=100 end
        if (drawFullHealthBars)or(hp100<100) then
          AddBar("health",hp,nil,(fullText and hp100..'%') or '',bfcolormap[hp100])
        end
      end

      --// BUILD
      if (build<1) then
        AddBar("building",build,"build",(fullText and floor(build*100)..'%') or '')
      end

      --// MORPHING
      if (morph) then
        local build = morph.progress
        AddBar("morph",build,"build",(fullText and floor(build*100)..'%') or '')
      end

      --// STOCKPILE
      if (ci.canStockpile) then
        local stockpileBuild
        numStockpiled,numStockpileQued,stockpileBuild = GetUnitStockpile(unitID)
        if (numStockpiled) then
          stockpileBuild = stockpileBuild or 0
          if (stockpileBuild>0) then
            AddBar("stockpile",stockpileBuild,"stock",(fullText and floor(stockpileBuild*100)..'%') or '')
          end
        end
      else
        numStockpiled = false
      end

      --// PARALYZE
	  if (emp>0.01)and(hp>0.01)and(not morph)and(emp<1e8) then
        local stunned = GetUnitIsStunned(unitID)
        local infotext = ""
        if (stunned) then
          paraUnits[#paraUnits+1]=unitID
          if (fullText) then
            infotext = floor((paralyzeDamage-empHP)/(maxHealth*empDecline)) .. 's'
          end
          emp = 1
        else
          if (emp>1) then emp=1 end
          if (fullText) then
            infotext = floor(emp*100)..'%'
          end
        end
        local empcolor_index = (stunned and ((blink and "emp_b") or "emp_p")) or ("emp")
        AddBar("paralyze",emp,empcolor_index,infotext)
      end

      --// CAPTURE (set by capture gadget)
      if ((capture or -1)>0) then
        AddBar("capture",capture,"capture",(fullText and floor(capture*100)..'%') or '')
      end
	  
	  --// CAPTURE RECHARGE
	  local captureReloadState = GetUnitRulesParam(unitID,"captureRechargeFrame")
      if (captureReloadState and captureReloadState > 0) then
		local capture = 1-(captureReloadState-gameFrame)/captureReloadTime
        AddBar("capture reload",capture,"reload",(fullText and floor(capture*100)..'%') or '')
      end

      --// RELOAD
      if (ci.reloadTime>=minReloadTime) then
        _,reloaded,reloadFrame = GetUnitWeaponState(unitID,ci.primaryWeapon)
        if (reloaded==false) then
		  local slowState = 1-(GetUnitRulesParam(unitID,"slowState") or 0)
		  local reloadTime = Spring.GetUnitWeaponState(unitID, ci.primaryWeapon , 'reloadTime')
		  ci.reloadTime = reloadTime
          reload = 1 - ((reloadFrame-gameFrame)/30) / ci.reloadTime;
          AddBar("reload",reload,"reload",(fullText and floor(reload*100)..'%') or '')
        end
      end

	  --// SHEATH
	  local sheathState = GetUnitRulesParam(unitID,"sheathState")
	  if sheathState and (sheathState < 1) then
			AddBar("sheath",sheathState,"sheath",(fullText and floor(sheathState*100)..'%') or '')
	  end
      	  
	  --// SLOW
      local slowState = GetUnitRulesParam(unitID,"slowState")
      if (slowState and (slowState>0)) then
        AddBar("slow",slowState,"slow",(fullText and floor(slowState*100)..'%') or '')
      end
	  
	  --// GOO
      local gooState = GetUnitRulesParam(unitID,"gooState")
      if (gooState and (gooState>0)) then
        AddBar("goo",gooState,"goo",(fullText and floor(gooState*100)..'%') or '')
      end
	  
      --// JUMPJET
      if (drawJumpJet)and(ci.canJump) then
        local jumpReload = GetUnitRulesParam(unitID,"jumpReload")
        if (jumpReload and (jumpReload>0) and (jumpReload<1)) then
          AddBar("jump",jumpReload,"jump",(fullText and floor(jumpReload*100)..'%') or '')
        end
      end

    if (barsN>0)or(numStockpiled) then
      glPushMatrix()
      glTranslate(ux, uy+ci.height, uz )
      glBillboard()

      --// STOCKPILE ICON
      if (numStockpiled) then
        if (barShader) then
          glMyText(1)
          DrawStockpile(numStockpiled,numStockpileQued)
          glMyText(0)
        else
          DrawStockpile(numStockpiled,numStockpileQued)
        end
      end

      --// DRAW BARS
      DrawBars(fullText)

      glPopMatrix()
    end
  end

end --// end do

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DrawFeatureInfos

do
  --//speedup
  local glTranslate     = gl.Translate
  local glPushMatrix    = gl.PushMatrix
  local glPopMatrix     = gl.PopMatrix
  local glBillboard     = gl.Billboard
  local GetFeatureHealth     = Spring.GetFeatureHealth
  local GetFeatureResources  = Spring.GetFeatureResources

  local featureDefID
  local health,maxHealth,resurrect,reclaimLeft
  local hp

  local customInfo = {}
  local ci

  function DrawFeatureInfos(featureID,featureDefID,fullText,fx,fy,fz)
    if (not customInfo[featureDefID]) then
      local featureDef   = FeatureDefs[featureDefID or -1] or {height=0,name=''}
      customInfo[featureDefID] = {
        height = featureDef.height+14,
        wall   = walls[featureDef.name],
      }
    end
    ci = customInfo[featureDefID]

    health,maxHealth,resurrect = GetFeatureHealth(featureID)
    _,_,_,_,reclaimLeft        = GetFeatureResources(featureID)
    if (not resurrect)   then resurrect=0 end
    if (not reclaimLeft) then reclaimLeft=1 end

    hp = (health or 0)/(maxHealth or 1)

    --// filter all walls and none resurrecting features
    if (resurrect == 0) and 
       (reclaimLeft == 1) and
       (hp > featureHpThreshold)
    then return end

    --// BARS //-----------------------------------------------------------------------------
      --// HEALTH
      if (hp<featureHpThreshold)and(drawFeatureHealth) then
        local hpcolor = {GetColor(fhpcolormap,hp)}
        AddBar("health",hp,nil,(fullText and floor(hp*100)..'%') or '',hpcolor)
      end

      --// RESURRECT
      if (resurrect>0) then
        AddBar("resurrect",resurrect,"resurrect",(fullText and floor(resurrect*100)..'%') or '')
      end

      --// RECLAIMING
      if (reclaimLeft>0 and reclaimLeft<1) then
        AddBar("reclaim",reclaimLeft,"reclaim",(fullText and floor(reclaimLeft*100)..'%') or '')
      end


    if (barsN>0) then
      glPushMatrix()
      glTranslate(fx,fy+ci.height,fz)
      glBillboard()

      --// DRAW BARS
      DrawBarsFeature(fullText)

      glPopMatrix()
    end
  end

end --// end do

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DrawOverlays

do
  local GL_TEXTURE_GEN_MODE    = GL.TEXTURE_GEN_MODE
  local GL_EYE_PLANE           = GL.EYE_PLANE
  local GL_EYE_LINEAR          = GL.EYE_LINEAR
  local GL_T                   = GL.T
  local GL_S                   = GL.S
  local GL_ONE                 = GL.ONE
  local GL_SRC_ALPHA           = GL.SRC_ALPHA
  local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
  local glUnit                 = gl.Unit
  local glTexGen               = gl.TexGen
  local glTexCoord             = gl.TexCoord
  local glPolygonOffset        = gl.PolygonOffset
  local glBlending             = gl.Blending
  local glDepthTest            = gl.DepthTest
  local glTexture              = gl.Texture
  local GetCameraVectors       = Spring.GetCameraVectors
  local abs                    = math.abs

  function DrawOverlays()
    --// draw an overlay for stunned units
    if (drawStunnedOverlay)and(#paraUnits>0) then
      glDepthTest(true)
      glPolygonOffset(-2, -2)
      glBlending(GL_SRC_ALPHA, GL_ONE)

      local alpha = ((5.5 * widgetHandler:GetHourTimer()) % 2) - 0.7
      glColor(0,0.7,1,alpha/4)
      for i=1,#paraUnits do
        glUnit(paraUnits[i],true)
      end
      local shift = widgetHandler:GetHourTimer() / 20

      glTexCoord(0,0)
      glTexGen(GL_T, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR)
      local cvs = GetCameraVectors()
      local v = cvs.right
      glTexGen(GL_T, GL_EYE_PLANE, v[1]*0.008,v[2]*0.008,v[3]*0.008, shift)
      glTexGen(GL_S, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR)
      v = cvs.forward
      glTexGen(GL_S, GL_EYE_PLANE, v[1]*0.008,v[2]*0.008,v[3]*0.008, shift)
      glTexture("LuaUI/Images/paralyzed.png")

      glColor(0,1,1,alpha*1.1)
      for i=1,#paraUnits do
        glUnit(paraUnits[i],true)
      end

      glTexture(false)
      glTexGen(GL_T, false)
      glTexGen(GL_S, false)
      glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
      glPolygonOffset(false)
      glDepthTest(false)

      paraUnits = {}
    end

    --// overlay for units on fire
    if (drawUnitsOnFire)and(onFireUnits) then
      glDepthTest(true)
      glPolygonOffset(-2, -2)
      glBlending(GL_SRC_ALPHA, GL_ONE)

      local alpha = abs((widgetHandler:GetHourTimer() % 2)-1)
      glColor(1,0.3,0,alpha/4)
      for i=1,#onFireUnits do
        glUnit(onFireUnits[i],true)
      end

      glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
      glPolygonOffset(false)
      glDepthTest(false)

      onFireUnits = {}
    end
  end

end --//end do


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local visibleFeatures = {}
local visibleUnits = {}

do
  local ALL_UNITS            = Spring.ALL_UNITS
  local GetCameraPosition    = Spring.GetCameraPosition
  local GetUnitDefID         = Spring.GetUnitDefID
  local glDepthMask          = gl.DepthMask

  function widget:DrawWorld()
	if Spring.IsGUIHidden() then return end
    if (#visibleUnits+#visibleFeatures==0) then
      return
    end

    --gl.Fog(false)
    --gl.DepthTest(true)
    glDepthMask(true)

    cx, cy, cz = GetCameraPosition()

    if (barShader) then gl.UseShader(barShader); glMyText(0); end

    --// draw bars of units
    local unitID,unitDefID,unitDef
    for i=1,#visibleUnits do
      unitID    = visibleUnits[i]
      unitDefID = GetUnitDefID(unitID)
      unitDef   = UnitDefs[unitDefID or -1]
      if (unitDef) then
        DrawUnitInfos(unitID, unitDefID, unitDef)
      end
    end

    --// draw bars for features
    local wx, wy, wz, dx, dy, dz, dist
    local featureInfo
    for i=1,#visibleFeatures do
      featureInfo = visibleFeatures[i]
      wx, wy, wz = featureInfo[1],featureInfo[2],featureInfo[3]
      dx, dy, dz = wx-cx, wy-cy, wz-cz
      dist = dx*dx + dy*dy + dz*dz
      if (dist < 6000000) then
        if (dist < infoDistance) then
          DrawFeatureInfos(featureInfo[4], featureInfo[5], true, wx,wy,wz)
        else
          DrawFeatureInfos(featureInfo[4], featureInfo[5], false, wx,wy,wz)
        end
      end
    end

    if (barShader) then gl.UseShader(0) end
    glDepthMask(false)

    DrawOverlays()

    glColor(1,1,1,1)
    --gl.DepthTest(false)
  end
end --//end do

do
  local GetGameFrame         = Spring.GetGameFrame
  local GetVisibleUnits      = Spring.GetVisibleUnits
  local GetVisibleFeatures   = Spring.GetVisibleFeatures
  local GetFeatureDefID      = Spring.GetFeatureDefID
  local GetFeaturePosition   = Spring.GetFeaturePosition
  local GetFeatureResources  = Spring.GetFeatureResources
  local select = select

  local sec = 0
  local sec2 = 0

  local videoFrame   = 0

  function widget:Update(dt)
    sec=sec+dt
    blink = (sec%1)<0.5

    gameFrame = GetGameFrame()

    videoFrame = videoFrame+1
    visibleUnits = GetVisibleUnits(-1,nil,false)

    sec2=sec2+dt
    if (sec2>1/3) then
      sec2 = 0
      visibleFeatures = GetVisibleFeatures(-1,nil,false,false)
      local cnt = #visibleFeatures
      local featureID,featureDefID,featureDef
      for i=cnt,1,-1 do
        featureID    = visibleFeatures[i]
        featureDefID = GetFeatureDefID(featureID) or -1
        featureDef   = FeatureDefs[featureDefID]
        --// filter trees and none destructable features
        if (featureDef)and(featureDef.destructable)and(
           (featureDef.drawTypeString=="model")or(select(5,GetFeatureResources(featureID))<1)
        ) then
          local fx,fy,fz = GetFeaturePosition(featureID)
          visibleFeatures[i] = {fx,fy,fz, featureID, featureDefID}
        else
          visibleFeatures[i] = visibleFeatures[cnt]
          visibleFeatures[cnt] = nil
          cnt = cnt-1
        end
      end
    end

  end

end --//end do

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// not 100% finished!

function MorphUpdate(morphTable)
  UnitMorphs = morphTable
end

function MorphStart(unitID,morphDef)
  --return false
end

function MorphStop(unitID)
  UnitMorphs[unitID] = nil
end

function MorphFinished(unitID)
  UnitMorphs[unitID] = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

