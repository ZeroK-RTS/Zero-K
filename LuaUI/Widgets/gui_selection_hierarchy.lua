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

local selectioRankCmdDesc = {
	id      = CMD_SELECTION_RANK,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Selection Rank',
	action  = 'selection_rank',
	tooltip = 'Selection filtering rank: only unts of the highest rank are selected. Hold Shift to ignore filtering.',
	params  = {0, 'Lowest', 'Low', 'Medium', 'High'}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local selectionRank = {}
local defaultRank = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.isImmobile or ud.speed == 0 then
		defaultRank[i] = 1
	elseif ud.isMobileBuilder and not ud.customParams.commtype then
		defaultRank[i] = 2
	else
		defaultRank[i] = 3
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Epic Menu Options

local ctrlFlattenRank = 1
local useSelectionFiltering = true
local selectionFilteringOnlyAlt = false

options_path = 'Settings/Interface/Selection'
options = {
	useSelectionFilteringOption = {
		name = "Use selection filtering",
		type = "bool",
		value = true,
		desc = "Enable to use selection filtering.",
		OnChange = function (self)
			useSelectionFiltering = self.value
		end
	},
	selectionFilteringOnlyAltOption = {
		name = "Only filter when Alt is held",
		type = "bool",
		value = false,
		desc = "Enable selection filtering when Alt is held. Required the main selection filtering option to be enabled.",
		OnChange = function (self)
			selectionFilteringOnlyAlt = self.value
		end
	},
	ctrlFlattenRankOption = {
		name = 'Hold Ctrl to ignore rank difference above:',
		type = 'number',
		value = 1,
		min = 0, max = 3, step = 1,
		noHotkey = true,
		OnChange = function (self)
			ctrlFlattenRank = self.value
		end
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Selection handling

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

local function RawGetFilteredSelection(units, subselection, subselectionCheckDone)
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
	
	local needsChanging = false
	local bestRank, bestUnits 
	for i = 1, #units do
		local unitID = units[i]
		local rank = unitID and selectionRank[unitID]
		if not rank then
			local unitDefID = Spring.GetUnitDefID(unitID)
			rank = unitDefID and defaultRank[unitDefID]
		end
		if rank then
			if ctrl and rank > ctrlFlattenRank then
				rank = ctrlFlattenRank
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
	return RawGetFilteredSelection(units, subselection, true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Handling

local function PossiblyTransferRankThroughMorph(unitID)
	local morphedTo = Spring.GetUnitRulesParam(unitID, "wasMorphedTo")
	if not morphedTo then
		return
	end

	selectionRank[morphedTo] = selectionRank[unitID]
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	if unitID and selectionRank[unitID] then
		PossiblyTransferRankThroughMorph(unitID)
		selectionRank[unitID] = nil
	end
end

local function SetSelectionRank(unitID, newRank)
	selectionRank[unitID] = newRank
end

function widget:Initialize()
	WG.SetSelectionRank = SetSelectionRank
	WG.SelectionRank_GetFilteredSelection = GetFilteredSelection
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
	selectioRankCmdDesc.params[1] = rank
	table.insert(customCommands, selectioRankCmdDesc)
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
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
