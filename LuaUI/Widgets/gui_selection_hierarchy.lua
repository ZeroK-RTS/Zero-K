--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Selection Hierarchy",
    desc      = "Implements selection heirarchy state.",
    author    = "GoogleFrog",
    date      = "13 April 2017",
    license   = "GNU GPL, v2 or later",
    layer     = -math.huge,
    enabled   = true, --  loaded by default?
    handler   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")
include("keysym.lua")

local spDiffTimers = Spring.DiffTimers
local spGetTimer = Spring.GetTimer

local selectionRankCmdDesc = {
	id      = CMD_SELECTION_RANK,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Selection Rank',
	action  = 'selection_rank',
	tooltip = 'Selection filtering rank: only unts of the highest rank are selected. Hold Shift to ignore filtering.',
	params  = {0, 'Lowest', 'Low', 'Medium', 'High'}
}

local doubleClickToleranceTime = (Spring.GetConfigInt('DoubleClickTime', 300) * 0.001) * 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local selectionRank = {}
local defaultRank = {}

local defaultRank, morphRankTransfer = VFS.Include(LUAUI_DIRNAME .. "Configs/selection_rank.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Epic Menu Options

local ctrlFlattenRank = 1
local altFilterHighRank = 2
local doubleClickFlattenRank = 1
local controlGroupFlattenRank = 1
local retreatOverride = true
local retreatingRank = 0
local useSelectionFiltering = true
local selectionFilteringOnlyAlt = false
local retreatDeselects = false

local function StartRetreat(unitID)
	if not Spring.GetSpectatingState() then -- FIXME: ideally would be `Spring.IsUnitControllable(unitID)`, see engine #1242
		Spring.DeselectUnit(unitID)
	end
end

i18nPrefix = 'selectionhierarchy_'
options_path = 'Settings/Interface/Selection/Filtering'
local retreatPath = 'Settings/Interface/Retreat Zones'
options_order = {
	'label_selection_rank',
	'useSelectionFilteringOption',
	'ctrlFlattenRankOption',
	'selectionFilteringOnlyAltOption',
	'altBlocksHighRankSelection',
	'doubleClickFlattenRankOption',
	'controlGroupFlattenRank',
	'retreatOverrideOption',
	'retreatingRankOption',
	'retreatDeselects'
}

options = {
	label_selection_rank = {
		type = 'text',
		value = [[Units have a toggleable selection rank on the right side of their command card (the circle with numbers 0-3).
 - Normal selection only selects the boxed units with the highest rank.
 - Shift ignores rank.
 - Combat units default to rank 3.
 - Constructors default to rank 2.
 - Structures default to rank 1.
 - Rank 0 intended for manual use to make a unit hard to accidentally select.
 - Default rank can be edited in 'Settings/Unit Behaviour/Default States'.]],
	},
	useSelectionFilteringOption = {
		type = "bool",
		value = true,
		noHotkey = true,
		OnChange = function (self)
			useSelectionFiltering = self.value
		end
	},
	ctrlFlattenRankOption = {
		type = 'number',
		value = 1,
		min = 0, max = 3, step = 1,
		noHotkey = true,
		tooltip_format = "%.0f",
		OnChange = function (self)
			ctrlFlattenRank = self.value
		end
	},
	selectionFilteringOnlyAltOption = {
		type = "bool",
		value = false,
		noHotkey = true,
		OnChange = function (self)
			selectionFilteringOnlyAlt = self.value
		end
	},
	altBlocksHighRankSelection = {
		type = 'number',
		value = 2,
		min = 0, max = 3, step = 1,
		noHotkey = true,
		tooltip_format = "%.0f",
		OnChange = function (self)
			altFilterHighRank = self.value
		end
	},
	doubleClickFlattenRankOption = {
		type = 'number',
		value = 1,
		min = 0, max = 3, step = 1,
		noHotkey = true,
		tooltip_format = "%.0f",
		OnChange = function (self)
			doubleClickFlattenRank = self.value
		end
	},
	controlGroupFlattenRank = {
		type = "number",
		value = controlGroupFlattenRank,
		min = 0, max = 3, step = 1,
		noHotkey = true,
		OnChange = function (self)
			controlGroupFlattenRank = self.value
		end
	},
	retreatOverrideOption = {
		type = "bool",
		value = true,
		noHotkey = true,
		path = retreatPath,
		OnChange = function (self)
			retreatOverride = self.value
		end
	},
	retreatingRankOption = {
		type = 'number',
		value = 0, -- This should be 0 because otherwise Ctrl selection keys work on the unit.
		min = 0, max = 3, step = 1,
		tooltip_format = "%.0f",
		noHotkey = true,
		path = retreatPath,
		OnChange = function (self)
			retreatingRank = self.value
		end
	},
	retreatDeselects = {
		type = "bool",
		value = true,
		noHotkey = true,
		path = retreatPath,
		OnChange = function (self)
			if self.value and not retreatDeselects then
				widgetHandler:RegisterGlobal(widget, "StartRetreat", StartRetreat)
			elseif not self.value and retreatDeselects then
				widgetHandler:DeregisterGlobal(widget, "StartRetreat")
			end
			retreatDeselects = self.value
		end,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Selection handling

local firstClickTimer
local firstClickUnitDefID
local function GetDoubleClickUnitDefID(units)
	if firstClickTimer and (spDiffTimers(spGetTimer(), firstClickTimer) <= doubleClickToleranceTime) then
		local unitDefID = firstClickUnitDefID
		firstClickUnitDefID = nil
		return unitDefID
	end
	
	if units and units[1] and #units == 1 then
		local unitDefID = Spring.GetUnitDefID(units[1])
		if unitDefID then
			firstClickTimer = spGetTimer()
			firstClickUnitDefID = unitDefID
		end
	else
		firstClickTimer = false
		firstClickUnitDefID = false
	end
end

local function GetIsSubselection(newSelection, oldSelection)
	if #newSelection > #oldSelection then
		return false
	else
		local newSeen = 0
		local oldSelectionMap = {}
		for i = 1, #oldSelection do
			oldSelectionMap[oldSelection[i]] = true
		end
		for i = 1, #newSelection do
			if not oldSelectionMap[newSelection[i]] then
				return false
			end
		end
	end
	return true
end

-- returns true if any control group hotkeys are being pressed
local function CheckControlGroupHotkeys(num)
	local keys = WG.GetControlGroupHotkeys()
	for keysym, group in pairs(keys) do
		if (num == nil or num == group) and Spring.GetKeyState(keysym) then
			return true
		end
	end
	return false
end

local function RawGetFilteredSelection(units, subselection, subselectionCheckDone, doubleClickUnitDefID)
	if not useSelectionFiltering then
		return
	end
	if not units then
		return
	end
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	if shift then
		return
	end
	
	if selectionFilteringOnlyAlt and not alt then
		return
	end
	
	if not subselectionCheckDone then
		subselection = GetIsSubselection(units, Spring.GetSelectedUnits())
	end
	
	if subselection then
		return -- Don't filter when the change is just that something was deselected
	end
	
	if #units <= 1 and not alt then
		return
	end

	local isControlGroupSelection = CheckControlGroupHotkeys()

	if doubleClickUnitDefID then
		for i = 1, #units do
			local unitID = units[i]
			if Spring.GetUnitDefID(unitID) ~= doubleClickUnitDefID then
				doubleClickUnitDefID = false
				break
			end
		end
	end
	
	local needsChanging = false
	local bestRank, bestUnits
	for i = 1, #units do
		local unitID = units[i]
		local rank = unitID and selectionRank[unitID]
		if not rank then
			local unitDefID = Spring.GetUnitDefID(unitID)
			rank = unitDefID and defaultRank[unitDefID]
		end
		if retreatOverride and unitID and (Spring.GetUnitRulesParam(unitID, "retreat") == 1) and (rank > retreatingRank) then
			rank = retreatingRank
		end

		if WG.GlobalBuildCommand and WG.GlobalBuildCommand.IsSelectionOverrideSet and WG.GlobalBuildCommand.IsControllingUnit(unitID) and (rank > WG.GlobalBuildCommand.SelectionOverrideRank) then
			rank = WG.GlobalBuildCommand.SelectionOverrideRank
		end

		if rank then
			if (alt and rank > altFilterHighRank) then
				rank = -1
			end
			if ctrl and rank > ctrlFlattenRank then
				rank = ctrlFlattenRank
			end
			if doubleClickUnitDefID and rank > doubleClickFlattenRank then
				rank = doubleClickFlattenRank
			end
			if isControlGroupSelection and rank > controlGroupFlattenRank then
				rank = controlGroupFlattenRank
			end
			if (not bestRank) or (bestRank < rank) then
				if bestRank then
					needsChanging = true
				end
				bestRank = rank
				bestUnits = {unitID}
			elseif bestRank == rank then
				bestUnits[#bestUnits + 1] = unitID
			else
				needsChanging = true
			end
		end
	end
	
	if needsChanging then
		return bestUnits
	end
end

local function GetFilteredSelection(units)
	if not units then
		return nil
	end
	local newUnits = RawGetFilteredSelection(units)
	if newUnits then
		return newUnits
	end
	return units
end

function widget:SelectionChanged(units, subselection)
	return RawGetFilteredSelection(units, subselection, true, GetDoubleClickUnitDefID(units))
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Handling

local function PossiblyTransferRankThroughMorph(unitID, unitDefID)
	if morphRankTransfer[unitDefID] then
		local morphedTo = Spring.GetUnitRulesParam(unitID, "wasMorphedTo")
		if not morphedTo then
			return
		end
		selectionRank[morphedTo] = selectionRank[unitID]
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	if unitID and selectionRank[unitID] then
		PossiblyTransferRankThroughMorph(unitID, unitDefID)
		selectionRank[unitID] = nil
	end
end

local function SetSelectionRank(unitID, newRank)
	selectionRank[unitID] = newRank
end

function widget:Initialize()
	options.retreatDeselects.OnChange(options.retreatDeselects)

	WG.SetSelectionRank = SetSelectionRank
	WG.SelectionRank_GetFilteredSelection = GetFilteredSelection
end

function widget:MousePress(x, y, button)
	if firstClickUnitDefID then
		firstClickTimer = spGetTimer()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

function widget:CommandsChanged()
	if not useSelectionFiltering then
		return
	end
	local selectedUnits = Spring.GetSelectedUnits()
	local unitID = selectedUnits and selectedUnits[1]
	local unitDefID = unitID and Spring.GetUnitDefID(unitID)
	if not unitDefID then
		return
	end
	local rank = selectionRank[unitID] or defaultRank[unitDefID]
	local customCommands = widgetHandler.customCommands
	selectionRankCmdDesc.params[1] = rank
	table.insert(customCommands, selectionRankCmdDesc)
end

function widget:CommandNotify(id, params, options)
	if id ~= CMD_SELECTION_RANK then
		return false
	end
	local newRank = params[1]
	if options.right then
		newRank = (newRank + 2)%4
	end
	local selectedUnits = Spring.GetSelectedUnits()
	for i = 1, #selectedUnits do
		selectionRank[selectedUnits[i]] = newRank
	end
	if WG.noises and selectedUnits[1] then
		WG.noises.PlayResponse(selectedUnits[1], CMD_SELECTION_RANK)
	end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
