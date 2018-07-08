local included = VFS.Include("units/pw_hq_attacker.lua")
local unitDef = included.pw_hq_attacker

unitDef.unitname = "pw_hq_defender"
unitDef.name = "Defender Command"

return { pw_hq_defender = unitDef }
