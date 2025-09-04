function widget:GetInfo()
  return {
    name      = "Showeco and Grid Drawer",
    desc      = "Register an action called Showeco & draw overdrive overlay.", --"acts like F4",
    author    = "xponen, ashdnazg, Shaman",
    date      = "July 19 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0, --only layer > -4 works because it seems to be blocked by something.
    enabled   = true,  --  loaded by default?
    handler   = true,
  }
end

local pylon = {}

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
local spIsSphereInView     = Spring.IsSphereInView
local spGetGroundHeight    = Spring.GetGroundHeight

local glVertex        = gl.Vertex
local glCallList      = gl.CallList
local glColor         = gl.Color
local glCreateList    = gl.CreateList
local glDepthMask     = gl.DepthMask
local glDepthTest     = gl.DepthTest
local glTexture       = gl.Texture
local glClear         = gl.Clear
local glDeleteList    = gl.DeleteList
local glUnitShape     = gl.UnitShape
local glRotate        = gl.Rotate
local glTranslate     = gl.Translate
local glPushMatrix    = gl.PushMatrix
local glPopMatrix     = gl.PopMatrix
local tableInsert     = table.insert

--// gl const

local pylons = {count = 0, data = {}} -- Isn't this just an iterable map?
local pylonByID = {}
local currentSelection = false
local playerIsPlacingPylon = false
local playerAllyTeam
local worldClickStartPositionX, worldClickStartPositionZ = -1, -1
local leftLowerBound = math.rad(45)
local leftUpperBound = math.rad(135)
local rightUpperBound = math.rad(225)
local rightUpperBound = math.rad(315)

local pylonDefs = {}
local isBuilder = {}
local floatOnWater = {}
local fpTable = {} -- stores building FootPrints. UnitDefID = {x = num, z = num}

