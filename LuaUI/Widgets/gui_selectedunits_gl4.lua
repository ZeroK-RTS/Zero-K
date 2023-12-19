function widget:GetInfo()
	return {
		name = "Selected Units GL4",
		desc = "Draw selection markers under units",
		author = "Fiendicus Prime, Beherith, Floris",
		date = "2023-12-19",
		license = "GNU GPL, v2 or later",
		-- Somewhere between layer -40 and -30 GetUnitUnderCursor starts
		-- returning nil before GetUnitsInSelectionBox includes that unit.
		layer = -30,
		enabled = true,
	}
end

-- Configurable Parts:

local lineWidth, showOtherSelections, platterOpacity

---- GL4 Backend Stuff----
local selectionVBO = nil
local selectShader = nil
local luaShaderDir = "LuaUI/Widgets/Include/"

local hasBadCulling = ((Platform.gpuVendor == "AMD" and Platform.osFamily == "Linux") == true)

-- Localize for speedups:
local spGetGameFrame = Spring.GetGameFrame
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitIsDead = Spring.GetUnitIsDead
local spGetUnitTeam = Spring.GetUnitTeam
local spLoadCmdColorsConfig = Spring.LoadCmdColorsConfig
local spValidUnitID = Spring.ValidUnitID

local SafeWGCall = function(fnName, param1) if fnName then return fnName(param1) else return nil end end
local GetUnitUnderCursor = function(onlySelectable) return SafeWGCall(WG.PreSelection_GetUnitUnderCursor, onlySelectable) end
local GetUnitsInSelectionBox = function() return SafeWGCall(WG.PreSelection_GetUnitsInSelectionBox) end
local IsSelectionBoxActive = function() return SafeWGCall(WG.PreSelection_IsSelectionBoxActive) end

local glStencilFunc         = gl.StencilFunc
local glStencilOp           = gl.StencilOp
local glStencilTest         = gl.StencilTest
local glStencilMask         = gl.StencilMask
local glDepthTest           = gl.DepthTest
local glClear               = gl.Clear
local GL_ALWAYS             = GL.ALWAYS
local GL_NOTEQUAL           = GL.NOTEQUAL
local GL_KEEP               = 0x1E00 --GL.KEEP
local GL_STENCIL_BUFFER_BIT = GL.STENCIL_BUFFER_BIT
local GL_REPLACE            = GL.REPLACE
local GL_POINTS				= GL.POINTS

local selUnits, isLocalSelection = {}, {}
local doUpdate

local unitScale = {}
local unitCanFly = {}
local unitBuilding = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	unitScale[unitDefID] = (7.5 * ( unitDef.xsize^2 + unitDef.zsize^2 ) ^ 0.5) + 8
	if unitDef.canFly then
		unitCanFly[unitDefID] = true
		unitScale[unitDefID] = unitScale[unitDefID] * 0.7
	elseif unitDef.isBuilding or unitDef.isFactory or unitDef.speed==0 then
		unitBuilding[unitDefID] = {
			unitDef.xsize * 8.2 + 12,
			unitDef.zsize * 8.2 + 12
		}
	end
end

local function AddSelected(unitID, unitTeam, preselection)
	if spValidUnitID(unitID) ~= true or spGetUnitIsDead(unitID) == true then return end
	local gf = spGetGameFrame()

	local unitDefID = spGetUnitDefID(unitID)
	if unitDefID == nil then return end -- these cant be selected

	local numVertices = 64

	local radius = unitScale[unitDefID]

	local width, length
	if unitCanFly[unitDefID] then
		numVertices = 3 -- triangles for planes
		width = radius
		length = radius
	elseif unitBuilding[unitDefID] then
		numVertices = 4
		width = unitBuilding[unitDefID][1]
		length = unitBuilding[unitDefID][2]
	else
		width = radius
		length = radius
	end

	pushElementInstance(
		selectionVBO, -- push into this Instance VBO Table
		{
			length, width, 0, 0,  -- lengthwidthcornerheight
			unitTeam, -- teamID
			numVertices, -- how many trianges should we make
			gf, preselection and 1 or 0, 0, 0, -- the gameFrame (for animations), whether to animate (for preselection) and unused parameters
			0, 1, 0, 1, -- These are our default UV atlas tranformations
			0, 0, 0, 0 -- these are just padding zeros, that will get filled in
		},
		unitID, -- this is the key inside the VBO TAble,
		true, -- update existing element
		nil, -- noupload, dont use unless you
		unitID -- last one should be UNITID?
	)
