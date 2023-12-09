--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local versionNumber = "v1.0"

function widget:GetInfo()
	return {
		name      = "Lobster units highlighter v2",
		desc      = versionNumber .. " Highlights units that will be lobbed by a lobster's dgun command.",
		author    = "dyth68",
		date      = "25 November 2023",
		license   = "PD",
		layer     = 1,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--config
--------------------------------------------------------------------------------
-- TODO: Make this configurable
local unitJumpStatusLineWidth = 4

-- TODO: Make colors configurable
local LIGHTRED = {1, 0.35, 0.35, 0.4}
local ORANGE = {0.9, 0.65, 0.35, 0.4}
local GREEN = {0.35, 1, 0.35, 0.4}
local YELLOW = {1, 1, 0.35, 0.4}
-- TODO: draw circles above the icons when in icon mode

local LOB_WEAPON_NUM = 1

options_path = "Settings/Interface/Falling Units/Lobster"
options_order = {"drawEffectCircle", "checkReloadTime", "checkRange", "drawFor", "edgeRange", "useHightlight"}
options = {
	drawEffectCircle = {
		name = "Show effect circle",
		type = "bool",
		value = true,
		desc = "Draws a circle around Lobsters showing their effect range.",
	},
	checkReloadTime = {
		name = "Check Reload Time",
		type = "bool",
		value = true,
		desc = "Do not draw highlight for Lobsters that are reloading.",
	},
	checkRange = {
		name = "Check Range",
		type = "bool",
		value = true,
		desc = "Do not draw highlight for Lobsters that out of range of the cursor.",
	},
	drawFor = {
		name = 'Draw highlight for',
		type = 'radioButton',
		value = 'nearby',
		items = {
			{key = 'both', name='Selected or nearby'},
			{key = 'selected', name='Selected units'},
			{key = 'nearby', name='Nearby units'},
			{key = 'none', name='No highlight on units'},
		},
	},
	edgeRange = {
		name = "Nearby detection range",
		type = "number",
		value = 50,
		min = 0,
		max = 200,
		step = 5,
	},
	useHightlight = {
		name = "Default visualisation",
		type = "bool",
		value = true,
		desc = "Highlight units which will be lobbed. When disabled, circles are drawn below units that show more information.",
	},
}

--------------------------------------------------------------------------------
--vars
--------------------------------------------------------------------------------
local lobstersSelected = {}
local fullSelection = {}
local anyLobstersSelected = false

local highlightedUnits = false

--------------------------------------------------------------------------------
--speedups
--------------------------------------------------------------------------------
local GetActiveCommand       = Spring.GetActiveCommand
local GetUnitPosition        = Spring.GetUnitPosition
local spGetUnitsInCylinder   = Spring.GetUnitsInCylinder
local GetMouseState          = Spring.GetMouseState
local TraceScreenRay         = Spring.TraceScreenRay

local spGetUnitDefID         = Spring.GetUnitDefID

local CMD_MANUALFIRE         = CMD.MANUALFIRE

local glColor                = gl.Color
local glLineWidth            = gl.LineWidth
local glDrawGroundCircle     = gl.DrawGroundCircle


-- TODO: don't hard code lobster and first weapon
local lobsterDefID           = UnitDefNames.amphlaunch.id
local lobsterGatherRange     = UnitDefs[lobsterDefID].customParams.thrower_gather
local lobsterFireRange       = WeaponDefs[UnitDefs[lobsterDefID].weapons[1].weaponDef].range

--------------------------------------------------------------------------------
--math
--------------------------------------------------------------------------------
-- taken from unit_jugglenaut_juggle.lua
local function DistanceSq(x1,y1,z1,x2,y2,z2)
  return (x1-x2)^2 + (y1-y2)^2 + (z1-z2)^2
end

--------------------------------------------------------------------------------
--lobster finding
--------------------------------------------------------------------------------

local function UpdateSelection(sel)
	anyLobstersSelected = false
	lobstersSelected = {}
	for i = 1, #sel do
		local unitID = sel[i]
		local unitDefID = spGetUnitDefID(unitID)
		if unitDefID then
			if unitDefID == lobsterDefID then
				anyLobstersSelected = true
				lobstersSelected[#lobstersSelected + 1] = unitID
			end
		end
	end
	
end

--------------------------------------------------------------------------------
--mouse management
--------------------------------------------------------------------------------

-- Taken from gui_attack_aoe.lua
local function GetMouseTargetPosition()
	local mx, my = GetMouseState()
	local mouseTargetType, mouseTarget = TraceScreenRay(mx, my, false, true, false, true)

	if (mouseTargetType == "ground") then
		return mouseTarget[1], mouseTarget[2], mouseTarget[3], true
	elseif (mouseTargetType == "unit") then
		return GetUnitPosition(mouseTarget)
	elseif (mouseTargetType == "feature") then
		local _, coords = TraceScreenRay(mx, my, true, true, false, true)
		if coords and coords[3] then
			return coords[1], coords[2], coords[3], true
		else
			return GetFeaturePosition(mouseTarget)
		end
	else
		return nil
	end
end

--------------------------------------------------------------------------------
--Drawing
--------------------------------------------------------------------------------

local function DrawStatusCircle(color, x, y, z)
	glColor(color)
	glLineWidth(unitJumpStatusLineWidth)
	glDrawGroundCircle(x, y, z, 15, 20)
	glColor(1,1,1,1)
end

local function GetUnitLobsterStatus(onlyCircle, drawCircles)
	local mx, my, mz = GetMouseTargetPosition()

	local unitsInLobsterRange = {}
	local unitsInActiveLobsterRange = {}
	local foundUnitList = {}
	local foundUnitMap = {}
	-- Draw lobster circles and figure out what units will be thrown
	for i = 1, #lobstersSelected do
		local unitID = lobstersSelected[i]
		local x,y,z, fx, fy, fz = GetUnitPosition(unitID, true)
		if not foundUnitMap[unitID] then
			foundUnitList[#foundUnitList + 1] = unitID
			foundUnitMap[unitID] = true
		end
		
		-- The "mx and" is to avoid crashes when the mouse is beyond the screen
		local activeLobster = true
		if options.checkRange.value then
			activeLobster = mx and (DistanceSq(x,y,z, mx, my, mz) <= lobsterFireRange*lobsterFireRange)
		end
		if options.checkReloadTime.value and activeLobster then
			local _, loaded = Spring.GetUnitWeaponState(unitID, LOB_WEAPON_NUM)
			activeLobster = activeLobster and loaded
		end
		
		if not onlyCircle then
			local unitsAffectedByThis = spGetUnitsInCylinder(fx, fz, lobsterGatherRange)
			for i = 1, #unitsAffectedByThis do
				local unitAffectedID = unitsAffectedByThis[i]
				if unitID ~= unitAffectedID then
					unitsInLobsterRange[unitAffectedID] = true
					if activeLobster then
						unitsInActiveLobsterRange[unitAffectedID] = true
					end
					if not foundUnitMap[unitAffectedID] then
						foundUnitList[#foundUnitList + 1] = unitAffectedID
						foundUnitMap[unitAffectedID] = true
					end
				end
			end

			if options.drawFor.value ~= "selected" and not options.useHightlight.value then
				local unitsAlmostAffectedByThis = spGetUnitsInCylinder(fx, fz, lobsterGatherRange + options.edgeRange.value)
				for i = 1, #unitsAlmostAffectedByThis do
					local unitAffectedID = unitsAlmostAffectedByThis[i]
					if not foundUnitMap[unitAffectedID] then
						foundUnitList[#foundUnitList + 1] = unitAffectedID
						foundUnitMap[unitAffectedID] = true
					end
				end
			end
		end

		if drawCircles then
			-- Draw the lobster gather circle
			if activeLobster then
				glColor(YELLOW)
			else
				glColor(ORANGE)
			end
			glLineWidth(2)
			glDrawGroundCircle(fx, fy, fz, lobsterGatherRange, 50)
			glColor(1,1,1,1)
		end
	end
	
	if onlyCircle then
		return
	end
	
	if options.drawFor.value ~= "nearby" then
		if fullSelection then
			for i = 1, #fullSelection do
				local unitAffectedID = fullSelection[i]
				if not foundUnitMap[unitAffectedID] then
					foundUnitList[#foundUnitList + 1] = unitAffectedID
					foundUnitMap[unitAffectedID] = true
				end
			end
		end
	end
	
	return unitsInLobsterRange, unitsInActiveLobsterRange, foundUnitList, foundUnitMap
end

local function DrawLobsterLobProperties()
	local onlyCircle = options.useHightlight.value or (options.drawFor.value == "none")
	local unitsInLobsterRange, unitsInActiveLobsterRange, foundUnitList, foundUnitMap = GetUnitLobsterStatus(onlyCircle, options.drawEffectCircle.value)
	if onlyCircle then
		return
	end
	
	for i = 1, #foundUnitList do
		local unitID = foundUnitList[i]
		local fx, fy, fz = Spring.GetUnitViewPosition(unitID)
		if fx then
			if unitsInActiveLobsterRange[unitID] then
				DrawStatusCircle(GREEN, fx, fy, fz)
			elseif unitsInLobsterRange[unitID] then
				DrawStatusCircle(ORANGE, fx, fy, fz)
			else
				DrawStatusCircle(LIGHTRED, fx, fy, fz)
			end
		end
	end
end

--------------------------------------------------------------------------------
--Highlight
--------------------------------------------------------------------------------

local function RemoveAllHighlights()
	if not highlightedUnits then
		return
	end
	for _, highlightID in pairs(highlightedUnits) do
		WG.StopHighlightUnitGL4(highlightID)
	end
	highlightedUnits = false
end

local function UpdateHighlight()
	highlightedUnits = highlightedUnits or {}
	local unitsInLobsterRange, unitsInActiveLobsterRange, foundUnitList, foundUnitMap = GetUnitLobsterStatus()

	local found = {}
	for i = 1, #foundUnitList do
		local unitID = foundUnitList[i]
		local fx, fy, fz = Spring.GetUnitViewPosition(unitID)
		if fx then
			if unitsInActiveLobsterRange[unitID] then
				found[unitID] = true
				if not highlightedUnits[unitID] then
					highlightedUnits[unitID] = WG.HighlightUnitGL4(unitID, 'unitID', 0.3, 0.3, 0, 0.75, 0.2, 0.15, 0.2, 0, 0, 0)
				end
			end
		end
	end

	for unitID, highlightID in pairs(highlightedUnits) do
		if not found[unitID] then
			WG.StopHighlightUnitGL4(highlightID)
			highlightedUnits[unitID] = nil
		end
	end
end

--------------------------------------------------------------------------------
--call-ins
--------------------------------------------------------------------------------

function widget:Update()
	local _, cmd, _ = GetActiveCommand()
	if not (anyLobstersSelected and cmd == CMD_MANUALFIRE and options.useHightlight.value) or (options.drawFor.value == "none") then
		if highlightedUnits then
			RemoveAllHighlights()
		end
		return
	end
	UpdateHighlight()
end

function widget:DrawWorld()
	if not(not options.useHightlight.value or options.drawEffectCircle.value) then
		return
	end
	local _, cmd, _ = GetActiveCommand()
	if anyLobstersSelected and cmd == CMD_MANUALFIRE then
		-- Doing lots of logic in the draw step, but it's quite performant 
		DrawLobsterLobProperties()
	end
end

function widget:SelectionChanged(sel)
	UpdateSelection(sel)
	fullSelection = sel
end