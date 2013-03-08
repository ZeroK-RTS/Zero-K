--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "XrayHaloSelections",
    desc      = "v0.021 XraySelections & HaloSelections (Halo on cloaked)",
    author    = "CarRepairer - Xray by trepan & Halo by jK",
    date      = "2011-06-11",
    license   = "GNU GPL, v2 or later",
    experimental = true,
    layer     = 0,
    enabled   = false,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local echo = Spring.Echo

local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local glBlending             = gl.Blending
local glColor                = gl.Color
local glCreateShader         = gl.CreateShader
local glDeleteShader         = gl.DeleteShader
local glDepthTest            = gl.DepthTest
local glFeature              = gl.Feature
local glGetShaderLog         = gl.GetShaderLog
local glPolygonOffset        = gl.PolygonOffset
local glSmoothing            = gl.Smoothing
local glUseShader            = gl.UseShader
local spEcho                 = Spring.Echo
local GetPlayerControlledUnit = Spring.GetPlayerControlledUnit
local GetMyPlayerID           = Spring.GetMyPlayerID
local TraceScreenRay          = Spring.TraceScreenRay
local GetMouseState           = Spring.GetMouseState
local GetUnitTeam             = Spring.GetUnitTeam
local GetTeamColor            = Spring.GetTeamColor
local ValidUnitID             = Spring.ValidUnitID
local ValidFeatureID          = Spring.ValidFeatureID


local spGetCameraPosition	= Spring.GetCameraPosition
local spGetGameFrame		= Spring.GetGameFrame
local spGetSelectedUnits	= Spring.GetSelectedUnits
local spGetVisibleUnits		= Spring.GetVisibleUnits
local spIsUnitSelected		= Spring.IsUnitSelected



--halo
local GL_ZERO      = GL.ZERO
local GL_KEEP      = 0x1E00
local GL_REPLACE   = 0x1E01  
local GL_INCR      = 0x1E02  
local GL_DECR      = 0x1E03
local GL_INCR_WRAP = 0x8507 
local GL_DECR_WRAP = 0x8508 
local GL_STENCIL_BITS = 0x0D57


local GetUnitRadius       = Spring.GetUnitRadius
local GetUnitViewPosition = Spring.GetUnitViewPosition
local GetUnitBasePosition = Spring.GetUnitBasePosition
local GetUnitAllyTeam     = Spring.GetUnitAllyTeam
local IsUnitVisible       = Spring.IsUnitVisible
local GetGroundNormal     = Spring.GetGroundNormal
local GetMyTeamID         = Spring.GetMyTeamID
local GetMyAllyTeamID     = Spring.GetMyAllyTeamID
local GetModKeyState      = Spring.GetModKeyState
local DrawUnitCommands    = Spring.DrawUnitCommands
local GetFeatureRadius   = Spring.GetFeatureRadius
local GetFeaturePosition = Spring.GetFeaturePosition

local GetPlayerInfo      = Spring.GetPlayerInfo

local acos   = math.acos
local PI_DEG = 180 / math.pi

local ipairs = ipairs

local glPushMatrix = gl.PushMatrix
local glTranslate  = gl.Translate
local glScale      = gl.Scale
local glRotate     = gl.Rotate
local glCallList   = gl.CallList
local glPopMatrix  = gl.PopMatrix
local glLineWidth  = gl.LineWidth
local glColor          = gl.Color
local glDrawListAtUnit = gl.DrawListAtUnit
local glUnit = gl.Unit


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local showAlly = false

options_path = 'Settings/Interface/Selection/Selection XRay&Halo'
options = {
	showally = {
		name = 'Show Ally Selections',
		type = 'bool',
		desc = 'Highlight in yellow the units your allies currently have selected.',
		value = false,
		OnChange = function(self) 
			visibleAllySelUnits = {}
			showAlly = self.value
		end,
	},
}

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

if (not glCreateShader) then
  spEcho("Hardware is incompatible with Xray shader requirements")
  return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  simple configuration parameters
