local included = VFS.Include("units/shipcarrier.lua")
local unitDef = included.shipcarrier
unitDef.name = [[Dazzle Reef]]
unitDef.customParams.override_tex1 = "unittextures/moire_texture.dds"

return { dbg_moire = unitDef }
