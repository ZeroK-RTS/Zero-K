local included = VFS.Include("units/pw_hq_attacker.lua")
local unitDef = included.pw_hq_attacker

unitDef.unitname = "pw_hq_defender"
unitDef.name = "Defender Command"
unitDef.customparams.helptext = "This building is integral to strategic control of the planet. If the Attackers lose but destroy this Command Center they gain a small amount of influence, 20% of what they would have gained if they won."

return { pw_hq_defender = unitDef }
