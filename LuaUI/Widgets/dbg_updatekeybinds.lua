-- $Id: gui_jumpjets.lua 4207 2009-03-29 01:08:09Z quantum $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local name = "Keybind Updater v0.9.3"

function widget:GetInfo()
  return {
    name      = name,
    desc      = "Runtime pdating for keybinds.",
    author    = "KingRaptor",
    date      = "12 December, 2011",
    license   = "Public domain",
    layer     = -math.huge,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local toBind = {
	jump = {
		keys = {"any+j"},
		unbind = {"any+j mouse2"}
	},
	oneclickwep = {
		keys = {"d", "shift+d"},
	},
	selectcomm = {
		keys = {"ctrl+c", "shift+ctrl+c"},
		unbindaction = {"select AllMap+_Commander+_ClearSelection_SelectOne+"}
	},
}

function widget:Initialize()
	for command, info in pairs(toBind) do
		local hotkeys = Spring.GetActionHotKeys(command)
		--Spring.Echo(hotkeys)
		if #hotkeys == 0 then	-- only take action if the command is not already bound
			-- unbind keys
			for i=1,#(info.unbind or {}) do
				Spring.SendCommands("unbind "..info.unbind[i])
				Spring.Echo("<" .. name .. "> Unbinding key/action: "..info.unbind[i])
			end
			for i=1,#(info.unbindaction or {}) do
				Spring.SendCommands("unbindaction "..info.unbindaction[i])
				Spring.Echo("<" .. name .. "> Unbinding key: "..info.unbindaction[i])
			end
			for i=1,#(info.unbindkeyset or {}) do
				Spring.SendCommands("unbindkeyset "..info.unbindkeyset[i])
				Spring.Echo("<" .. name .. "> Unbinding action: "..info.unbindkeyset[i])
			end
			
			-- bind keys
			for i=1,#(info.keys or {})  do
				Spring.SendCommands("bind "..info.keys[i] .. " " .. command)
				Spring.Echo("<" .. name .. "> Binding "..info.keys[i] .. " to action " .. command)
			end	
		end
	end
	--widgetHandler:RemoveWidget()
end 

function widget:Shutdown()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

























