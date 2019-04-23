local version = "v1.003"
function widget:GetInfo()
  return {
    name      = "Showeco and Grid Drawer",
    desc      = "Register an action called Showeco & draw overdrive overlay.", --"acts like F4",
    author    = "xponen, ashdnazg",
    date      = "July 19 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0, --only layer > -4 works because it seems to be blocked by something.
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

WG.ToggleShoweco = ToggleShoweco

--------------------------------------------------------------------------------------
--Grid drawing. Copied and trimmed from unit_mex_overdrive.lua gadget (by licho & googlefrog)
VFS.Include("LuaRules/Configs/constants.lua", nil, VFS.ZIP_FIRST)
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
local spGetBuildFacing     = Spring.GetBuildFacing
local spPos2BuildPos       = Spring.Pos2BuildPos

local glVertex        = gl.Vertex
local glCallList      = gl.CallList
local glColor         = gl.Color
local glCreateList    = gl.CreateList

--// gl const

local pylons = {count = 0, data = {}}
local pylonByID = {}

local pylonDefs = {}

for i=1,#UnitDefs do
	local udef = UnitDefs[i]
	local range = tonumber(udef.customParams.pylonrange)
	if (range and range > 0) then
		pylonDefs[i] = range
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Utilities

local drawList = 0
local disabledDrawList = 0
local lastDrawnFrame = 0
local lastFrame = 2
local highlightQueue = false
local prevCmdID
local lastCommandsCount

local function ForceRedraw()
	lastDrawnFrame = 0
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Menu Options

local drawAlpha = 0.2
WG.showeco_always_mexes = true -- No OnChange when not changed from the default.

options_path = 'Settings/Interface/Economy Overlay'
options_order = {'start_with_showeco', 'always_show_mexes', 'mergeCircles', 'drawQueued'}
options = {
	start_with_showeco = {
		name = "Start with economy overly",
		desc = "Game starts with Economy Overlay enabled",
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function(self)
			if (self.value) then
				WG.showeco = self.value
			end
		end,
	},
	always_show_mexes = {
		name = "Always show Mexes",
		desc = "Show metal extractors even when the full economy overlay is not enabled.",
		type = 'bool',
		value = true,
		OnChange = function(self)
			WG.showeco_always_mexes = self.value
		end,
	},
	mergeCircles = {
		name = "Draw merged grid circles",
		desc = "Merge overlapping grid circle visualisation. Does not work on older hardware and should automatically disable.",
		type = 'bool',
		value = true,
		OnChange = ForceRedraw,
	},
	drawQueued = {
		name = "Draw grid in queue",
		desc = "Shows the grid of not-yet constructed buildings in the queue of a selected constructor. Activates only when placing grid structures.",
		type = 'bool',
		value = true,
		OnChange = ForceRedraw,
	},
}
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- local functions

local disabledColor = { 0.6,0.7,0.5, drawAlpha}
local placementColor = { 0.6, 0.7, 0.5, drawAlpha} -- drawAlpha on purpose!

local GetGridColor = VFS.Include("LuaUI/Headers/overdrive.lua")

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Unit Handling

local function addUnit(unitID, unitDefID, unitTeam)
	if pylonDefs[unitDefID] and not pylonByID[unitID] then
		local spec, fullview = spGetSpectatingState()
		spec = spec or fullview
		if spec or spAreTeamsAllied(unitTeam, spGetMyTeamID()) then
			local x,y,z = spGetUnitPosition(unitID)
			pylons.count = pylons.count + 1
			pylons.data[pylons.count] = {unitID = unitID, x = x, y = y, z = z, range = pylonDefs[unitDefID]}
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

local function InitializeUnits()
	pylons = {count = 0, data = {}}
	pylonByID = {}
	local allUnits = Spring.GetAllUnits()
	for i=1, #allUnits do
		local unitID = allUnits[i]
		local unitDefID = spGetUnitDefID(unitID)
		local unitTeam = Spring.GetUnitTeam(unitID)
		widget:UnitCreated(unitID, unitDefID, unitTeam)
	end
end

local prevFullView = false
local prevTeamID = -1

function widget:Update(dt)
	local teamID = Spring.GetMyTeamID()
	local _, fullView = Spring.GetSpectatingState()
	if (fullView ~= prevFullView) or (teamID ~= prevTeamID) then
		InitializeUnits()
	end
	prevFullView = fullView
	prevTeamID = teamID
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Drawing

function widget:Initialize()
	InitializeUnits()
end

function widget:Shutdown()
	gl.DeleteList(drawList or 0)
	gl.DeleteList(disabledDrawList or 0)
end

function widget:GameFrame(f)
	if f%32 == 2 then
		lastFrame = f
	end
end

local function makePylonListVolume(onlyActive, onlyDisabled)
	local drawGroundCircle = options.mergeCircles.value and gl.Utilities.DrawMergedGroundCircle or gl.Utilities.DrawGroundCircle
	local i = 1
	while i <= pylons.count do
		local data = pylons.data[i]
		local unitID = data.unitID
		if spValidUnitID(unitID) then
			local efficiency = spGetUnitRulesParam(unitID, "gridefficiency") or -1
			if efficiency == -1 and not onlyActive then
				glColor(disabledColor)
				drawGroundCircle(data.x, data.z, data.range)
			elseif efficiency ~= -1 and not onlyDisabled then
				local color = GetGridColor(efficiency, drawAlpha)
				glColor(color)
				drawGroundCircle(data.x, data.z, data.range)
			end
			i = i + 1
		else
			pylons.data[i] = pylons.data[pylons.count]
			pylonByID[pylons.data[i].unitID] = i
			pylons.data[pylons.count] = nil
			pylons.count = pylons.count - 1
		end
	end
	if highlightQueue and not onlyActive then
		local selUnits = spGetSelectedUnits()
		for i=1,#selUnits do
			local unitID = selUnits[i]
			local unitDefID = spGetUnitDefID(unitID)
			if UnitDefs[unitDefID].isBuilder then
				local cmdQueue = Spring.GetCommandQueue(unitID, -1)
				if cmdQueue then
					for i = 1, #cmdQueue do
						local cmd = cmdQueue[i]
						local radius = pylonDefs[-cmd.id]
						if radius then
							glColor(disabledColor)
							drawGroundCircle(cmd.params[1], cmd.params[3], radius)
						end
					end
				end
				break
			end
		end
	end
	-- Keep clean for everyone after us
	gl.Clear(GL.STENCIL_BUFFER_BIT, 0)
end


local function HighlightPylons()
	if lastDrawnFrame < lastFrame then
		lastDrawnFrame = lastFrame
		if options.mergeCircles.value then
			gl.DeleteList(disabledDrawList or 0)
			disabledDrawList = gl.CreateList(makePylonListVolume, false, true)
			gl.DeleteList(drawList or 0)
			drawList = gl.CreateList(makePylonListVolume, true, false)
		else
			gl.DeleteList(drawList or 0)
			drawList = gl.CreateList(makePylonListVolume)
		end
	end
	gl.CallList(drawList)
	if options.mergeCircles.value then
		gl.CallList(disabledDrawList)
	end
end

local function HighlightPlacement(unitDefID)
	if not (unitDefID and UnitDefs[unitDefID]) then
		return
	end
	local mx, my = spGetMouseState()
	local _, coords = spTraceScreenRay(mx, my, true, true, false, not UnitDefs[unitDefID].floatOnWater)
	if coords then
		local radius = pylonDefs[unitDefID]
		if (radius ~= 0) then
			local x, _, z = spPos2BuildPos( unitDefID, coords[1], 0, coords[3], spGetBuildFacing())
			glColor(placementColor)
			gl.Utilities.DrawGroundCircle(x,z, radius)
		end
	end
end

function widget:SelectionChanged(selectedUnits)
	-- force regenerating the lists if we've selected a different unit
	lastDrawnFrame = 0
end


function widget:DrawWorldPreUnit()
	if Spring.IsGUIHidden() then return end

	local _, cmdID = spGetActiveCommand()  -- show pylons if pylon is about to be placed
	if cmdID ~= prevCmdID then
		-- force regenerating the lists if just picked a building to place
		lastDrawnFrame = 0
		prevCmdID = cmdID
	end
	if (cmdID) then
		if pylonDefs[-cmdID] then
			if lastDrawnFrame ~= 0 then
				local selUnits = spGetSelectedUnits()
				local commandsCount = 0
				for i=1,#selUnits do
					local unitID = selUnits[i]
					local unitDefID = spGetUnitDefID(unitID)
					if UnitDefs[unitDefID].isBuilder then
						commandsCount = Spring.GetCommandQueue(unitID, 0)
						break
					end
				end
				if commandsCount ~= lastCommandsCount then
					-- force regenerating the lists if a building was placed/removed
					lastCommandsCount = commandsCount
					lastDrawnFrame = 0
				end
			end
			highlightQueue = options.drawQueued.value
			HighlightPylons()
			highlightQueue = false
			HighlightPlacement(-cmdID)
			glColor(1,1,1,1)
			return
		end
	end

	local selUnits = spGetSelectedUnits() -- or show it if its selected
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
