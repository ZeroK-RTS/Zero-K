--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name 	= "Chonsole gadget",
		desc	= "Gadget support for Chonsole",
		author	= "gajop",
		date	= "In the future 2015",
		license	= "GNU GPL, v2 or later",
		layer	= 0,
		enabled = true
	}
end

-- shared (synced and unsynced)
local cmdConfig = {}

-- add optional support for i18n (we won't be using it, but extensions contain translations)
i18n = function(key, data)
	data = data or {}
	return data.default or key
end

function LoadExtensions()
	-- Load extensions (We're only interested in commands)
	for _, f in pairs(VFS.DirList(CHONSOLE_FOLDER .. "/exts", "*", VFS.DEF_MODE)) do
		local success, err = pcall(function() VFS.Include(f, nil, VFS.DEF_MODE) end)
		if not success then
			Spring.Log("Chonsole", LOG.ERROR, "Error loading extension file: " .. f)
			Spring.Log("Chonsole", LOG.ERROR, err)
		else
			if commands ~= nil then
				for _, cmd in pairs(commands) do
					cmdConfig[cmd.command] = cmd
				end
			end
		end
	end
end

local function explode(div,str)
	if (div=='') then return 
		false 
	end
	local pos,arr = 0,{}
	-- for each divider found
	for st,sp in function() return string.find(str,div,pos,true) end do
		table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
		pos = sp + 1 -- Jump past current divider
	end
	table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
	return arr
end

-- Hack for ZK as it normally squelches echos
if Game.gameName:find("Zero-K") or Game.gameName:find("Scened ZK") then
	-- FIXME: override Spring.Echo only for this widget
	local oldEcho = Spring.Echo
	Spring.Echo = function(...) 
		x = {...}
		for i = 1, #x do
			x[i] = "game_message:" .. tostring(x[i])
		end
		oldEcho(unpack(x))
	end
end

-- SYNCED
if gadgetHandler:IsSyncedCode() then
	
-- this is used to identify the current command used in Unsync
local currentCmd = ""
function Unsync(...)
	local x = {...}
	local msg = currentCmd
	for _, v in pairs(x) do
		msg = msg .. "|" .. v
	end
	SendToUnsynced('chonsoleUnsynced', msg)
end

function gadget:Initialize()
	LoadExtensions()
end

function ExecuteCustomCommand(cmd, params)
	currentCmd = cmd.command
	local success, err = pcall(function() cmd.execs(unpack(params)) end)
	if not success then
		Spring.Log("Chonsole", LOG.ERROR, "Error executing custom command in synced: " .. tostring(cmd.command))
		Spring.Log("Chonsole", LOG.ERROR, err)
	end
	currentCmd = ""
end

function gadget:RecvLuaMsg(msg)
	local msg_table = explode('|', msg)
	if msg_table[1] == "chonsole" then
		local cmd = cmdConfig[msg_table[2]]
		if cmd == nil then
			Spring.Log("Chonsole", LOG.ERROR, "No such command: " .. msg_table[2])
			return
		elseif cmd.execs == nil then
			Spring.Log("Chonsole", LOG.ERROR, "Command doesn't have synced execute (execs) function defined.")
			return
		end
		local params = {}
		for i = 3, #msg_table do
			table.insert(params, msg_table[i])
		end
		if not cmd.cheat or Spring.IsCheatingEnabled() then
			ExecuteCustomCommand(cmd, params)
		else
			Spring.Log("Chonsole", LOG.ERROR, "Attempt to execute command that requires cheats while cheating is enabled.")
		end
		return
	end
end

-- UNSYNCED
else
	
local function ExecuteInUnsynced(_, data)
    local msg_table = explode('|', data)
	local cmd = cmdConfig[msg_table[1]]
	if cmd == nil then
		Spring.Log("Chonsole", LOG.ERROR, "No such command: " .. msg_table[1])
		return
	elseif cmd.execu == nil then
		Spring.Log("Chonsole", LOG.ERROR, "Command doesn't have synced execute (execs) function defined.")
		return
	end
	local t = {}
	for i = 2, #msg_table do
		table.insert(t, msg_table[i])
	end
	local success, err = pcall(function() cmd.execu(unpack(t)) end)
	if not success then
		Spring.Log("Chonsole", LOG.ERROR, "Error executing custom command in synced: " .. tostring(cmd.command))
		Spring.Log("Chonsole", LOG.ERROR, err)
	end
end	

function gadget:Initialize()
	LoadExtensions()
	gadgetHandler:AddSyncAction('chonsoleUnsynced', ExecuteInUnsynced)
end

end