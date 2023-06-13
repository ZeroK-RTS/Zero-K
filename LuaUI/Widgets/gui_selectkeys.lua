--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Select Keys",
    desc      = "v0.035 Common SelectKey Hotkeys for EPIC Menu.",
    author    = "CarRepairer",
    date      = "2010-09-23",
    license   = "GNU GPL, v2 or later",
    layer     = 1002,
	enabled	  = true,
 }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--[[

Note:

The selection actions in this file must match those in luaui/configs/zk_keys.lua

Please keep them up to date.

--]]
--------------------------------------------------------------------------------

options_path = 'Hotkeys/Selection'
options_order = {
	'lbl_visibilty',
	'select_all_visible',
	'select_landw',
	'selectairw',
	'select_visible_constructor',
	
	'lbl_same',
	'select_same',
	'select_same_except_builder',
	'select_vissame',
	
	'lbl_filter',
	'select_half',
	'select_one',
	'select_nonidle',
	'select_idle',
	'select_constructor',
	'select_non_constructor',
	'lowhealth_30',
	'highhealth_30',
	'lowhealth_60',
	'highhealth_60',
	'lowhealth_100',
	'highhealth_100',
	'filterfulltransports',
	'filteremptytransports',
	
	'lbl_w',
	'select_all',
	'uikey1',
	'uikey1a',
	'uikey1b',
	'uikey2',
	'uikey2a',
	'uikey3',
	'uikey4',
	'uikey5',
	'uikey7',
	'selectfulltransports',
	'selectemptytransports',
	'uikey6',
	'lbl_other',
	'select_missiles'
}
options = {

	lbl_filter = { type = 'label', name = 'Filters'},
	lbl_visibilty = { type = 'label', name = 'On Screen'},
	lbl_same = { type = 'label', name = 'By Type In Selection' },
	lbl_w = { type = 'label', name = 'Global Selection' },
	lbl_other = { type = 'label', name = 'Other' },
	
	select_all = { type = 'button',
		name = 'All Units',
		desc = 'Select all units.',
		action = 'select AllMap++_ClearSelection_SelectAll+',
	},
	select_all_visible = { type = 'button',
		name = 'All Visible Units',
		desc = 'Select all visible units.',
		action = 'select Visible++_ClearSelection_SelectAll+',
	},
	
	select_landw = { type = 'button',
		name = 'Visible Armed Land',
		desc = 'Select all visible armed land units.',
		action = 'select Visible+_Not_Builder_Not_Building_Not_Aircraft_Weapons+_ClearSelection_SelectAll+',
	},
	selectairw = { type = 'button',
		name = 'Visible Armed Flying',
		desc = 'Select all visible armed flying units.',
		action = 'select Visible+_Not_Building_Not_Transport_Aircraft_Weapons+_ClearSelection_SelectAll+',
	},
	select_visible_constructor = { type = 'button',
		name = 'Visible Builders',
		desc = 'Select all visible mobile constructors.',
		action = 'select Visible+_Builder_Not_Building+_ClearSelection_SelectAll+',
	},
	select_vissame = { type = 'button',
		name = 'Visible Same',
		desc = 'Select all visible units of the same type as current selection.',
		action = 'select Visible+_InPrevSel+_ClearSelection_SelectAll+',
	},
	select_same_except_builder = { type = 'button',
		name = 'All Same Except Builders',
		desc = 'Deselects builders then selects all units of the same type as current selection.',
		action = 'select AllMap+_InPrevSel_Not_Builder+_ClearSelection_SelectAll+',
	},
	select_same = { type = 'button',
		name = 'All Same',
		desc = 'Select all units of the same type as current selection.',
		action = 'select AllMap+_InPrevSel+_ClearSelection_SelectAll+',
	},
	select_half = { type = 'button',
		name = 'Deselect Half',
		desc = 'Deselect half of the selected units.',
		action = 'select PrevSelection++_ClearSelection_SelectPart_50+',
	},
	select_one = { type = 'button',
		name = 'Deselect Except One',
		desc = 'Deselect all but one of the selected units.',
		action = 'select PrevSelection++_ClearSelection_SelectOne+',
	},
	select_nonidle = { type = 'button',
		name = 'Deselect non-idle',
		desc = 'Deselect all but the idle selected units.',
		action = 'select PrevSelection+_Idle+_ClearSelection_SelectAll+',
	},
	select_idle = { type = 'button',
		name = 'Deselect idle',
		desc = 'Deselect all idle selected units.',
		action = 'select PrevSelection+_Not_Idle+_ClearSelection_SelectAll+',
	},
	select_constructor = { type = 'button',
		name = 'Deselect constructor',
		desc = 'Deselect all constructors.',
		action = 'select PrevSelection+_Not_Builder+_ClearSelection_SelectAll+',
	},
	select_non_constructor = { type = 'button',
		name = 'Deselect non-constructor',
		desc = 'Deselect all non-constructors.',
		action = 'select PrevSelection+_Builder+_ClearSelection_SelectAll+',
	},
	selectfulltransports = { type = 'button',
		name = 'Select Full Transports',
		desc = 'Selects all full transports.',
		action = 'selectfulltransports',
		path = 'Hotkeys/Selection',
		dontRegisterAction = true,
	},
	selectemptytransports = { type = 'button',
		name = 'Select Empty Transports',
		desc = 'Selects all empty transports.',
		action = 'selectemptytransports',
		path = 'Hotkeys/Selection',
		dontRegisterAction = true,
	},
	filteremptytransports = { type = 'button',
		name = 'Only loaded transports',
		desc = 'Removes all units that arent loaded transports from the current selection.',
		action = 'filteremptytransports',
		path = 'Hotkeys/Selection',
		dontRegisterAction = true,
	},
	filterfulltransports = { type = 'button',
		name = 'Only unloaded transports',
		desc = 'Removes all units that arent unloaded transports from the current selection.',
		action = 'filterfulltransports',
		path = 'Hotkeys/Selection',
		dontRegisterAction = true,
	},
	
	select_missiles = { type = 'button',
		name = 'Select missiles',
		desc = 'Select missiles of all currently selected missile silos.',
		action = 'selectmissiles',
		bindWithAny = true,
	},
	
	lowhealth_30 = { type = 'button',
		name = 'Deselect Above 30% Health',
		desc = 'Filters high health units out of your selection.',
		action = 'select PrevSelection+_Not_RelativeHealth_30+_ClearSelection_SelectAll+',
	},
	highhealth_30 = { type = 'button',
		name = 'Deselect Below 30% Health',
		desc = 'Filters low health units out of your selection',
		action = 'select PrevSelection+_RelativeHealth_30+_ClearSelection_SelectAll+',
	},
	lowhealth_60 = { type = 'button',
		name = 'Deselect Above 60% Health',
		desc = 'Filters high health units out of your selection.',
		action = 'select PrevSelection+_Not_RelativeHealth_60+_ClearSelection_SelectAll+',
	},
	highhealth_60 = { type = 'button',
		name = 'Deselect Below 60% Health',
		desc = 'Filters low health units out of your selection',
		action = 'select PrevSelection+_RelativeHealth_60+_ClearSelection_SelectAll+',
	},
	lowhealth_100 = { type = 'button',
		name = 'Deselect Full Health',
		desc = 'Filters full health units out of your selection',
		action = 'select PrevSelection+_RelativeHealth_100+_ClearSelection_SelectAll+',
	},
	highhealth_100 = { type = 'button',
		name = 'Deselect Damaged Units',
		desc = 'Filters damaged units out of your selection',
		action = 'select PrevSelection+_Not_RelativeHealth_100+_ClearSelection_SelectAll+',
	},
	
	----
	uikey1 = { type = 'button',
		name = 'Non-transport non-Raptor armed air',
		desc = '',
		action = 'select AllMap+_Not_Builder_Not_Building_Not_Transport_Aircraft_Weapons_Not_NameContain_Raptor_Not_Radar+_ClearSelection_SelectAll+',
	},
	uikey1a = { type = 'button',
		name = 'Athenas',
		desc = '',
		action = 'select AllMap+_NameContain_Athena+_ClearSelection_SelectAll+',
	},
	uikey1b = { type = 'button',
		name = 'Swifts',
		desc = '',
		action = 'select AllMap+_NameContain_Swift+_ClearSelection_SelectAll+',
	},
	uikey2 = { type = 'button',
		name = 'Raptors',
		desc = '',
		action = 'select AllMap+_NameContain_Raptor+_ClearSelection_SelectAll+',
	},
	uikey2a = { type = 'button',
		name = 'Thunderbirds',
		desc = '',
		action = 'select AllMap+_NameContain_Thunderbird+_ClearSelection_SelectAll+',
	},
	uikey3 = { type = 'button',
		name = 'Mobile non-builders',
		desc = '',
		action = 'select AllMap+_Not_Builder_Not_Building+_ClearSelection_SelectAll+',
	},
	uikey4 = { type = 'button',
		name = 'Owls',
		desc = '',
		action = 'select AllMap+_Not_Builder_Not_Building_Not_Transport_Aircraft_Radar+_ClearSelection_SelectAll+',
	},
	uikey5 = { type = 'button',
		name = 'Air transports',
		desc = '',
		action = 'select AllMap+_Not_Builder_Not_Building_Transport_Aircraft+_ClearSelection_SelectAll+',
	},
	uikey6 = { type = 'button',
		name = 'Append non-ctrl grouped',
		desc = '',
		action = 'select AllMap+_InPrevSel_Not_InHotkeyGroup+_SelectAll+',
	},
	uikey7 = { type = 'button',
		name = 'Athenas',
		desc = '',
		action = 'select AllMap+_NameContain_Athena+_ClearSelection_SelectAll+',
	},
}

