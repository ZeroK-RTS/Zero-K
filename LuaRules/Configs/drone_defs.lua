-- reloadTime is in seconds
-- offsets = {x,y,z} , where x is left(-)/right(+), y is up(+)/down(-), z is forward(+)/backward(-)
local BUILD_UPDATE_INTERVAL = 15

local carrierDefs = {}

local carrierDefNames = {
	armcarry = {
		spawnPieces = {"base"},
		{
			drone = UnitDefNames.carrydrone.id, 
			reloadTime = 15, 
			maxDrones = 8, 
			spawnSize = 2, 
			range = 1600, 
			buildTime = 3, 
			maxBuild = 1,
			offsets = {0, 60, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
		},
	},
	
	reef = {
		spawnPieces = {"DroneAft", "DroneFore", "DroneLower","DroneUpper"},
		{
			drone = UnitDefNames.carrydrone.id, 
			reloadTime = 5, 
			maxDrones = 8, 
			spawnSize = 1, 
			range = 1000, 
			buildTime = 25, 
			maxBuild = 4,
			offsets = {0, 0, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
		},
	},
	--corcrw = { {drone = UnitDefNames.attackdrone.id, reloadTime = 15, maxDrones = 6, spawnSize = 2, range = 900, buildTime=3,
			-- offsets = {0,0,0,colvolMidX=0, colvolMidY=0,colvolMidZ=0,aimX=0,aimY=0,aimZ=0}},
	funnelweb = {
		spawnPieces = {"emitl", "emitr"},
		{
			drone = UnitDefNames.attackdrone.id, 
			reloadTime = 15, 
			maxDrones = 6, 
			spawnSize = 2, 
			range = 800, 
			buildTime = 10, 
			maxBuild = 1,
			offsets = {0, 35, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
		},
		{
			drone = UnitDefNames.battledrone.id,
			reloadTime = 25, 
			maxDrones = 2, 
			spawnSize = 1, 
			range = 800, 
			buildTime = 15, 
			maxBuild = 1,
			offsets = {0, 35, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
		},
	},
	nebula = {
		spawnPieces = {"pad1", "pad2", "pad3", "pad4"},
		{
			drone = UnitDefNames.fighterdrone.id, 
			reloadTime = 15, 
			maxDrones = 8, 
			spawnSize = 2, 
			range = 1000,
			buildTime = 3, 
			maxBuild = 1,
			offsets = {0, 8, 15, colvolMidX = 0, colvolMidY = 30, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0} --shift colvol to avoid collision.
		},
	},
}

local presets = {
	module_companion_drone = {
		drone = UnitDefNames.attackdrone.id, 
		reloadTime = 15, 
		maxDrones = 2,
		spawnSize = 1, 
		range = 600, 
		buildTime = 10, 
		maxBuild = 1,
		offsets = {0, 35, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
	},
	module_battle_drone = {
		drone = UnitDefNames.battledrone.id, 
		reloadTime = 25,
		maxDrones = 1, 
		spawnSize = 1, 
		range = 600, 
		buildTime = 15,
		maxBuild = 1,
		offsets = {0, 35, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
	},
}

local unitRulesCarrierDefs = {
	drone = {
		drone = UnitDefNames.attackdrone.id, 
		reloadTime = 15, 
		maxDrones = 2,
		spawnSize = 1, 
		range = 450, 
		buildTime = 10, 
		maxBuild = 1,
		offsets = {0, 50, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
	},
	battleDrone = {
		drone = UnitDefNames.battledrone.id, 
		reloadTime = 25,
		maxDrones = 1, 
		spawnSize = 1, 
		range = 600, 
		buildTime = 15,
		maxBuild = 1,
		offsets = {0, 50, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
	}
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
	if UnitDefNames[name] then 
		carrierDefs[UnitDefNames[name].id] = data	
	end
end

local thingsWhichAreDrones = {
	[UnitDefNames.carrydrone.id] = true,
	[UnitDefNames.attackdrone.id] = true,
	[UnitDefNames.battledrone.id] = true,
	[UnitDefNames.fighterdrone.id] = true
}

local function ProcessCarrierDef(carrierData)
	-- derived from: time_to_complete = (1.0/build_step_fraction)*build_interval
	local buildUpProgress = 1/(carrierData.buildTime)*(BUILD_UPDATE_INTERVAL/30)
	carrierData.buildStep = buildUpProgress
	carrierData.buildStepHealth = buildUpProgress*UnitDefs[carrierData.drone].health
	carrierData.colvolTweaked = carrierData.offsets.colvolMidX ~= 0 or carrierData.offsets.colvolMidY ~= 0
									or carrierData.offsets.colvolMidZ ~= 0 or carrierData.offsets.aimX ~= 0
										or carrierData.offsets.aimY ~= 0 or carrierData.offsets.aimZ ~= 0
	return carrierData
end

for name, carrierData in pairs(carrierDefs) do
	for i = 1, #carrierData do
		carrierData[i] = ProcessCarrierDef(carrierData[i])
	end
end

for name, carrierData in pairs(unitRulesCarrierDefs) do
	carrierData = ProcessCarrierDef(carrierData)
end

return carrierDefs, thingsWhichAreDrones, unitRulesCarrierDefs, BUILD_UPDATE_INTERVAL
