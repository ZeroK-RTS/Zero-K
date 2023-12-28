-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--
-- A collection of some useful functions
--
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

Spring.Utilities = Spring.Utilities or {}

local SCRIPT_DIR = Script.GetName() .. '/'
local utilFiles = VFS.DirList(SCRIPT_DIR .. 'Utilities/', "*.lua")
for i=1, #utilFiles do
  if string.find(utilFiles[i], "json.lua") or -1 > -1 then
    Spring.Utilities.json = VFS.Include(utilFiles[i])
  else
    VFS.Include(utilFiles[i])
  end
end
