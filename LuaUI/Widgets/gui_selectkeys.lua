--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Select Keys",
    desc      = "v0.02 Common SelectKey Hotkeys for EPIC Menu.",
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
		OnChange = function() Spring.SendCommands({'select AllMap++_ClearSelection_SelectAll+'}) end
	},
	select_idleb = { type = 'button',
		name = 'Select An Idle Builder',
		OnChange = function() Spring.SendCommands({'select AllMap+_Builder_Idle+_ClearSelection_SelectOne+'}) end
	},
	select_vissame = { type = 'button',
		name = 'On-screen Units of Same Type as Selected',
		OnChange = function() Spring.SendCommands({'select Visible+_InPrevSel+_ClearSelection_SelectAll+'}) end
	},
	select_same = { type = 'button',
		name = 'Units of Same Type as Selected',
		OnChange = function() Spring.SendCommands({'select AllMap+_InPrevSel+_ClearSelection_SelectAll+'}) end
	},
	select_half = { type = 'button',
		name = 'Deselect Half',
		OnChange = function() Spring.SendCommands({'select PrevSelection++_ClearSelection_SelectPart_50+'}) end
	},
	select_one = { type = 'button',
		name = 'Deselect All But One',
		OnChange = function() Spring.SendCommands({'select PrevSelection++_ClearSelection_SelectOne+'}) end
	},
	select_nonidle = { type = 'button',
		name = 'Deselect non-idle units',
		OnChange = function() Spring.SendCommands({'select PrevSelection+_Idle+_ClearSelection_SelectAll+'}) end
	},
	select_landw = { type = 'button',
		name = 'On-screen Armed Land Units',
		OnChange = function() Spring.SendCommands({'select Visible+_Not_Builder_Not_Building_Not_Commander_Not_Aircraft_Weapons+_ClearSelection_SelectAll+'}) end
	},
	selectairw = { type = 'button',
		name = 'On-screen Armed Flying Units',
		OnChange = function() Spring.SendCommands({'select Visible+_Not_Building_Not_Commander_Not_Transport_Aircraft_Weapons+_ClearSelection_SelectAll+'}) end
	},
	
	
	
}

local echo = Spring.Echo