local allPylons = {length = 0, data = {}} -- [1] = {x, z, radius}

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local queuedPylons = IterableMap.New() -- {unitID = {[1] = {x, z, def} . . .}
local needsUpdate = IterableMap.New() -- list of unitIDs that need updating.

for i=1,#UnitDefs do
	local udef = UnitDefs[i]
	local range = tonumber(udef.customParams.pylonrange)
	if (range and range > 0) then
		pylonDefs[i] = range
		fpTable[i] = {x = UnitDefs[i].xsize, z = UnitDefs[i].zsize} -- FootPrint units are 16 elmos. See: https://springrts.com/wiki/Gamedev:UnitsOfMeasurement#Linear
	end
	if udef.isBuilder then
		isBuilder[i] = true
	end
	if udef.floatOnWater then
		floatOnWater[i] = true
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Utilities

local drawList = 0
local disabledDrawList = 0
local drawQueueList = 0
local drawAllQueuedList = 0
local lastDrawnFrame = 0
local lastFrame = 2
local highlightQueue = false
local alwaysHighlight = false
local playerHasBuilderSelected = false
local currentCommand = 0
local playerTeamID = 0

local function ForceRedraw()
	lastDrawnFrame = 0
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Menu Options

local drawAlpha = 0.2
WG.showeco_always_mexes = true -- No OnChange when not changed from the default.

local drawGroundCircle
local showAllies = false

options_path = 'Settings/Interface/Economy Overlay'
options_order = {'start_with_showeco', 'always_show_mexes', 'mergeCircles', 'drawQueued', 'show_allies'}


local queuedColor = { 0.9,0.8,0.75, drawAlpha}
local disabledColor = { 0.9,0.8,0.75, drawAlpha}
local placementColor = { 0.6, 0.7, 0.5, drawAlpha} -- drawAlpha on purpose!

local GetGridColor = VFS.Include("LuaUI/Headers/overdrive.lua")

local function QueueList()
	if currentSelection then
		glColor(disabledColor)
		for i = 1, #currentSelection do
			local unitID = currentSelection[i]
			local data = IterableMap.Get(queuedPylons, unitID)
			if data then
				for i = 1, #data do
					local radius = data[i].range
					drawGroundCircle(data[i].x, data[i].z, radius)
				end
			end
		end
	end
	glColor(1,1,1,1)
	glClear(GL.STENCIL_BUFFER_BIT, 0)
end

local function UpdateQueueList()
	if alwaysHighlight then return end
	glDeleteList(drawQueueList or 0)
	drawQueueList = glCreateList(QueueList)
end

local function AddEntryToList(x, z, def, range, team, facing) -- prevent repeats!
	if allPylons.length > 0 then
		for i = 1, allPylons.length do
			local entry = allPylons.data[i]
			if entry.x == x and entry.z == z and entry.def == def then
				return
			end
		end
	end
	allPylons.length = allPylons.length + 1
	if allPylons.data[allPylons.length] then
		local entry = allPylons.data[allPylons.length]
		entry.x = x
		entry.y = spGetGroundHeight(x, z)
		entry.z = z
		entry.def = def
		entry.range = range
		entry.team = team
	else
		allPylons.data[allPylons.length] = {x = x, y = spGetGroundHeight(x, z), z = z, range = range, def = def, team = team, facing = facing}
	end
end

local function UpdateQueuedList()
	allPylons.length = 0 -- reset the list.
	for unitID, data in IterableMap.Iterator(queuedPylons) do
		if showAllies or Spring.GetUnitTeam(unitID) == playerTeamID then
			
			--Spring.Echo("Make list volume: " .. unitID .. "data: " .. tostring(data))
			for i = 1, #data do
				--              x, z, def, range, team, facing
				AddEntryToList(data[i].x, data[i].z, data[i].def, data[i].range, Spring.GetUnitTeam(unitID), data[i].facing)
				--Spring.Echo(i .. ":" .. tostring(data[i].x) .. ", " .. tostring(data[i].z) .. ", " .. tostring(data[i].range) .. ", " .. tostring(data[i].team))
				--drawGroundCircle(data[i].x, data[i].z, data[i].range)
			end
		end
	end
end

local function AllQueue()
	glColor(queuedColor)
	for i = 1, allPylons.length do
		local entry = allPylons.data[i]
		drawGroundCircle(entry.x, entry.z, entry.range)
	end
	glColor(1, 1, 1, 1)
	glClear(GL.STENCIL_BUFFER_BIT, 0)
end

local function UpdateAllQueuesList()
	glDeleteList(drawAllQueuedList or 0)
	UpdateQueuedList()
	drawAllQueuedList = glCreateList(AllQueue)
	UpdateQueueList()
end

options = {
	start_with_showeco = {
		name = "Start with economy overlay",
		desc = "Game starts with Economy Overlay enabled",
		type = 'bool',
		value = true,
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
		OnChange = function(self)
			drawGroundCircle = self.value and gl.Utilities.DrawMergedGroundCircle or gl.Utilities.DrawGroundCircle
			lastDrawnFrame = 0
		end,
	},
	drawQueued = {
		name = "Always Draw Queued Grid",
		desc = "When enabled, always draw grid in queue, otherwise, only draw it when placing new grid units down.",
		type = 'bool',
		value = false,
		OnChange = function(self) 
			alwaysHighlight = self.value 
		end,
	},
	show_allies = {
		name = "Draw allied queued grid",
		desc = "Shows the queued grid of allied queued units.",
		type = 'bool',
		value = true,
		OnChange = function(self)
			showAllies = self.value
			UpdateAllQueuesList()
		end,
	},
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Unit Handling

local function RemoveFromOrderedTable(tab, num)
	tab.taglookup[tab[num]] = nil
	local table_length = #tab
	if num == table_length then
		tab[num] = nil
	else
		local entry = tab[#tab]
		tab.taglookup[entry.tag] = num
		tab[num] = entry
		tab[table_length] = nil
	end
end

local function ShiftFromTable(tab, num)
	if tab[num] == nil then
		Spring.Echo("[Ecoview] Attempted to index a nonexistent queue num (shift from tab). Index: " .. tostring(num))
		return
	end
	local table_length = #tab
	tab.taglookup[tab[num].tag] = nil
	if table_length == num then
		tab[num] = nil
	else
		for i = num + 1, table_length do -- shift out.
			tab.taglookup[tab[i].tag] = i - 1
			tab[i - 1] = tab[i]
		end
		tab[table_length] = nil
	end
end


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

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if not Spring.AreTeamsAllied(unitTeam, playerTeamID) then
		return
	end
	addUnit(unitID, unitDefID, unitTeam)
	local data = IterableMap.Get(queuedPylons, builderID)
	if data and data[1] and data[1].def == unitDefID then -- we're starting construction on the current cmd.
		ShiftFromTable(data, 1)
		UpdateAllQueuesList()
	end
	if isBuilder[unitDefID] then
		IterableMap.Add(queuedPylons, unitID, {taglookup = {}, clearedRecently = false})
	end
end

function widget:RenderUnitDestroyed(unitID, unitDefID, unitTeam)
	if pylonByID[unitID] then
		removeUnit(unitID, unitDefID, unitTeam)
	end
	if isBuilder[unitDefID] then
		IterableMap.Remove(queuedPylons, unitID)
		IterableMap.Remove(needsUpdate, unitID)
		UpdateAllQueuesList()
	end
end

function widget:UnitIdle(unitID, unitDefID, unitTeam)
	if isBuilder[unitDefID] then
		widget:UnitCommand(unitID, unitDefID, unitTeam, CMD.STOP)
	end
end

--[[function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if not Spring.AreTeamsAllied(unitTeam, playerTeamID) then
		return
	end
	if isBuilder[unitDefID] then
		IterableMap.Add(queuedPylons, unitID, {taglookup = {}, clearedRecently = false})
	end
end]]

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	addUnit(unitID, unitDefID, unitTeam)
	if IterableMap.InMap(queuedPylons, unitID) then
		UpdateAllQueuesList()
	end
end

function widget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	if pylonByID[unitID] then
		removeUnit(unitID, unitDefID, unitTeam)
	end
end

function widget:UnitUnloaded(unitID, unitDefID, unitTeam)
	addUnit(unitID, unitDefID, unitTeam)
end

local function BuildTableFromCommand(cmd, cmdParams, indexShift, buildDef, cmdTag)
	local x      = cmdParams[1 + indexShift]
	local y      = cmdParams[2 + indexShift]
	local z      = cmdParams[3 + indexShift]
	local facing = cmdParams[4 + indexShift] or 1
	local range  = pylonDefs[buildDef]
	if x and y and z and range and buildDef then
		return {x = x, y = y, z = z, range = range, def = buildDef, facing = facing, tag = cmdTag}
	elseif x and y and z then
		Spring.Echo("Missing range and buildDef!")
		return
	else
		Spring.Echo("[EcoView]: CMD ID: " .. cmd .. " Missing values:\nx = " .. tostring(x) .. "\ny: " .. tostring(y) .. "\nz: " .. tostring(z) .. "\nrange: " .. tostring(range) .. "\nfacing: " .. tostring(facing))
		return
	end
end

--function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	--Spring.Echo("CommandNotify: " .. cmdID)
--end

local function ClearData(data)
	if data == nil then return end
	data.taglookup = {}
	data.clearedRecently = false
	for i = 1, #data do
		data[i] = nil
	end
end

local function DoUpdate()
	local updates = 0
	for unitID, _ in IterableMap.Iterator(needsUpdate) do
		local queue = Spring.GetUnitCommands(unitID, -1)
		local index = 1
		local data = IterableMap.Get(queuedPylons, unitID)
		if not data then -- missing data.
			IterableMap.Remove(needsUpdate, unitID)
		else
			if queue and #queue > 0 then
				updates = updates + 1
				IterableMap.Remove(needsUpdate, unitID)
				ClearData(data)
				local cmd
				for i = 1, #queue do
					cmd = queue[i]
					--Spring.Echo("DoUpdate: " .. Spring.Utilities.CommandNameByID(cmd.id))
					if cmd.id < 0 then -- this is a unit construction order
						local unitDef = -cmd.id
						if pylonDefs[unitDef] then
							local d = BuildTableFromCommand(cmd.id, cmd.params, 0, unitDef, cmd.tag)
							if d then
								data[index] = d
								data.taglookup[cmd.tag] = index
								index = index + 1
							else
								Spring.Echo("[Ecoview] Table failed to build")
							end
						end
					end
				end
			elseif queue and #queue == 0 then
				ClearData(data)
			end
		end
	end
	if updates > 0 then
		UpdateAllQueuesList()
	end
end


function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag, playerID, fromSynced, fromLua)
	--Spring.Echo("UnitCommand: " .. cmdID .. "(" .. Spring.Utilities.CommandNameByID(cmdID) .. ")")
	--Spring.Echo(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag, playerID, fromSynced, fromLua)
	--for k, v in pairs(cmdParams) do
		--Spring.Echo(k .. ": " .. tostring(v))
	--end
	if isBuilder[unitDefID] and Spring.AreTeamsAllied(unitTeam, playerTeamID) then
		local queueAltered = false
		local data = IterableMap.Get(queuedPylons, unitID)
		if data == nil then -- for some reason we don't have this builder on record!
			data = {taglookup = {}, clearedRecently = false}
			IterableMap.Set(queuedPylons, unitID, data) -- should be fine?
		end
		if cmdID == CMD.REMOVE and cmdParams[1] then
			if data and data.taglookup[cmdParams[1]] then
				ShiftFromTable(data, data.taglookup[cmdParams[1]])
				UpdateAllQueuesList()
			end
		elseif cmdID == CMD.STOP and #data > 0 then
			ClearData(data)
			--Spring.Echo("[Ecoview] Queue cleared. (CMD.STOP)")
			queueAltered = true
		elseif cmdID < 0 then
			if not (cmdOpts.shift or cmdOpts.meta) and #data > 0 then
				ClearData(data)
				--Spring.Echo("[Ecoview] Queue cleared. (build order without shift)")
				queueAltered = true
			end
			local buildDef = -cmdID -- turn it positive. build orders are negative.
			if pylonDefs[buildDef] then
				--if queue == nil or #queue == 0 then
				--Spring.Echo("Needs to update!")
				IterableMap.Add(needsUpdate, unitID, true)
				return 
				--[[end
				cmdTag = queue[#queue].tag
				local d = BuildTableFromCommand(cmdID, cmdParams, 0, buildDef, cmdTag)
				if d then
					data[#data + 1] = d
					data.taglookup[cmdTag] = #data
				end
				queueAltered = true]]
			end
		elseif cmdID >= 10 and not (cmdID == 80 or cmdID == 31110 or fromLua) then
			if (not (cmdOpts.shift or cmdOpts.meta) or cmdID == CMD.STOP) and #data > 0 then
				ClearData(data)
				IterableMap.Add(needsUpdate, unitID, true)
				queueAltered = true
			end
		elseif cmdID == CMD.INSERT and cmdParams[2] and cmdParams[2] < 0 then
			local buildDef = -cmdParams[2]
			if pylonDefs[buildDef] then
				--local position = cmdParams[1] + 1 -- zero indexed.
				--local queue = Spring.GetUnitCommands(unitID, position)
				--if queue == nil or #queue < position then
					IterableMap.Add(needsUpdate, unitID, true)
					return
				--end
				--cmdTag = queue[position]
				--local d = BuildTableFromCommand(cmdID, cmdParams, 3, buildDef, cmdTag) -- CMD Insert: position, cmdID, cmdOptions, cmdParams[1] . . .
				--if d then
					--tableInsert(data, position, d)
				--end
				--queueAltered = true
			end
			--Spring.Echo("[Ecoview] Added new " .. buildDef .. " for " .. unitID .. ", Team: " .. tostring(unitTeam))
			--Spring.MarkerAddPoint(cmdParams[4], cmdParams[5], cmdParams[6], buildDef, true)
		end
		if queueAltered then
			UpdateAllQueuesList()
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Drawing

local function AllyTeamChanged()
	pylons = {count = 0, data = {}}
	pylonByID = {}
	for unitID, _ in IterableMap.Iterator(queuedPylons) do
		IterableMap.Remove(queuedPylons, unitID)
	end
	playerAllyTeam = Spring.GetMyAllyTeamID()
	playerTeamID = Spring.GetMyTeamID()
	local teamList = Spring.GetTeamList(playerAllyTeam)
	for i = 1, #teamList do
		local units = Spring.GetTeamUnits(teamList[i])
		for j = 1, #units do
			local unitID = units[j]
			local unitDefID = spGetUnitDefID(unitID)
			local unitTeam = Spring.GetUnitTeam(unitID)
			widget:UnitCreated(unitID, unitDefID, unitTeam)
			local commandQueue = Spring.GetUnitCommands(unitID, -1)
			if commandQueue and #commandQueue > 0 then
				local ux, _, uz = Spring.GetUnitPosition(unitID)
				for j = 1, #commandQueue do
					local cmd = commandQueue[j]
					if j == 1 and cmd.id < -1 then
						local currentBuilding = Spring.GetUnitIsBuilding(unitID)
						if currentBuilding and Spring.GetUnitDefID(currentBuilding) ~= -cmd.id then
							--Spring.Echo("Adding ID")
							widget:UnitCommand(unitID, unitDefID, unitTeam, commandQueue[j].id, commandQueue[j].params, commandQueue[j].options, commandQueue[j].tag)
						end
					end
					if cmd.id < 0 then
						--Spring.Echo("Processing command for " .. unitID)
						widget:UnitCommand(unitID, unitDefID, unitTeam, commandQueue[j].id, commandQueue[j].params, commandQueue[j].options, commandQueue[j].tag)
					end
				end
			end
		end
	end
	UpdateAllQueuesList()
end

function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag)
	if isBuilder[unitDefID] and cmdID < 0 then
		IterableMap.Add(needsUpdate, unitID, true)
	end
end

function widget:Initialize()
	drawGroundCircle = options.mergeCircles.value and gl.Utilities.DrawMergedGroundCircle or gl.Utilities.DrawGroundCircle
	playerAllyTeam = Spring.GetMyAllyTeamID()
	playerTeamID = Spring.GetMyTeamID()
	showAllies = options.show_allies.value -- must be before AllyTeamChanged otherwise will need to be invalidated!
	WG.showeco = options.start_with_showeco.value
	AllyTeamChanged()
	highlightQueue = false
	alwaysHighlight = options.drawQueued.value
	widget:SelectionChanged(Spring.GetSelectedUnits())
	--highlightQueue = options.drawQueued.value
end

function widget:PlayerChanged(playerID)
	if playerID == Spring.GetMyPlayerID() and Spring.GetMyAllyTeamID() ~= playerAllyTeam then
		AllyTeamChanged()
	end
end

function widget:Shutdown()
	glDeleteList(drawList or 0)
	glDeleteList(disabledDrawList or 0)
	glDeleteList(drawQueueList or 0)
	glDeleteList(drawAllQueuedList or 0)
end

function widget:GameFrame(f)
	if f%32 == 2 then
		lastFrame = f
		for unitID, data in IterableMap.Iterator(queuedPylons) do
			local currentBuilding = Spring.GetUnitIsBuilding(unitID)
			if data[1] and data[1].def == currentBuilding then
				ShiftFromTable(data, 1)
				data.clearedRecently = true
				UpdateAllQueuesList()
			end
		end
	end
end


local function makePylonListVolume(onlyActive, onlyDisabled)
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
	-- Keep clean for everyone after us
	glClear(GL.STENCIL_BUFFER_BIT, 0)
end


local function HighlightPylons()
	if lastDrawnFrame < lastFrame then
		lastDrawnFrame = lastFrame
		if options.mergeCircles.value then
			glDeleteList(disabledDrawList or 0)
			disabledDrawList = glCreateList(makePylonListVolume, false, true)
			glDeleteList(drawList or 0)
			drawList = glCreateList(makePylonListVolume, true, false)
		else
			glDeleteList(drawList or 0)
			drawList = glCreateList(makePylonListVolume)
		end
	end
	glCallList(drawList)
	if options.mergeCircles.value then
		glCallList(disabledDrawList)
	end
end

local function HighlightPlacement(unitDefID)
	if not unitDefID then
		return
	end
	local mx, my = spGetMouseState()
	local _, coords = spTraceScreenRay(mx, my, true, true, false, not floatOnWater[unitDefID])
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
	currentSelection = selectedUnits
	playerHasBuilderSelected = false
	if #currentSelection > 0 then
		for i = 1, #currentSelection do
			if isBuilder[Spring.GetUnitDefID(currentSelection[i])] then
				playerHasBuilderSelected = true
				break
			end
		end
	end
	UpdateQueueList()
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() or not (playerIsPlacingPylon or alwaysHighlight) then return end
	glDepthMask(true)
	glDepthTest(GL.LEQUAL)
	glColor(1.0, 1.0, 1.0, 0.20)
	for i = 1, allPylons.length do
		local entry = allPylons.data[i]
		local x, y, z = entry.x, entry.y, entry.z
		if spIsSphereInView(x, y, z, 30) then
			local facing = entry.facing or 1
			glPushMatrix()
				gl.LoadIdentity()
				glTranslate(x, spGetGroundHeight(x, z), z)
				glRotate(90 * facing, 0, 1, 0)
				glTexture("%"..entry.def..":0") 
				glUnitShape(entry.def, entry.team, false, false, false) -- gl.UnitShape(bDefID, teamID, false, false, false)
			glPopMatrix()
		end
	end
	glColor(1,1,1,1)
	glDepthTest(false)
	glDepthMask(false)
	glTexture(false) 
end

function widget:Update(dt)
	DoUpdate()
	if playerHasBuilderSelected or alwaysHighlight then
		local _, newCommand = spGetActiveCommand()  -- show pylons if pylon is about to be placed
		if newCommand ~= currentCommand then
			currentCommand = newCommand
			if newCommand and pylonDefs[-newCommand] then
				ForceRedraw()
			end
		end
		if currentCommand and pylonDefs[-currentCommand] then
			playerIsPlacingPylon = true
		else
			playerIsPlacingPylon = false
		end
	end
end


function widget:KeyPress(key, mods)
	--Spring.Echo("KeyPress: " .. tostring(mods.shift))
	if mods.shift and playerHasBuilderSelected then
		highlightQueue = true
	end
end

function widget:KeyRelease(key)
	highlightQueue = false
end

function widget:DrawWorldPreUnit()
	local showecoMode = WG.showeco
	if Spring.IsGUIHidden() or (not showecoMode and not playerIsPlacingPylon) then return end
	if highlightQueue and not (playerIsPlacingPylon or alwaysHighlight) then
		glCallList(drawQueueList)
	elseif playerIsPlacingPylon or alwaysHighlight then
		glCallList(drawAllQueuedList)
		if currentCommand and pylonDefs[-currentCommand] then
			HighlightPlacement(-currentCommand)
		end
	end
	if showecoMode or playerIsPlacingPylon then
		HighlightPylons()
		glColor(1,1,1,1)
		return
	end
end