local charonID = UnitDefNames["gunshiptrans"].id
local hercID = UnitDefNames["gunshipheavytrans"].id

local spGetSelectedUnits = Spring.GetSelectedUnits
local spSelectUnitArray = Spring.SelectUnitArray
local spGetUnitIsTransporting = Spring.GetUnitIsTransporting
local spGetUnitDefID = Spring.GetUnitDefID
local spGetTeamUnitsByDefs = Spring.GetTeamUnitsByDefs
local spGetMyTeamID = Spring.GetMyTeamID
local spGetModKeyState = Spring.GetModKeyState

local function IsTransporting(unitID)
	local transported = spGetUnitIsTransporting(unitID)
	if transported ~= nil and #transported > 0 then
		return true
	else
		return false
	end
end


local function FilterTransports(wanted)
	local selection = Spring.GetSelectedUnits()
	local newselection = {}
	for i = 1, #selection do
		local unitDefID = spGetUnitDefID(selection[i])
		if (unitDefID == charonID or unitDefID == hercID) and wanted == "unloaded" and IsTransporting(selection[i]) == false then
			newselection[#newselection+1] = selection[i]
		elseif (unitDefID == charonID or unitDefID == hercID) and wanted == "loaded" and IsTransporting(selection[i]) then
			newselection[#newselection+1] = selection[i]
		end
	end
	spSelectUnitArray(newselection,false)
end

local function FilterFullTransports()
	FilterTransports("loaded")
end

local function FilterEmptyTransports()
	FilterTransports("unloaded")
end

local function SelectFullTransports()
	local _,_,_,addselect = spGetModKeyState()
	local alltrans = spGetTeamUnitsByDefs(spGetMyTeamID(),charonID)
	local allheavytrans = spGetTeamUnitsByDefs(spGetMyTeamID(),hercID)
	local newselection = {}
	for i=1, #alltrans do
		if IsTransporting(alltrans[i]) == true then
			newselection[#newselection+1] = alltrans[i]
		end
	end
	for i=1, #allheavytrans do
		if IsTransporting(allheavytrans[i]) == true then
			newselection[#newselection+1] = allheavytrans[i]
		end
	end
	spSelectUnitArray(newselection,addselect)
end

local function SelectEmptyTransports()
	local _,_,_,addselect = spGetModKeyState()
	local alltrans = spGetTeamUnitsByDefs(spGetMyTeamID(),charonID)
	local allheavytrans = spGetTeamUnitsByDefs(spGetMyTeamID(),hercID)
	local newselection = {}
	for i=1, #alltrans do
		if IsTransporting(alltrans[i]) == false then
			newselection[#newselection+1] = alltrans[i]
		end
	end
	for i=1, #allheavytrans do
		if IsTransporting(allheavytrans[i]) == false then
			newselection[#newselection+1] = allheavytrans[i]
		end
	end
	spSelectUnitArray(newselection,addselect)
end

function widget:Shutdown()
	widgetHandler:RemoveAction("selectfulltransports")
	widgetHandler:RemoveAction("selectemptytransports")
	widgetHandler:RemoveAction("filteremptytransports")
	widgetHandler:RemoveAction("filterfulltransports")
end

function widget:Initialize()
	widgetHandler:AddAction("selectemptytransports", SelectEmptyTransports, nil, 'tp')
	widgetHandler:AddAction("selectfulltransports", SelectFullTransports, nil, 'tp')
	widgetHandler:AddAction("filteremptytransports", FilterEmptyTransports, nil, 'tp')
	widgetHandler:AddAction("filterfulltransports", FilterFullTransports, nil, 'tp')
end
