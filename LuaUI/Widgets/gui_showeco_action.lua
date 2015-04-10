local version = "v1.003"
function widget:GetInfo()
  return {
    name      = "Showeco and Grid Drawer",
    desc      = "Register an action called Showeco & draw overdrive overlay.", --"acts like F4",
    author    = "xponen",
    date      = "July 19 2013",
    license   = "GNU GPL, v2 or later",
	layer	  = 0, --only layer > -4 works because it seems to be blocked by something.
	enabled   = true,  --  loaded by default?
    handler   = true,
  }
end

local pylon ={}

local spGetMapDrawMode = Spring.GetMapDrawMode
local spSendCommands   = Spring.SendCommands

local function ToggleShoweco()
  WG.showeco = not WG.showeco

  if (not WG.metalSpots and (spGetMapDrawMode() == "metal") ~= WG.showeco) then
    spSendCommands("showmetalmap")
  end
end

options_path = 'Settings/Interface/Map'
options = {
	showeco = {
		name = 'Show Eco Overlay',
		desc = 'Show metal, geo spots and energy grid',
		hotkey = {key='f4', mod=''},
		type ='button',
		action='showeco',
		noAutoControlFunc = true,
		OnChange = ToggleShoweco
	},
}

--------------------------------------------------------------------------------------
--Grid drawing. Copied and trimmed from unit_mex_overdrive.lua gadget (by licho & googlefrog)
VFS.Include("LuaRules/Configs/constants.lua", nil, VFS.ZIP_FIRST)
VFS.Include("LuaRules/Configs/mex_overdrive.lua", nil, VFS.ZIP_FIRST)
VFS.Include("LuaRules/Utilities/glVolumes.lua") --have to import this incase it fail to load before this widget

local spGetSelectedUnits   = Spring.GetSelectedUnits
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitPosition    = Spring.GetUnitPosition
local spGetActiveCommand   = Spring.GetActiveCommand
local spTraceScreenRay     = Spring.TraceScreenRay
local spGetMouseState      = Spring.GetMouseState
local spAreTeamsAllied     = Spring.AreTeamsAllied
local spGetMyTeamID        = Spring.GetMyTeamID
local spGetUnitPosition    = Spring.GetUnitPosition
local spValidUnitID        = Spring.ValidUnitID
local spGetUnitRulesParam  = Spring.GetUnitRulesParam
local spGetSpectatingState = Spring.GetSpectatingState
local spGetBuildFacing	   = Spring.GetBuildFacing
local spPos2BuildPos       = Spring.Pos2BuildPos

local glVertex        = gl.Vertex
local glCallList      = gl.CallList
local glColor         = gl.Color
local glBeginEnd      = gl.BeginEnd
local glCreateList    = gl.CreateList

local GL_TRIANGLE_FAN = GL.TRIANGLE_FAN

local pylons = {count = 0, data = {}}
local pylonByID = {}

local pylonDefs = {}

for i=1,#UnitDefs do
	local udef = UnitDefs[i]
	if (tonumber(udef.customParams.pylonrange) or 0 > 0) then
		pylonDefs[i] = {
			range = tonumber(udef.customParams.pylonrange) or DEFAULT_PYLON_RANGE
		}
	end
end

local floor = math.floor
local circlePolys = 0 -- list for circles

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- local functions

local disabledColor = { 0.6,0.7,0.5,0.2}

local function HSLtoRGB(ch,cs,cl)
 
if cs == 0 then
  cr = cl
  cg = cl
  cb = cl
