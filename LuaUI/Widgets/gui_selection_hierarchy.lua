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

local SUC = Spring.Utilities.CMD
local CMD_SELECTION_RANK = SUC.SELECTION_RANK

local isGuardCommand = {
	[CMD.GUARD     ] = true,
	[SUC.ORBIT     ] = true,
	[SUC.ORBIT_DRAW] = true,
	[SUC.AREA_GUARD] = true,
}

local rearmUnitDef = {}

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
local disableForNextUpdate = false

local defaultRank, morphRankTransfer = VFS.Include(LUAUI_DIRNAME .. "Configs/selection_rank.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Epic Menu Options

local shiftFlattenRank = 0
local ctrlFlattenRank = 1
local altFilterHighRank = 2
local metaFlattenRank = 3
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

options_path = 'Settings/Interface/Selection Filtering'
local retreatPath = 'Settings/Interface/Retreat Zones'
options_order = {
	'label_selection_rank',
	'shiftFlattenRankOption',
	'ctrlFlattenRankOption',
	'metaFlattenRankOption',
	'selectionFilteringOnlyAltOption',
	'altBlocksHighRankSelection',
	'doubleClickFlattenRankOption',
	'controlGroupFlattenRank',
	'guardRankOverrideOption',
	'rearmingOverrideRank',
	'retreatOverrideOption',
	'retreatingRankOption',
	'retreatDeselects',
	'useSelectionFilteringOption',
}

options = {
	label_selection_rank = {
		type = 'text',
		name = 'Selection Filtering',
		value = [[Default filtering is:
 - Unmodified selection only selects the boxed units with the highest rank.
 - Shift allows selection of mixed ranks.
 - Combat units default to rank 3.
 - Constructors default to rank 2.
 - Structures default to rank 1.
 - Change rank mid game by toggling the state on the the command card (circle with the number top right).
 - Default rank can be edited in 'Settings/Unit Behaviour/Default States'.
The modifiers can be configured below.
 ]],
	},
	useSelectionFilteringOption = {
		name = "Enable selection filtering",
		type = "bool",
		value = true,
		desc = "Enables selection rank, which filters constructors from combat units by default.",
		OnChange = function (self)
			useSelectionFiltering = self.value
		end
	},
	shiftFlattenRankOption = {
		name = 'Hold Shift to ignore rank difference above:',
		desc = "Set to 0 to have shift ignore rank. Set to 3 to have shift have no effect on rank.",
		type = 'number',
		value = shiftFlattenRank,
		min = 0, max = 3, step = 1,
		noHotkey = true,
		tooltip_format = "%.0f",
		OnChange = function (self)
			shiftFlattenRank = self.value
		end
	},
	ctrlFlattenRankOption = {
		name = 'Hold Ctrl to ignore rank difference above:',
		desc = "Useful so that global selection hotkeys (such as Ctrl+Z) can expand upon a mixed selection.",
		type = 'number',
		value = ctrlFlattenRank,
		min = 0, max = 3, step = 1,
		noHotkey = true,
		tooltip_format = "%.0f",
		OnChange = function (self)
			ctrlFlattenRank = self.value
		end
	},
	metaFlattenRankOption = {
		name = 'Hold Space to ignore rank difference above:',
		desc = "Set to 0 to have space ignore rank. Set to 3 to have space have no effect on rank.",
		type = 'number',
		value = metaFlattenRank,
		min = 0, max = 3, step = 1,
		noHotkey = true,
		tooltip_format = "%.0f",
		OnChange = function (self)
			metaFlattenRank = self.value
		end
	},
	selectionFilteringOnlyAltOption = {
		name = "Only filter when Alt is held",
		type = "bool",
		value = false,
		noHotkey = true,
		desc = "Enable selection filtering when Alt is held. Requires the main selection filtering option to be enabled.",
		OnChange = function (self)
			selectionFilteringOnlyAlt = self.value
		end
	},
	altBlocksHighRankSelection = {
		name = 'Hold Alt to filter out ranks above:',
		desc = "Useful for selecting low-rank units, such as constructors as they default to rank 2.",
		type = 'number',
		value = altFilterHighRank,
		min = 0, max = 3, step = 1,
		noHotkey = true,
		tooltip_format = "%.0f",
		OnChange = function (self)
			altFilterHighRank = self.value
		end
	},
	doubleClickFlattenRankOption = {
		name = 'Double click ignores rank difference above:',
		desc = "Allows for double click selection of many units of the same type and differing selection rank.",
		type = 'number',
		value = doubleClickFlattenRank,
		min = 0, max = 3, step = 1,
		noHotkey = true,
		tooltip_format = "%.0f",
		OnChange = function (self)
			doubleClickFlattenRank = self.value
		end
	},
	controlGroupFlattenRank = {
		name = "Control groups ignore rank difference above:",
		desc = "Allows selecting entire control groups of differing selection rank.",
		type = "number",
		value = controlGroupFlattenRank,
		min = 0, max = 3, step = 1,
		noHotkey = true,
		OnChange = function (self)
			controlGroupFlattenRank = self.value
		end
	},
	guardRankOverrideOption = {
		name = 'Guard rank reduction:',
		desc = "Units currently executing the guard command are reduced to this selection rank, if higher.",
		type = 'number',
		value = 3,
		min = 0, max = 3, step = 1,
		tooltip_format = "%.0f",
		noHotkey = true,
	},
	rearmingOverrideRank = {
		name = 'Rearming rank reduction:',
		desc = "Units currently rearming are reduced to this selection rank, if higher.",
		type = 'number',
		value = 3,
		min = 0, max = 3, step = 1,
		tooltip_format = "%.0f",
		noHotkey = true,
	},
	retreatOverrideOption = {
		name = "Retreat overrides selection rank",
		desc = "Retreating units will be treated as a different selection rank.",
		type = "bool",
		value = true,
		noHotkey = true,
		path = retreatPath,
		OnChange = function (self)
			retreatOverride = self.value
		end
	},
	retreatingRankOption = {
		name = 'Retreat selection override:',
		desc = "Retreating units are treated as this selection rank, if override is enabled.",
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
		name = "Retreat deselects",
		desc = "Whether a unit that starts retreating will be deselected, so as not to keep accidentally bringing units back into danger.",
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
	if not useSelectionFiltering or disableForNextUpdate then
		return
	end
	if not units then
		return
	end
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	
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
		local unitDefID = Spring.GetUnitDefID(unitID)
		local rank = unitID and selectionRank[unitID]
		if not rank then
			rank = unitDefID and defaultRank[unitDefID]
		end
		if retreatOverride and unitID and (Spring.GetUnitRulesParam(unitID, "retreat") == 1) and (rank > retreatingRank) then
			rank = retreatingRank
		end

		if WG.GlobalBuildCommand and WG.GlobalBuildCommand.IsSelectionOverrideSet and WG.GlobalBuildCommand.IsControllingUnit(unitID) and (rank > WG.GlobalBuildCommand.SelectionOverrideRank) then
			rank = WG.GlobalBuildCommand.SelectionOverrideRank
		end

		if rank then
			local guardRankOverrideRank = options.guardRankOverrideOption.value
			if rank > guardRankOverrideRank then
				local cmdID = Spring.GetUnitCurrentCommand(unitID)
				if isGuardCommand[cmdID] then
					rank = guardRankOverrideRank
				end
			end

			if rearmUnitDef[unitDefID] then
				local rearmingOverrideRank = options.rearmingOverrideRank.value
				local reammoState = Spring.GetUnitRulesParam(unitID, "noammo") or 0
				if (reammoState == 1 or reammoState == 2)
					and rank > rearmingOverrideRank then
					rank = rearmingOverrideRank
				end
			end

			if (alt and rank > altFilterHighRank) then
				rank = -1
			end
			if ctrl and rank > ctrlFlattenRank then
				rank = ctrlFlattenRank
			end
			if shift and rank > shiftFlattenRank then
				rank = shiftFlattenRank
			end
			if meta and rank > metaFlattenRank then
				rank = metaFlattenRank
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
	for unitDefID = 1, #UnitDefs do
		local ud = UnitDefs[unitDefID]
		if ud.customParams.reammoseconds then
			rearmUnitDef[unitDefID] = true
		end
	end
end

function widget:MousePress(x, y, button)
	if firstClickUnitDefID then
		firstClickTimer = spGetTimer()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget API for overriding selection rank

function widget:Update()
	if not disableForNextUpdate or disableForNextUpdate <= 0 then
		widgetHandler:RemoveWidgetCallIn("Update", widget)
		disableForNextUpdate = false
		return
	end
	disableForNextUpdate = disableForNextUpdate - 1
end


function WG.SelectMapIgnoringRank(unitMap, append)
	if useSelectionFiltering then
		disableForNextUpdate = 1
		widgetHandler:UpdateWidgetCallIn("Update", widget)
		Spring.SelectUnitMap(unitMap, append)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

function widget:CommandsChanged()
	if disableForNextUpdate then
		disableForNextUpdate = false
		return
	end
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
