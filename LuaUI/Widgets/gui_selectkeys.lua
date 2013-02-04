--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Select Keys",
    desc      = "v0.033 Common SelectKey Hotkeys for EPIC Menu.",
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
}
options = {

	lbl_main = { type = 'label', name = 'By Total' },
	lbl_idle = { type = 'label', name = 'Idle' },
	lbl_same = { type = 'label', name = 'Of Same Type' },
	lbl_w = { type = 'label', name = 'Armed Units' },
	select_all = { type = 'button',
		name = 'Select All Units',
		action = 'select AllMap++_ClearSelection_SelectAll+',
	},
	select_idleb = { type = 'button',
		name = 'Select An Idle Builder',
		action = 'select AllMap+_Builder_Not_Building_Idle+_ClearSelection_SelectOne+',
	},
	select_idleallb = { type = 'button',
		name = 'Select All Idle Builders',
		action = 'select AllMap+_Builder_Not_Building_Not_Transport_Idle+_ClearSelection_SelectAll+',
	},
	
	select_vissame = { type = 'button',
		name = 'In-View Units of Same Type as Selected',
		action = 'select Visible+_InPrevSel+_ClearSelection_SelectAll+',
	},
	select_same = { type = 'button',
		name = 'All Units of Same Type as Selected',
		action = 'select AllMap+_InPrevSel+_ClearSelection_SelectAll+',
	},
	select_half = { type = 'button',
		name = 'Deselect Half',
		action = 'select PrevSelection++_ClearSelection_SelectPart_50+',
	},
	select_one = { type = 'button',
		name = 'Deselect All But One',
		action = 'select PrevSelection++_ClearSelection_SelectOne+',
	},
	select_nonidle = { type = 'button',
		name = 'Deselect non-idle units',
		action = 'select PrevSelection+_Idle+_ClearSelection_SelectAll+',
	},
	select_landw = { type = 'button',
		name = 'Armed Land Units In View',
		action = 'select Visible+_Not_Builder_Not_Building_Not_Aircraft_Weapons+_ClearSelection_SelectAll+',
	},
	selectairw = { type = 'button',
		name = 'Armed Flying Units In View',
		action = 'select Visible+_Not_Building_Not_Transport_Aircraft_Weapons+_ClearSelection_SelectAll+',
	},

	
		
	lowhealth = { type = 'button',
		name = '30% Health',
		desc = '',
		action = 'select PrevSelection+_Not_RelativeHealth_30+_ClearSelection_SelectAll+',
	},
	----
	-- the below are from uikeys, I don't know what they do
	
	uikey1 = { type = 'button',
		name = 'Unknown uikey 1 - aircraft?',
		desc = '',
		action = 'select AllMap+_Not_Builder_Not_Building_Not_Transport_Aircraft_Weapons_Not_NameContain_Vamp_Not_Radar+_ClearSelection_SelectAll+',
	},
	uikey2 = { type = 'button',
		name = 'Unknown uikey 2 - vamp?',
		desc = '',
		action = 'select AllMap+_NameContain_Vamp+_ClearSelection_SelectAll+',
	},
	uikey3 = { type = 'button',
		name = 'Unknown uikey 3 - not builder?',
		desc = '',
		action = 'select AllMap+_Not_Builder_Not_Building+_ClearSelection_SelectAll+',
	},
	uikey4 = { type = 'button',
		name = 'Unknown uikey 3 - radar?',
		desc = '',
		action = 'select AllMap+_Not_Builder_Not_Building_Not_Transport_Aircraft_Radar+_ClearSelection_SelectAll+',
	},
	uikey5 = { type = 'button',
		name = 'Unknown uikey 5 - transport?',
		desc = '',
		action = 'select AllMap+_Not_Builder_Not_Building_Transport_Aircraft+_ClearSelection_SelectAll+',
	},
	uikey6 = { type = 'button',
		name = 'Unknown uikey 6 - allunits?',
		desc = '',
		action = 'select AllMap+_InPrevSel_Not_InHotkeyGroup+_SelectAll+',
	},
	
	
}

local echo = Spring.Echo
