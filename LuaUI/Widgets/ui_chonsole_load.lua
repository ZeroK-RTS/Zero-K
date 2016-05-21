----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Copy this file to both the luaui/widgets and the luarules/gadgets folders

-- Set this line to the Chonsole installation folder
CHONSOLE_FOLDER = "libs/chonsole"

-- Do NOT modify the following lines
if Script.GetName() == "LuaUI" then
	VFS.Include(CHONSOLE_FOLDER .. "/luaui/widgets/ui_chonsole.lua", nil, VFS.DEF_MODE)
elseif Script.GetName() == "LuaRules" then
	VFS.Include(CHONSOLE_FOLDER .. "/luarules/gadgets/ui_chonsole.lua", nil, VFS.DEF_MODE)
end
