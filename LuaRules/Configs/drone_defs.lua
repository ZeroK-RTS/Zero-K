-- reloadTime is in seconds
-- offsets = {x,y,z} , where x is left(-)/right(+), y is up(+)/down(-), z is forward(+)/backward(-)

local carrierDefs = {}

local carrierDefNames = {
	armcarry = {
		spawnPieces = {"base"},
		{drone = UnitDefNames.carrydrone.id, reloadTime = 15, maxDrones = 8, spawnSize = 2, range = 1600, buildTime=3,
		 offsets = {0,60,0,colvolMidX=0, colvolMidY=0,colvolMidZ=0,aimX=0,aimY=0,aimZ=0}},
	},
	
	reef = {
		spawnPieces = {"DroneAft", "DroneFore", "DroneLower","DroneUpper"},
		{drone = UnitDefNames.carrydrone.id, reloadTime = 15, maxDrones = 2, spawnSize = 1, range = 1600, buildTime=10,
		 offsets = {0,0,0,colvolMidX=0, colvolMidY=0,colvolMidZ=0,aimX=0,aimY=0,aimZ=0}},
		{drone = UnitDefNames.carrydrone.id, reloadTime = 15, maxDrones = 2, spawnSize = 1, range = 1600, buildTime=10,
		 offsets = {0,0,0,colvolMidX=0, colvolMidY=0,colvolMidZ=0,aimX=0,aimY=0,aimZ=0}},
		{drone = UnitDefNames.carrydrone.id, reloadTime = 30, maxDrones = 2, spawnSize = 1, range = 1600, buildTime=10,
		 offsets = {0,0,0,colvolMidX=0, colvolMidY=0,colvolMidZ=0,aimX=0,aimY=0,aimZ=0}},
		{drone = UnitDefNames.carrydrone.id, reloadTime = 30, maxDrones = 2, spawnSize = 1, range = 1600, buildTime=10,
		 offsets = {0,0,0,colvolMidX=0, colvolMidY=0,colvolMidZ=0,aimX=0,aimY=0,aimZ=0}},
	},
	--corcrw = { {drone = UnitDefNames.attackdrone.id, reloadTime = 15, maxDrones = 6, spawnSize = 2, range = 900, buildTime=3,
			-- offsets = {0,0,0,colvolMidX=0, colvolMidY=0,colvolMidZ=0,aimX=0,aimY=0,aimZ=0}},
	funnelweb = {
		spawnPieces = {"emitl", "emitr"},
		{drone = UnitDefNames.attackdrone.id, reloadTime = 10, maxDrones = 6, spawnSize = 2, range = 800, buildTime=3,
		 offsets = {0,35,0,colvolMidX=0, colvolMidY=0,colvolMidZ=0,aimX=0,aimY=0,aimZ=0}},
		{drone = UnitDefNames.battledrone.id, reloadTime = 15, maxDrones = 2, spawnSize = 1, range = 800, buildTime=3,
		 offsets = {0,35,0,colvolMidX=0, colvolMidY=0,colvolMidZ=0,aimX=0,aimY=0,aimZ=0}},
	},
	nebula = {
		spawnPieces = {"pad1", "pad2", "pad3", "pad4"},
		{drone = UnitDefNames.fighterdrone.id, reloadTime = 15, maxDrones = 8, spawnSize = 2, range = 1000, buildTime=3,
		 offsets = {0,8,15,colvolMidX=0, colvolMidY=30,colvolMidZ=0,aimX=0,aimY=0,aimZ=0}}, --shift colvol to avoid collision.
	},
}

local presets = {
	module_companion_drone = {drone = UnitDefNames.attackdrone.id, reloadTime = 10, maxDrones = 2, spawnSize = 1, range = 450, buildTime=3,
							 offsets = {0,35,0,colvolMidX=0, colvolMidY=0,colvolMidZ=0,aimX=0,aimY=0,aimZ=0}},
	module_battle_drone = {drone = UnitDefNames.battledrone.id, reloadTime = 20, maxDrones = 1, spawnSize = 1, range = 600, buildTime=3,
							offsets = {0,35,0,colvolMidX=0, colvolMidY=0,colvolMidZ=0,aimX=0,aimY=0,aimZ=0}},
}

--[[
for name, ud in pairs(UnitDefNames) do
	if ud.customParams.sheath_preset then
		sheathDefNames[name] = Spring.Utilities.CopyTable(presets[ud.customParams.sheath_preset], true)
	end
end
]]--
for id, ud in pairs(UnitDefs) do
	if ud.customParams and ud.customParams.drones then
		local droneFunc = loadstring("return "..ud.customParams.drones)
		local drones = droneFunc()
		carrierDefs[id] = {}
		for i=1,#drones do
			carrierDefs[id][i] = Spring.Utilities.CopyTable(presets[drones[i]])
		end
	end
end

for name, data in pairs(carrierDefNames) do
	if UnitDefNames[name] then carrierDefs[UnitDefNames[name].id] = data	end
end

local thingsWhichAreDrones = {
	[UnitDefNames.carrydrone.id] = true,
	[UnitDefNames.attackdrone.id] = true,
	[UnitDefNames.battledrone.id] = true,
	[UnitDefNames.fighterdrone.id] = true
}
	

return carrierDefs, thingsWhichAreDrones
