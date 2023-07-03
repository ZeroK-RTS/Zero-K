local included = VFS.Include("units/pw_hq_attacker.lua")
local unitDef = included.pw_hq_attacker

unitDef.name = "Defender Command"

return { pw_hq_defender = unitDef }
