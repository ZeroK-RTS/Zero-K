local included = VFS.Include("units/shipcarrier.lua")
local unitDef = included.shipcarrier
unitDef.name = [[Dazzle Reef]]
unitDef.customParams.override_tex1 = "unittextures/moire_texture.dds"
unitDef.customParams.unit_class_tags = nil -- could be something! but maybe looks too silly..

return { dbg_moire = unitDef }
