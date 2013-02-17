--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Unit Commands And Selections",
    desc      = "v0.001 Add commands and selections to Epicmenu",
    author    = "CarRepairer",
    date      = "2012-02-16",
    license   = "GNU GPL, v2 or later",
    layer     = 9991,
    enabled   = true,
  }
end 


-------------------------------------------------

local echo				= Spring.Echo

------------------------------------------------

-- config
local common_commands, states_commands, factory_commands,
	econ_commands, defense_commands, special_commands,
	globalCommands, overrides, custom_cmd_actions = include("Configs/integral_menu_commands.lua")


------------------------------------------------

-- globals



------------------------------------------------
-- options


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

	--selectkey options
	lbl_main = { type = 'label', name = 'By Total' },
	lbl_idle = { type = 'label', name = 'Idle' },
	lbl_same = { type = 'label', name = 'Same Type' },
	lbl_w = { type = 'label', name = 'Armed Units' },
	
	lbl_misc = { type = 'label', name = 'Misc ZK uikeys' },
	
	select_all = { type = 'button',
		name = 'All Units',
		desc = 'Select all units.',
		action = 'select AllMap++_ClearSelection_SelectAll+',
	},
	select_idleb = { type = 'button',
		name = 'Idle Builder',
		desc = 'Select the next idle builder.',
		action = 'select AllMap+_Builder_Not_Building_Idle+_ClearSelection_SelectOne+',
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


local function CapCase(str)
	local str = str:lower()
	str = str:gsub( '_', ' ' )
	str = str:sub(1,1):upper() .. str:sub(2)
	
	str = str:gsub( ' (.)', 
		function(x) return (' ' .. x):upper(); end
		)
	return str
end

local function AddHotkeyOptions()
	local options_order_tmp_cmd = {}
	local options_order_tmp_states = {}
	for cmdname, number in pairs(custom_cmd_actions) do 
			
		local cmdnamel = cmdname:lower()
		local cmdname_disp = CapCase(cmdname)
		options[cmdnamel] = {
			name = cmdname_disp,
			type = 'button',
			action = cmdnamel,
			path = 'Game/Commands',
		}
		if number == 2 then
			options_order_tmp_states[#options_order_tmp_states+1] = cmdnamel
		else
			options_order_tmp_cmd[#options_order_tmp_cmd+1] = cmdnamel
		end
	end

	options.lblcmd 			= { type='label', name='Unit Commands', path = 'Game/Commands',}
	options['lblstate'] 	= { type='label', name='State Commands', path = 'Game/Commands',}
	
	
	table.sort(options_order_tmp_cmd)
	table.sort(options_order_tmp_states)

	options_order[#options_order+1] = 'lblcmd'
	for _, option in ipairs( options_order_tmp_cmd ) do
		options_order[#options_order+1] = option
	end
	
	options_order[#options_order+1] = 'lblstate'
	for _, option in ipairs( options_order_tmp_states ) do
		options_order[#options_order+1] = option
	end
end

AddHotkeyOptions()


---


