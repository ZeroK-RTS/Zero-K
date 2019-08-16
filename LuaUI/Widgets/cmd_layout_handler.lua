--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Layout Handler",
		desc      = "Handles Custom Commands",
		author    = "GoogleFrog",
		date      = "8 Novemember 2016",
		license   = "GNU GPL, v2 or later",
		layer     = math.huge-1,
		enabled   = true,
		handler   = true,
	}
end

local emptyTable = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Add commands to epic menu

local custom_cmd_actions = include("Configs/customCmdTypes.lua")

local function CapCase(str)
	local str = str:lower()
	str = str:gsub( '_', ' ' )
	str = str:sub(1,1):upper() .. str:sub(2)
	
	str = str:gsub( ' (.)',
		function(x) return (' ' .. x):upper(); end
		)
	return str
end

options = {}
options_order = {}

local function AddHotkeyOptions()
	local options_order_tmp_cmd = {}
	local options_order_tmp_cmd_instant = {}
	local options_order_tmp_states = {}
	for cmdname, cmdData in pairs(custom_cmd_actions) do
		local number = cmdData.cmdType
		
		local cmdnamel = cmdname:lower()
		local cmdname_disp = cmdData.name or CapCase(cmdname)
		options[cmdname_disp] = {
			name = cmdname_disp,
			type = 'button',
			action = cmdnamel,
			path = 'Hotkeys/Commands',
		}
		if number == 2 then
			options_order_tmp_states[#options_order_tmp_states+1] = cmdname_disp
			--options[cmdnamel].isUnitStateCommand = true
		elseif number == 3 then
			options_order_tmp_cmd_instant[#options_order_tmp_cmd_instant+1] = cmdname_disp
			--options[cmdnamel].isUnitInstantCommand = true
		else
			options_order_tmp_cmd[#options_order_tmp_cmd+1] = cmdname_disp
			--options[cmdnamel].isUnitCommand = true
		end
	end

	options.lblcmd 		= { type='label', name='Targeted Commands', path = 'Hotkeys/Commands',}
	options.lblcmdinstant	= { type='label', name='Instant Commands', path = 'Hotkeys/Commands',}
	options.lblstate	= { type='label', name='State Commands', path = 'Hotkeys/Commands',}
	
	
	table.sort(options_order_tmp_cmd)
	table.sort(options_order_tmp_cmd_instant)
	table.sort(options_order_tmp_states)

	options_order[#options_order+1] = 'lblcmd'
	for i=1, #options_order_tmp_cmd do
		options_order[#options_order+1] = options_order_tmp_cmd[i]
	end
	
	options_order[#options_order+1] = 'lblcmdinstant'
	for i=1, #options_order_tmp_cmd_instant do
		options_order[#options_order+1] = options_order_tmp_cmd_instant[i]
	end
	
	options_order[#options_order+1] = 'lblstate'
	for i=1, #options_order_tmp_states do
		options_order[#options_order+1] = options_order_tmp_states[i]
	end
end

AddHotkeyOptions()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command List Processing

local function CopyTable(outtable,intable)
	for i,v in pairs(intable) do
		if (type(v)=='table') then
			if (type(outtable[i])~='table') then
				outtable[i] = {}
			end
			CopyTable(outtable[i],v)
		else
			outtable[i] = v
		end
	end
end

-- layout handler - its needed for custom commands to work and to delete normal spring menu
local function LayoutHandler(xIcons, yIcons, cmdCount, commands)
	widgetHandler.commands   = commands
	widgetHandler.commands.n = cmdCount
	widgetHandler:CommandsChanged()
	local reParamsCmds = {}
	local customCmds = {}
	
	local cnt = 0
	
	local AddCommand = function(command)
		local cc = {}
		CopyTable(cc,command )
		cnt = cnt + 1
		cc.cmdDescID = cmdCount+cnt
		if (cc.params) then
			if (not cc.actions) then --// workaround for params
				local params = cc.params
				for i=1,#params+1 do
					params[i-1] = params[i]
				end
				cc.actions = params
			end
			reParamsCmds[cc.cmdDescID] = cc.params
		end
		--// remove api keys (custom keys are prohibited in the engine handler)
		cc.pos       = nil
		cc.cmdDescID = nil
		cc.params    = nil
		
		customCmds[#customCmds+1] = cc
	end
	
	
	--// preprocess the Custom Commands
	for i=1,#widgetHandler.customCommands do
		AddCommand(widgetHandler.customCommands[i])
	end

	if (cmdCount <= 0) then
		return "", xIcons, yIcons, {}, customCmds, {}, {}, {}, {}, reParamsCmds, {} --prevent CommandChanged() from being called twice when deselecting all units  (copied from ca_layout.lua)
	end
	return "", xIcons, yIcons, {}, customCmds, {}, {}, {}, {}, reParamsCmds, {[1337]=9001}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

-- To get a list of used action just uncomment this
--local seenAction = {}
--function widget:CommandsChanged()
--	local commands = widgetHandler.commands
--	local customCommands = widgetHandler.customCommands
--	for i = 1, #commands do
--		if commands[i].action and not seenAction[commands[i].action] then
--			seenAction[commands[i].action] = true
--			Spring.Echo("action", commands[i].action)
--		end
--	end
--
--	for i = 1, #customCommands do
--		if customCommands[i].action and not seenAction[customCommands[i].action] then
--			seenAction[customCommands[i].action] = true
--			Spring.Echo("action", customCommands[i].action)
--		end
--	end
--end
-- Then find repalce '[f=0000678] action, ' with '"] = true,\n\t["'

function widget:Initialize()
	widgetHandler:ConfigLayoutHandler(LayoutHandler)
	Spring.ForceLayoutUpdate()
end

function widget:Shutdown()
	widgetHandler:ConfigLayoutHandler(true)
	Spring.ForceLayoutUpdate()
end
