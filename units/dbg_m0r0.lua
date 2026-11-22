local included = VFS.Include("units/jumpsumo.lua")
local unitDef = included.jumpsumo
unitDef.customParams.override_tex2 = "unittextures/m0r0.dds"
unitDef.customParams.unit_class_tags = nil -- could have these reskins as special variants but I it may pollute the unit pool/the original intent was vet

return { dbg_m0r0 = unitDef }
