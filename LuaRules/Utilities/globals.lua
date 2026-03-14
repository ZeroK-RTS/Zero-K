Spring.Utilities.CMD = VFS.Include("LuaRules/Configs/customcmds.lua", nil, VFS.GAME)

-- Inserts
-- gl.InstanceVBOTable = VFS.Include("modules/graphics/instancevbotable.lua")
-- gl.InstanceVBOIdTable = VFS.Include("modules/graphics/instancevboidtable.lua")
-- gl.LuaShader = VFS.Include("modules/graphics/LuaShader.lua")
-- gl.R2tHelper = VFS.Include("modules/graphics/r2thelper.lua")
VFS.Include("modules/graphics/init.lua").Init(gl)
