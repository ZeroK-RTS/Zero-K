local unitDef = VFS.Include("units/chicken_drone.lua").chicken_drone

unitDef.unitname = "chicken_drone_starter"
unitDef.buildPic = "chicken_drone_starter.png"
unitDef.customParams.statsname = "chicken_drone"

return { chicken_drone_starter = unitDef }
