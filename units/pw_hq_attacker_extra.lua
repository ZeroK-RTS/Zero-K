local included = VFS.Include("units/pw_hq_attacker.lua")
local unitDef = included.pw_hq_attacker

unitDef.name = "Attacker Extra Command"
unitDef.health = 6000
unitDef.metalCost = 100
unitDef.buildPic = [[pw_hq_extra.png]]
unitDef.objectName = [[pw_hq_small.s3o]]
unitDef.iconType = [[pw_assault_small]]
unitDef.footprintX = 5
unitDef.footprintZ = 5
unitDef.yardMap = string.rep('o', 5*5)
unitDef.collisionVolumeOffsets = [[0 0 0]]
unitDef.collisionVolumeScales  = [[75 110 75]]
unitDef.collisionVolumeType    = [[ellipsoid]]
unitDef.customParams.modelradius = 30

unitDef.featureDefs.DEAD.footprintX = 5
unitDef.featureDefs.DEAD.footprintZ = 5
unitDef.featureDefs.DEAD.object = [[pw_hq_small_dead.s3o]]

unitDef.featureDefs.HEAP.footprintX = 5
unitDef.featureDefs.HEAP.footprintZ = 5


return { pw_hq_attacker_extra = unitDef }
