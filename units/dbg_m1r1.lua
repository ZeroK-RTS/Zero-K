local included = VFS.Include("units/jumpsumo.lua")
local unitDef = included.jumpsumo
unitDef.customParams.override_tex2 = "unittextures/m1r1.dds"

return { dbg_m1r1 = unitDef }
