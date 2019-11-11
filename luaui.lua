-- $Id: luaui.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------

 

--------------------------------------------------------------------------------
--
--  file:    luaui.lua
--  brief:   entry point for LuaUI
--  author:  Dave Rodgers
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

LUAUI_VERSION = "LuaUI v0.3"

LUAUI_DIRNAME = 'LuaUI/'

VFS.DEF_MODE = VFS.RAW_FIRST

local STARTUP_FILENAME = LUAUI_DIRNAME .. 'camain.lua'

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- load the user's UI
--

do
  text = VFS.LoadFile(STARTUP_FILENAME, VFS.RAW_FIRST)
  if (text == nil) then
    Script.Kill('Failed to load ' .. STARTUP_FILENAME)
  end
  local chunk, err = loadstring(text)
  if (chunk == nil) then
    Script.Kill('Failed to load ' .. STARTUP_FILENAME .. ' (' .. err .. ')')
  else
    chunk()
    return
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
