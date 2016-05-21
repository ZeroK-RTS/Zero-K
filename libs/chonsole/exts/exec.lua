-- This module provides functionality for executing Lua code using the console

-- TODO: would be nice if we could print the evaluation of some commands, e.g. "/execw 5+5" could print 10
local function ExecuteLuaCommand(luaCommandStr)
	Spring.Echo("$ " .. luaCommandStr)
-- 			if not luaCommandStr:gsub("==", "_"):gsub("~=", "_"):gsub(">=", "_"):gsub("<=", "_"):find("=") then
-- 				luaCommandStr = "return " .. luaCommandStr
-- 			end
	local luaCommand, msg = loadstring(luaCommandStr)
	if not luaCommand then
		Spring.Echo(msg)
	else
		setfenv(luaCommand, getfenv())
		local success, msg = pcall(function()
			local msg = {luaCommand()}
			if #msg > 0 then
				Spring.Echo(unpack(msg))
			end
		end)
		if not success then
			Spring.Echo(msg)
		end
	end
end

commands = {
	{ 
		command = "exec",
		description = i18n("exec_desc", {default = "Execute Lua command in a widget"}),
		cheat = false,
		exec = function(command, cmdParts)
			local commandPart = cmdParts[1]
			local x = command:lower():find(commandPart)
			local luaCommandStr = command:sub(x + #commandPart):trimLeft()
			ExecuteLuaCommand(luaCommandStr)
		end,
	},
	{ 
		command = "execs",
		description = i18n("execs_desc", {default = "Execute Lua command in a synced gadget"}),
		cheat = true,
		exec = function(command, cmdParts)
			local commandPart = cmdParts[1]
			local x = command:lower():find(commandPart)
			local luaCommandStr = command:sub(x + #commandPart):trimLeft()
			Sync(luaCommandStr)
		end,
		execs = function(luaCommandStr)
			ExecuteLuaCommand(luaCommandStr)
		end,
	},
	{ 
		command = "execu",
		description = i18n("execu_desc", {default = "Execute Lua command in an unsynced gadget"}),
		cheat = true,
		exec = function(command, cmdParts)
			local commandPart = cmdParts[1]
			local x = command:lower():find(commandPart)
			local luaCommandStr = command:sub(x + #commandPart):trimLeft()
			Sync(luaCommandStr)
		end,
		execs = function(luaCommandStr)
			Unsync(luaCommandStr)
		end,
		execu = function(luaCommandStr)
			ExecuteLuaCommand(luaCommandStr)
		end,
	},
	{ 
		command = "execgl",
		description = i18n("execgl_desc", {default = "Execute Lua command in a widget OpenGL callin"}),
		cheat = false,
		exec = function(command, cmdParts)
			local commandPart = cmdParts[1]
			local x = command:lower():find(commandPart)
			local luaCommandStr = command:sub(x + #commandPart):trimLeft()
			delayGL = function() ExecuteLuaCommand(luaCommandStr) end
		end,
	},
}