else
  if cl < 0.5 then temp2 = cl * (cl + cs)
  else temp2 = (cl + cs) - (cl * cs)
  end
 
  temp1 = 2 * cl - temp2
  tempr = ch + 1 / 3
 
  if tempr > 1 then tempr = tempr - 1 end
  tempg = ch
  tempb = ch - 1 / 3
  if tempb < 0 then tempb = tempb + 1 end
 
  if tempr < 1 / 6 then cr = temp1 + (temp2 - temp1) * 6 * tempr
  elseif tempr < 0.5 then cr = temp2
  elseif tempr < 2 / 3 then cr = temp1 + (temp2 - temp1) * ((2 / 3) - tempr) * 6
  else cr = temp1
  end
 
  if tempg < 1 / 6 then cg = temp1 + (temp2 - temp1) * 6 * tempg
  elseif tempg < 0.5 then cg = temp2
  elseif tempg < 2 / 3 then cg = temp1 + (temp2 - temp1) * ((2 / 3) - tempg) * 6
  else cg = temp1
  end
 
  if tempb < 1 / 6 then cb = temp1 + (temp2 - temp1) * 6 * tempb
  elseif tempb < 0.5 then cb = temp2
  elseif tempb < 2 / 3 then cb = temp1 + (temp2 - temp1) * ((2 / 3) - tempb) * 6
  else cb = temp1
  end
 
end
return {cr,cg,cb, 0.2}
end --HSLtoRGB


local function GetGridColor(efficiency) 
 	local n = efficiency      
	-- mex has no esource/esource has no mex
	if n==0 then
		return {1, .25, 1, 0.2}
	else
		if n < 3.5 then 
			h = 5760/(3.5+2)^2 
		else
			h=5760/(n+2)^2
		end
		return HSLtoRGB(h/255,1,0.5)
	end
        
--[[
--	average/good - will be green
	local good = 3
	--max/inefficient - will be red
	local bad = 15
		 -- mex has no esource/esource has no mex
	if n == 0 then
		return {1, 0.25, 1, 0.25}
	else
                -- red, green, blue
                r, g, b = 0, 0, 0
                
                if n <= good then
                        b = (1 - n/good)^.5
                        g = (n/good)^.5
                elseif n <= bad then
                        -- difference of bad and good
                        local z = bad-good
                        -- n - good, since we are inside "good-bad" now
                        -- n must not be bigger than z
                        nRemain = min(n-good, z)
                        
                        g = 1 - nRemain/z
                        r = (nRemain/z)^.3
                else
                        r = bad/n
                end
        end
	return {r, g, b, 0.2}]]--
end 

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Unit Handling

function InitializeUnits()
	local allUnits = Spring.GetAllUnits()
	for i=1, #allUnits do
		local unitID = allUnits[i]
		local unitDefID = spGetUnitDefID(unitID)
		local unitTeam = Spring.GetUnitTeam(unitID)
		widget:UnitCreated(unitID, unitDefID, unitTeam)
	end
end

local function addUnit(unitID, unitDefID, unitTeam)
	if pylonDefs[unitDefID] and not pylonByID[unitID] then
		local spec, fullview = spGetSpectatingState()
		spec = spec or fullview
		if spec or spAreTeamsAllied(unitTeam, spGetMyTeamID()) then
			local x,y,z = spGetUnitPosition(unitID)
			pylons.count = pylons.count + 1
			pylons.data[pylons.count] = {unitID = unitID, x = x, y = y, z = z, range = pylonDefs[unitDefID].range}
			pylonByID[unitID] = pylons.count
		end
	end
end

