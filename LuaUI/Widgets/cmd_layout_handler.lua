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
-- Command List Processing

-- layout handler - its needed for custom commands to work and to delete normal spring menu
local function LayoutHandler(xIcons, yIcons, cmdCount, commands)
	--Spring.Echo("===== LayoutHandler =======")
	--Spring.Utilities.TableEcho(commands)
	
	widgetHandler.commands   = commands
	widgetHandler.commands.n = cmdCount
	widgetHandler:CommandsChanged()
	local reParamsCmds = {}
	local customCmds = {}
	
	local cnt = 0
	
	local AddCommand = function(command) 
		local cc = {}
		Spring.Utilities.CopyTable(cc, command)
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
	for i = 1, #widgetHandler.customCommands do
		AddCommand(widgetHandler.customCommands[i])
	end

	if (cmdCount <= 0) then
		return "", xIcons, yIcons, emptyTable, customCmds, emptyTable, emptyTable, emptyTable, emptyTable, reParamsCmds, emptyTable --prevent CommandChanged() from being called twice when deselecting all units  (copied from ca_layout.lua)
	end
	return "", xIcons, yIcons, emptyTable, customCmds, emptyTable, emptyTable, emptyTable, emptyTable, reParamsCmds, {[1337]=9001}
end 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

function widget:Initialize()
	widgetHandler:ConfigLayoutHandler(LayoutHandler)
	Spring.ForceLayoutUpdate()
end

function widget:Shutdown()
	widgetHandler:ConfigLayoutHandler(true)
	Spring.ForceLayoutUpdate()
end