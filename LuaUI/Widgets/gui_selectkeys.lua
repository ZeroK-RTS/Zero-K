--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Select Keys",
    desc      = "v0.032 Common SelectKey Hotkeys for EPIC Menu.",
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
	'selectcomm',
	
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
	selectcomm = { type = 'button',
		name = 'Select Commander',
		action = 'selectcomm',
	},
	
	
	
}

local echo = Spring.Echo