end

local function RemoveSelected(unitID)
	doUpdate = true
	isLocalSelection[unitID] = nil
	selUnits[unitID] = nil
	if selectionVBO and selectionVBO.instanceIDtoIndex[unitID] then
		popElementInstance(selectionVBO, unitID)
	end
end

local function FindPreselUnits()
	local preselection = {}
	local hoverUnitID = GetUnitUnderCursor(false)
	if hoverUnitID then
		preselection[hoverUnitID] = true
	end
	for _, unitID in pairs(GetUnitsInSelectionBox() or {}) do
		preselection[unitID] = true
	end
	return preselection
end

-- Hide/show the default Spring selection boxes
local function UpdateCmdColorsConfig(isOn)
	WG.widgets_handling_selection = WG.widgets_handling_selection or 0
	WG.widgets_handling_selection = WG.widgets_handling_selection + (isOn and 1 or -1)
	if not isOn and WG.widgets_handling_selection > 0 then
		return
	end
	spLoadCmdColorsConfig('unitBox  0 1 0 ' .. (isOn and 0 or 1))
end

local function init()
	lineWidth = tonumber(options.linewidth.value) or 3.0
	showOtherSelections = options.showallselections.value
	platterOpacity = tonumber(options.platteropacity.value) or 0.2
	doUpdate = true

	for unitID, _ in pairs(selUnits) do
		RemoveSelected(unitID)
	end

	local DPatUnit = VFS.Include(luaShaderDir.."DrawPrimitiveAtUnit.lua")
	local InitDrawPrimitiveAtUnit = DPatUnit.InitDrawPrimitiveAtUnit
	local shaderConfig = DPatUnit.shaderConfig -- MAKE SURE YOU READ THE SHADERCONFIG TABLE!
	shaderConfig.BILLBOARD = 0
	shaderConfig.TRANSPARENCY = platterOpacity
	shaderConfig.ANIMATION = 1
	shaderConfig.INITIALSIZE = 0.6
	shaderConfig.GROWTHRATE = 15.0
	shaderConfig.BREATHERATE = 15.0
	shaderConfig.BREATHESIZE = 0.05
	shaderConfig.HEIGHTOFFSET = 0
	shaderConfig.USETEXTURE = 0
	shaderConfig.POST_SHADING = "fragColor.rgba = vec4(g_color.rgb, texcolor.a * TRANSPARENCY + addRadius);"
	selectionVBO, selectShader = InitDrawPrimitiveAtUnit(shaderConfig, "selectedUnits")

	return selectionVBO ~= nil
end

options_path = 'Settings/Interface/Selection/SelectedUnits'
options_order = {'showallselections', 'linewidth', 'platteropacity'}
options = {
	showallselections = {
		name = 'Show Other Selections',
		desc = 'Show selections of other players',
		type = 'bool',
		value = 'true',
		OnChange = function(self)
			showOtherSelections = nil
			init()
			-- showOtherSelections = self.value
		end,
	},
	linewidth = {
		name = 'Line Width',
		desc = '',
		type = 'radioButton',
		items = {
			{name = 'Thin', key='1.5'},
			{name = 'Standard', key='3'},
		},
		value = '3',
		noHotkey = true,
		OnChange = function(self)
			lineWidth = nil
			init()
			-- lineWidth = tonumber(self.value) or lineWidth
		end,
	},
	platteropacity = {
		name = 'Platter Opacity',
		desc = '',
		type = 'number',
		min = 0.0,
		max = 0.3,
		step = 0.1,
		def = 0.2,
		OnChange = function(self)
			platterOpacity = nil
			init()
			-- opacity = self.value
		end,
	}
}

