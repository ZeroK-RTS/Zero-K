local included = VFS.Include("units/vehassault.lua")
local unitDef = included.vehassault

unitDef.unitname = "tiptest"
unitDef.name = "Turn In Place test"
unitDef.description = "Tests turn in place"

unitDef.acceleration = 0.008
unitDef.maxvelocity = 5
unitDef.turnrate = 300
unitDef.turninplace = 0
unitDef.customparams.turnatfullspeed = 1

return lowerkeys({ tiptest = unitDef })
