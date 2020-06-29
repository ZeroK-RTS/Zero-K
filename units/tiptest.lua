local included = VFS.Include("units/vehassault.lua")
local unitDef = included.vehassault

unitDef.unitname = "tiptest"
unitDef.name = "Turn In Place test"
unitDef.description = "Tests turn in place"

unitDef.acceleration = 0.04
unitDef.maxVelocity = 5
unitDef.turnRate = 300
unitDef.turninplace = 0
unitDef.customParams.turnatfullspeed = 1

return { tiptest = unitDef }