-- Callins

function widget:DrawWorldPreUnit()
	if selectionVBO.usedElements == 0 then
		return
	end

	if hasBadCulling then
		gl.Culling(false)
	end
	
	selectShader:Activate()
	selectShader:SetUniform("iconDistance", 99999) -- pass
	glStencilTest(true) --https://learnopengl.com/Advanced-OpenGL/Stencil-testing
	glDepthTest(true)
	glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE) -- Set The Stencil Buffer To 1 Where Draw Any Polygon		this to the shader
	glClear(GL_STENCIL_BUFFER_BIT ) -- set stencil buffer to 0

	glStencilFunc(GL_NOTEQUAL, 1, 1) -- use NOTEQUAL instead of ALWAYS to ensure that overlapping transparent fragments dont get written multiple times
	glStencilMask(1)

	selectShader:SetUniform("addRadius", 0)
	selectionVBO.VAO:DrawArrays(GL_POINTS, selectionVBO.usedElements)

	glStencilFunc(GL_NOTEQUAL, 1, 1)
	glStencilMask(0)
	glDepthTest(true)

	selectShader:SetUniform("addRadius", lineWidth)
	selectionVBO.VAO:DrawArrays(GL_POINTS, selectionVBO.usedElements)

	glStencilMask(1)
	glStencilFunc(GL_ALWAYS, 1, 1)
	glDepthTest(true)

	selectShader:Deactivate()

	-- This is the correct way to exit out of the stencil mode, to not break drawing of area commands:
	glStencilTest(false)
	glStencilMask(255)
	glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP)
	glClear(GL_STENCIL_BUFFER_BIT)
	-- All the above are needed :(
end

function widget:SelectionChanged()
	doUpdate = true
end

function widget:Update(dt)
	if not doUpdate and not IsSelectionBoxActive() then
		return
	end
	doUpdate = false

	local newSelUnits = {}
	-- Local selections
	for _, unitID in pairs(spGetSelectedUnits()) do
		if not selUnits[unitID] or not isLocalSelection[unitID] then
			AddSelected(unitID, 255)
			selUnits[unitID] = true
			isLocalSelection[unitID] = true
		end
		newSelUnits[unitID] = true
	end
	-- Preselections
	for unitID, _ in pairs(FindPreselUnits()) do
		if not selUnits[unitID] or not isLocalSelection[unitID] then
			AddSelected(unitID, 255, true)
			selUnits[unitID] = true
			isLocalSelection[unitID] = true
		end
		newSelUnits[unitID] = true
	end
	-- Ally/other selections
	if showOtherSelections then
		for unitID, _ in pairs(WG.allySelUnits or {}) do
			if not selUnits[unitID] or (isLocalSelection[unitID] and not newSelUnits[unitID]) then
				AddSelected(unitID, spGetUnitTeam(unitID))
				selUnits[unitID] = true
				isLocalSelection[unitID] = nil
			end
			newSelUnits[unitID] = true
		end
	end
	-- Clean up deselected units
	for unitID, _ in pairs(selUnits) do
		if not newSelUnits[unitID] then
			RemoveSelected(unitID)
		end
	end
end

function widget:UnitDestroyed(unitID)
	RemoveSelected(unitID)
end

function widget:UnitGiven()
	doUpdate = true
end

function widget:UnitTaken(unitID)
	RemoveSelected(unitID)
end

function widget:VisibleUnitAdded()
	doUpdate = true
end

function widget:VisibleUnitRemoved(unitID)
	RemoveSelected(unitID)
end

function widget:VisibleUnitsChanged()
	-- Only called on start/stop of api_unit_tracker
    init()
end

function widget:Initialize()
	if not gl.CreateShader or not init() then
		widgetHandler:RemoveWidget()
		return
	end
	UpdateCmdColorsConfig(true)
end

function widget:Shutdown()
	UpdateCmdColorsConfig(false)
end