local function removeUnit(unitID, unitDefID, unitTeam)
	pylons.data[pylonByID[unitID]] = pylons.data[pylons.count]
	pylonByID[pylons.data[pylons.count].unitID] = pylonByID[unitID]
	pylons.data[pylons.count] = nil
	pylons.count = pylons.count - 1
	pylonByID[unitID] = nil
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	addUnit(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if pylonByID[unitID] then
		removeUnit(unitID, unitDefID, unitTeam)
	end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	addUnit(unitID, unitDefID, unitTeam)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local prevFullView = false
local prevTeamID = -1
local doTest = 0

function widget:Update(dt)
	doTest = doTest + 1
	if doTest > 30 then
		local teamID = Spring.GetMyTeamID()
		local _, fullView = Spring.GetSpectatingState()
		if (fullView and not prevFullView) or (teamID ~= prevTeamID) then
			InitializeUnits()
			prevFullView = true
		end
		prevFullView = fullView
		prevTeamID = teamID
		doTest = 0
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:Initialize()
	local circleDivs = 32
	circlePolys = glCreateList(function()
		glBeginEnd(GL_TRIANGLE_FAN, function()
		local radstep = (2.0 * math.pi) / circleDivs
			for i = 1, circleDivs do
				local a = (i * radstep)
				glVertex(math.sin(a), 0, math.cos(a))
			end
		end)
	end)
	
	InitializeUnits()
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Drawing

local drawList = 0
local lastDrawnFrame = 0
local lastFrame = 2

function widget:GameFrame(f)
	if f%32 == 2 then
		lastFrame = f
	end
end

local function makePylonListVolume()
	local i = 1
	while i <= pylons.count do
		local data = pylons.data[i]
		local unitID = data.unitID
		if spValidUnitID(unitID) then
			local efficiency = spGetUnitRulesParam(unitID, "gridefficiency") or -1
			if efficiency == -1 then
				glColor(disabledColor)
			else
				local color = GetGridColor(efficiency)
				glColor(color)
			end
			--gl.Utilities.DrawMyCylinder(data.x,data.y,data.z,data.range,data.range,35)
			gl.Utilities.DrawGroundCircle(data.x, data.z, data.range)
			i = i + 1
		else
			pylons.data[i] = pylons.data[pylons.count]
			pylonByID[pylons.data[i].unitID] = i
			pylons.data[pylons.count] = nil
			pylons.count = pylons.count - 1
		end
	end  
end

local function HighlightPylons()
	if lastDrawnFrame < lastFrame then
		lastDrawnFrame = lastFrame
		drawList = gl.CreateList(makePylonListVolume)
	end
	--gl.Utilities.DrawVolume(drawList)
	gl.CallList(drawList)
	--[[
	local i = 1
	while i <= pylons.count do
		local data = pylons.data[i]
		local unitID = data.unitID
		if spValidUnitID(unitID) then
			local efficiency = spGetUnitRulesParam(unitID, "gridefficiency") or -1
			if efficiency == -1 then
				glColor(disabledColor)
			else
				local color = GetGridColor(efficiency)
				glColor(color)
			end
			
			gl.Utilities.DrawGroundCircle(data.x, data.z, data.range)
			i = i + 1
		else
			pylons.data[i] = pylons.data[pylons.count]
			pylonByID[pylons.data[i].unitID] = i
			pylons.data[pylons.count] = nil
			pylons.count = pylons.count - 1
		end
	end  
	--]]
end 

local function HighlightPlacement(unitDefID)
	local mx, my = spGetMouseState()
	local _, coords = spTraceScreenRay(mx, my, true, true)
	if coords then 
		local radius = pylonDefs[unitDefID].range
		if (radius ~= 0) then
			x, _, z = Spring.Pos2BuildPos( unitDefID, coords[1], 0, coords[3], spGetBuildFacing())
			glColor(disabledColor)
			gl.Utilities.DrawGroundCircle(x,z, radius)
		end
	end 
end

function widget:DrawWorldPreUnit()
	if Spring.IsGUIHidden() then return end
	
	local _, cmd_id = spGetActiveCommand()  -- show pylons if pylon is about to be placed
	if (cmd_id) then 
		if pylonDefs[-cmd_id] then 
			HighlightPylons()
			HighlightPlacement(-cmd_id)
			glColor(1,1,1,1)
			return
		end 
	end
	
	local selUnits = spGetSelectedUnits()  -- or show it if its selected 	
	if selUnits then 
		for i=1,#selUnits do 
			local ud = spGetUnitDefID(selUnits[i])
			if (pylonDefs[ud]) then 
				HighlightPylons()
				glColor(1,1,1,1)
				return 
			end 
		end
	end
	
	local showecoMode = WG.showeco
	if showecoMode then
		HighlightPylons()
		glColor(1,1,1,1)
		return
	end
end
