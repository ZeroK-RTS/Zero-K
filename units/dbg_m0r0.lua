local included = VFS.Include("units/jumpsumo.lua")
local unitDef = included.jumpsumo
unitDef.customParams.override_tex2 = "m0r0.dds"

return { dbg_m0r0 = unitDef }
