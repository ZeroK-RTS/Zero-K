--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Select Keys",
    desc      = "v0.035 Common SelectKey Hotkeys for EPIC Menu.",
    author    = "CarRepairer",
    date      = "2010-09-23",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
	enabled	  = true,
 }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Game/Selections'
options_order = {
	'lbl_main',
	'select_all',
	'select_half',
	'select_one',
	
	'lbl_idle',
	'select_idleb',
	'select_idleallb',
	'select_nonidle',
	
	'lbl_same',
	'select_same',
	'select_vissame',
	
	'lbl_w',
	'select_landw',
	'selectairw',
	
	'lbl_misc',
	'uikey1',
	'uikey2',
	'uikey3',
	'uikey4',
	'uikey5',
	'uikey6',
}
options = {

	lbl_main = { type = 'label', name = 'By Total' },
	lbl_idle = { type = 'label', name = 'Idle' },
	lbl_same = { type = 'label', name = 'Of Same Type' },
	lbl_w = { type = 'label', name = 'Armed Units' },
	
	
	
	select_all = { type = 'button',
		name = 'All Units',
		desc = 'Select all units.',
		action = 'select AllMap++_ClearSelection_SelectAll+',
	},
	select_idleb = { type = 'button',
		name = 'Idle Builder',
		desc = 'Select the next idle builder.',
		action = 'select AllMap+_Builder_Idle+_ClearSelection_SelectOne+',
	},
	select_idleallb = { type = 'button',
		name = 'All Idle Builders',
		desc = 'Select all idle builders.',
		action = 'select AllMap+_Builder_Not_Building_Not_Transport_Idle+_ClearSelection_SelectAll+',
	},
	
	select_vissame = { type = 'button',
		name = 'Visible Same',
		desc = 'Select all visible units of the same type as current selection.',
		action = 'select Visible+_InPrevSel+_ClearSelection_SelectAll+',
	},
	select_same = { type = 'button',
		name = 'All Same',
		desc = 'Select all units of the same type as current selection.',
		action = 'select AllMap+_InPrevSel+_ClearSelection_SelectAll+',
	},
	select_half = { type = 'button',
		name = 'Deselect Half',
		desc = 'Deselect half of the selected units.',
		action = 'select PrevSelection++_ClearSelection_SelectPart_50+',
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
	
	lowhealth = { type = 'button',
		name = '30% Health',
		desc = '',
		action = 'select PrevSelection+_Not_RelativeHealth_30+_ClearSelection_SelectAll+',
	},
	
	
	
	----
	lbl_misc = { type = 'label', name = 'Misc ZK uikeys' },
	uikey1 = { type = 'button',
		name = 'Non-trans non-Vamp armed air',
		desc = '',
		action = 'select AllMap+_Not_Builder_Not_Building_Not_Transport_Aircraft_Weapons_Not_NameContain_Vamp_Not_Radar+_ClearSelection_SelectAll+',
	},
	uikey2 = { type = 'button',
		name = 'Vamps',
		desc = '',
		action = 'select AllMap+_NameContain_Vamp+_ClearSelection_SelectAll+',
	},
	uikey3 = { type = 'button',
		name = 'Mobile non-builders',
		desc = '',
		action = 'select AllMap+_Not_Builder_Not_Building+_ClearSelection_SelectAll+',
	},
	uikey4 = { type = 'button',
		name = 'Vultures',
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
}
