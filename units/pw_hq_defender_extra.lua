local included = VFS.Include("units/pw_hq_attacker_extra.lua")
local unitDef = included.pw_hq_attacker_extra

unitDef.name = "Defender Extra Command"

return { pw_hq_defender_extra = unitDef }
