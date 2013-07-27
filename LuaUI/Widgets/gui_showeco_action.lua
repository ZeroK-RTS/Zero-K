local version = "v1.002"
function widget:GetInfo()
  return {
    name      = "Showeco and Grid Drawer",
    desc      = "Register an action called Showeco & draw overdrive overlay.", --"acts like F4",
    author    = "xponen",
    date      = "July 19 2013",
    license   = "GNU GPL, v2 or later",
	layer		= 0, --only layer > -4 works because it seems to be blocked by something.
	enabled   = true,  --  loaded by default?
	alwaysStart    = true,
    handler   = true,
  }
end

local pylon ={}

options_path = 'Settings/Interface/Map'
options = {
	showeco = {
		name = 'Show Eco Overlay',
		desc = 'Show metal, geo spots and energy grid',
		hotkey = {key='f4', mod=''},
		type ='button',
		action='showeco',
		noAutoControlFunc = true,
		OnChange = function() WG.showeco = not WG.showeco end
	},
}

--------------------------------------------------------------------------------------
--Action registration. Copied fully from gui_epicmenu.lua (widget by CarRepairer)
function PylonOut(pylonString)
	local chunk, err = loadstring("return"..pylonString) --This code is from cawidgets.lua
	pylon = chunk and chunk() or {}
end
--------------------------------------------------------------------------------------
--Grid drawing. Copied and trimmed from unit_mex_overdrive.lua gadget (by licho & googlefrog)
VFS.Include("LuaRules/Configs/constants.lua", nil, VFS.ZIP_FIRST)
VFS.Include("LuaRules/Configs/mex_overdrive.lua", nil, VFS.ZIP_FIRST)
VFS.Include("LuaRules/Utilities/glVolumes.lua") --have to import this incase it fail to load before this widget

local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitDefID     = Spring.GetUnitDefID
local spGetUnitPosition  = Spring.GetUnitPosition
local spGetActiveCommand = Spring.GetActiveCommand
local spTraceScreenRay   = Spring.TraceScreenRay
local spGetMouseState    = Spring.GetMouseState

local glVertex        = gl.Vertex
local glCallList      = gl.CallList
local glColor         = gl.Color
local glBeginEnd      = gl.BeginEnd
local glCreateList    = gl.CreateList

local GL_TRIANGLE_FAN = GL.TRIANGLE_FAN

local pylonDefs = {}

for i=1,#UnitDefs do
	local udef = UnitDefs[i]
	if (tonumber(udef.customParams.pylonrange) or 0 > 0) then
		pylonDefs[i] = {
			range = tonumber(udef.customParams.pylonrange) or DEFAULT_PYLON_RANGE,
			extractor = (udef.customParams.ismex and true or false),
			neededLink = tonumber(udef.customParams.neededlink) or false,
			keeptooltip = udef.customParams.keeptooltip or false,
		}
	end
		
end

local floor = math.floor

local circlePolys = 0 -- list for circles

function widget:Initialize()
	widgetHandler:RegisterGlobal(widget,"PylonOut", PylonOut)
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
end

local disabledColor = { 0.6,0.7,0.5,0.2}

local function HighlightPylons(selectedUnitDefID)
	for id, data in pairs(pylon) do
		if pylonDefs[spGetUnitDefID(id)] then
			local radius = pylonDefs[spGetUnitDefID(id)].range
			if (radius) then 
				glColor(data.color[1],data.color[2], data.color[3], data.color[4])

				local x,y,z = spGetUnitPosition(id)
				gl.Utilities.DrawGroundCircle(x,z, radius)
			end 
		end
	end 
	
	if selectedUnitDefID then 
		local mx, my = spGetMouseState()
		local _, coords = spTraceScreenRay(mx, my, true, true)
		if coords then 
			local radius = pylonDefs[selectedUnitDefID].range
			if (radius == 0) then
			else
				local x = floor((coords[1])/16)*16 +8
				local z = floor((coords[3])/16)*16 +8
				glColor(disabledColor)
				gl.Utilities.DrawGroundCircle(x,z, radius)
			end
		end 
	end 
end 


function widget:DrawWorldPreUnit()
	if Spring.IsGUIHidden() then return end
	
	local _, cmd_id = spGetActiveCommand()  -- show pylons if pylon is about to be placed
	if (cmd_id) then 
		if pylonDefs[-cmd_id] then 
			HighlightPylons(-cmd_id)
			glColor(1,1,1,1)
			return
		end 
	end
	
	local selUnits = spGetSelectedUnits()  -- or show it if its selected 	
	if selUnits then 
		for i=1,#selUnits do 
			local ud = spGetUnitDefID(selUnits[i])
			if (pylonDefs[ud]) then 
				HighlightPylons(nil)
				glColor(1,1,1,1)
				return 
			end 
		end
	end
	
	local showecoMode = WG.showeco
	if showecoMode then
		HighlightPylons(nil)
		glColor(1,1,1,1)
		return
	end
end