--

local edgeExponent = 2.5

local doFeatures = false

local featureColor 	= { 1, 0, 1 }
local myColor 		= { 0, 1, 1 }
local allyColor 	= { 1, 0.5, 0 }
local enemyColor 	= { 1, 0, 0 }
local selectColor 	= { 0, 1, 0 }
local allySelectColor 	= { 1, 1, 0 }


-- looks a lot nicer, esp. without FSAA  (but eats into the FPS too much)
local smoothPolys = glSmoothing and true

local myPlayerID = Spring.GetMyPlayerID()

local type, data  --  for the TraceScreenRay() call
local shader


local circleLines  = 0
local circleDivs   = 32
local circleOffset = 0


local visibleAllySelUnits = {}
local visibleSelected = {}

local uCycle = 1

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function GetVisibleUnits()
    local units = spGetVisibleUnits(-1, 30, true)
    --local visibleUnits = {}
    local visibleAllySelUnits = {}
    local visibleSelected = {}
    
    for i=1, #units do
	    local unitID = units[i]
	    if (spIsUnitSelected(unitID)) then
		    visibleSelected[#visibleSelected+1] = unitID
	    elseif showAlly and WG.allySelUnits[unitID] then
		    visibleAllySelUnits[#visibleAllySelUnits+1] = unitID
	    end
    end
    
    return visibleAllySelUnits, visibleSelected

end

local function SetupCommandColors(state)
  local alpha = state and 1 or 0
  local f = io.open('cmdcolors.tmp', 'w+')
  if (f) then
    f:write('unitBox  0 1 0 ' .. alpha)
    f:close()
    Spring.SendCommands({'cmdcolors cmdcolors.tmp'})
  end
  os.remove('cmdcolors.tmp')
end

--
--  utility routine
--


local function SetTeamColor(teamID)
	if teamID == Spring.GetMyTeamID() then
		glColor(myColor)
	elseif (teamID and Spring.AreTeamsAllied(teamID, Spring.GetMyTeamID()) ) then
		glColor(allyColor)
	else
		glColor(enemyColor)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





function widget:Shutdown()
    glDeleteShader(shader)
    SetupCommandColors(true)
end


function widget:Initialize()

    showAlly = options.showally.value 
    shader = glCreateShader({
    
	uniform = {
	    edgeExponent = edgeExponent,
	},
	
	vertex = [[
	    // Application to vertex shader
	    varying vec3 normal;
	    varying vec3 eyeVec;
	    varying vec3 color;
	    uniform mat4 camera;
	    uniform mat4 caminv;
	    
	    void main()
	    {
		vec4 P = gl_ModelViewMatrix * gl_Vertex;
		
		eyeVec = P.xyz;
		
		normal  = gl_NormalMatrix * gl_Normal;
		
		color = gl_Color.rgb;
		
		gl_Position = gl_ProjectionMatrix * P;
	    }
	]],  
	
	fragment = [[
	    varying vec3 normal;
	    varying vec3 eyeVec;
	    varying vec3 color;
	    
	    uniform float edgeExponent;
	    
	    void main()
	    {
		float opac = dot(normalize(normal), normalize(eyeVec));
		opac = 1.0 - abs(opac);
		//opac = abs(opac);
		opac = pow(opac, edgeExponent);
		
		gl_FragColor.rgb = color;
		gl_FragColor.a = opac;
	    }
	]],
    })
    
    if (shader == nil) then
	Spring.Log(widget:GetInfo().name, LOG.ERROR, glGetShaderLog())
	spEcho("Xray shader compilation failed.")
	widgetHandler:RemoveWidget()
    end
    
    myPlayerID = Spring.GetMyPlayerID()
    SetupCommandColors(false)
    
    
    
    
    -- halo
    local stencilBits = gl.GetNumber(GL_STENCIL_BITS)

  if (stencilBits < 1) then
    Spring.Echo('Hardware support not available, quitting')
    widgetHandler:RemoveWidget()
    return
  end

  circleLines = gl.CreateList(function()
    gl.BeginEnd(GL.LINE_LOOP, function()
      local radstep = (2.0 * math.pi) / circleDivs
      for i = 1, circleDivs do
        local a = (i * radstep)
        gl.Vertex(math.sin(a), circleOffset, math.cos(a))
      end
    end)
    gl.BeginEnd(GL.POINTS, function()
      local radstep = (2.0 * math.pi) / circleDivs
      for i = 1, circleDivs do
        local a = (i * radstep)
        gl.Vertex(math.sin(a), circleOffset, math.cos(a))
      end
    end)
  end)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:Update()
    local mx, my = GetMouseState()
    type, data = TraceScreenRay(mx, my)

    --visibleUnits, visibleSelected = GetVisibleUnits()
    uCycle = (uCycle + 1) % 4
    if uCycle == 1 then
        visibleAllySelUnits, visibleSelected = GetVisibleUnits()
    end
end


function widget:DrawWorld()
    if Spring.IsGUIHidden() then return end
    if not( (type == 'feature') or (type == 'unit') or #visibleSelected > 0 or #visibleAllySelUnits > 0 ) then
        return
    end
	
	local visUnit,visCloakUnit,n,nc = {},{},1, 1
    for i=1, #visibleSelected do
        local unitID = visibleSelected[i]
        if IsUnitVisible(unitID,nil,true) then
			if Spring.GetUnitIsCloaked(unitID) then
			--if true then
				visCloakUnit[nc] = unitID
				nc = nc+1
			else
				visUnit[n] = unitID
				n = n+1
			end
			
        end
    end
    n = n - 1
    nc = nc - 1
	
    local visAllyUnit,visAllyCloakUnit,na,nac = {},{},1, 1
    for i=1, #visibleAllySelUnits do
        local unitID = visibleAllySelUnits[i]
        if IsUnitVisible(unitID,nil,true) then
			if Spring.GetUnitIsCloaked(unitID) then
			--if true then
				visAllyCloakUnit[nac] = unitID
				nac = nac+1
			else
				visAllyUnit[na] = unitID
				na = na+1
			end
			
        end
    end
    na = na - 1
    nac = nac - 1
	
    -- xray
	
    if (smoothPolys) then
        glSmoothing(nil, nil, true)
    end
    
    glColor(1, 1, 1, 1)
    glUseShader(shader)
    glDepthTest(true)
    glBlending(GL_SRC_ALPHA, GL_ONE)
    glPolygonOffset(-2, -2)
    
    if (type == 'unit') and ValidUnitID(data) and (data ~= GetPlayerControlledUnit(myPlayerID)) then 
        SetTeamColor(GetUnitTeam(data))
        glUnit(data, true)
    elseif (type == 'feature') and ValidFeatureID(data) then
        glColor(featureColor)
        glFeature(data, true)
    end
    
    if (n>0) then
        glColor(selectColor)
		for i=1,n do
            --if unitID and unitID ~= data then
            glUnit(visUnit[i], true)
        end
    end
    
    if (na>0) then
        glColor(allySelectColor)
        for i=1,na do
            --if unitID and unitID ~= data then
            glUnit(visAllyUnit[i], true)
        end
    end
    
    
    glPolygonOffset(false)
    glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glDepthTest(false)
    glUseShader(0)
    glColor(1, 1, 1, 1)
    
    if (smoothPolys) then
        glSmoothing(nil, nil, false)
    end
    
    
    --halo
    

    glLineWidth(3)
    gl.PointSize(3)
    gl.Blending(false)
    gl.Smoothing(true,true)
    gl.DepthTest(true)
    gl.PolygonOffset(0,-95)
    gl.StencilTest(true)
    gl.StencilMask(1)

    if (nc>0) then
        gl.ColorMask(false)
        gl.StencilFunc(GL.ALWAYS, 1, 1)
        gl.StencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
        gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
        for i=1,nc do
              glUnit(visCloakUnit[i],true,-1)
        end
      
        gl.ColorMask(true)
        glColor(selectColor)
        gl.StencilFunc(GL.NOTEQUAL, 1, 1)
        gl.StencilOp(GL_KEEP, GL_KEEP, GL_KEEP)
        gl.PolygonMode(GL.FRONT_AND_BACK,GL.LINE)
        for i=1,nc do
              glUnit(visCloakUnit[i],true,-1)
        end
        gl.PolygonMode(GL.FRONT_AND_BACK,GL.POINT)
        for i=1,nc do
            glUnit(visCloakUnit[i],true,-1)
        end
      
        gl.ColorMask(false)
        gl.StencilFunc(GL.ALWAYS, 0, 1)
        gl.StencilOp(GL_ZERO, GL_ZERO, GL_ZERO)
        gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
        for i=1,nc do
              glUnit(visCloakUnit[i],true,-1)
        end
    end 

    if (nac>0) then
        gl.ColorMask(false)
        gl.StencilFunc(GL.ALWAYS, 1, 1)
        gl.StencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
        gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
        for i=1,nac do
            glUnit(visAllyCloakUnit[i],true,-1)
        end
        
        gl.ColorMask(true)
        glColor(allySelectColor)
        gl.StencilFunc(GL.NOTEQUAL, 1, 1)
        gl.StencilOp(GL_KEEP, GL_KEEP, GL_KEEP)
        gl.PolygonMode(GL.FRONT_AND_BACK,GL.LINE)
        for i=1,nac do
			glUnit(visAllyCloakUnit[i],true,-1)
        end
        gl.PolygonMode(GL.FRONT_AND_BACK,GL.POINT)
        for i=1,nac do
			glUnit(visAllyCloakUnit[i],true,-1)
        end
        
        gl.ColorMask(false)
        gl.StencilFunc(GL.ALWAYS, 0, 1)
        gl.StencilOp(GL_ZERO, GL_ZERO, GL_ZERO)
        gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
        for i=1,nac do
            glUnit(visAllyCloakUnit[i],true,-1)
        end
    end 

	-- highlight hovered unit

	if (type == 'unit') then
		local unitID = GetPlayerControlledUnit(GetMyPlayerID())
		--if (data ~= unitID and Spring.GetUnitIsCloaked(data) ) then
		if (data ~= unitID ) then
		
			glLineWidth(4)
			gl.PointSize(4)
		
			gl.ColorMask(false)
			gl.StencilFunc(GL.ALWAYS, 1, 1); 
			gl.StencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
			gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
			gl.Unit(data,true,-1)
			
			gl.ColorMask(true)
			gl.StencilFunc(GL.NOTEQUAL, 1, 1)
			gl.StencilOp(GL_KEEP, GL_KEEP, GL_KEEP)
			
			SetTeamColor(GetUnitTeam(data))
			gl.PolygonMode(GL.FRONT_AND_BACK,GL.LINE)
			gl.Unit(data,true,-1)
			gl.PolygonMode(GL.FRONT_AND_BACK,GL.POINT)
			gl.Unit(data,true,-1)
			
			gl.ColorMask(false)
			gl.StencilFunc(GL.ALWAYS, 0, 1); 
			gl.StencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE)
			gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
			gl.Unit(data,true,-1)
			
			-- also draw the unit's command queue
			--[[
			local a,c,m,s = GetModKeyState()
			if (m)or(not selUnits[1]) then
			DrawUnitCommands(data)
			end
			--]]
		end
		
	end

	gl.ColorMask(true)
	gl.StencilTest(false)
	glColor(1,1,1,1)
	glLineWidth(1)
	gl.PointSize(1)
	gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
	gl.Blending(true)
	--gl.Smoothing(true,true)
	gl.DepthTest(false)
	gl.DepthMask(false)
	gl.PolygonOffset(false)
    
    
end
              

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------