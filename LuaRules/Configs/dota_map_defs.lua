local mapSizeX   = Game.mapSizeX
local mapSizeZ   = Game.mapSizeZ


local mapConfigs = {
  ["ShevaV2"] = {
    startingCreepCount = 3,
    maxCreepCount      = 7,
    creepSpawnDelay  =  900,
    creepSpawnPeriod = 1350,

    teamData = {
      [1] = {
        hqPosition      = { 1000, 1000 },
        djinnSpawnPoint = { 1200, 1150, facing = 0 },
        comRespawnPoint = {  630,  630, facing = 0 },

        healingAreas = {
          {  350,  350, radius = 500, healing = 200 },
        },
        creeperSpawnPoints = {
          { 1350,  800, facing = 1 },
          { 1350, 1300, facing = 0 },
          {  850, 1300, facing = 0 },
        },
        turretPositions = {
          -- lane turrets
          { 3470, 3652, "turret1" },
          { 4890, 1340, "turret1" },
          { 1555, 5315, "turret1" },
          { 3528,  816, "turret2" },
          { 2442, 2487, "turret2" },
          {  900, 2920, "turret2" },
          {  467, 1467, "turret3" },
          { 1467,  587, "turret3" },
          { 1573, 1443, "turret3" },
          -- base
          {  840, 1160, "turret2" },
          { 1160,  840, "turret2" },
        },
      },
      [2] = {
        hqPosition      = { mapSizeX - 1000, mapSizeZ - 1000 },
        djinnSpawnPoint = { mapSizeX - 1200, mapSizeZ - 1200, facing = 2 },
        comRespawnPoint = { mapSizeX -  630, mapSizeZ -  630, facing = 2 },

        healingAreas = {
          { mapSizeX -  350, mapSizeZ -  350, radius = 500, healing = 200 },
        },
        creeperSpawnPoints = {
          { mapSizeX -  850, mapSizeZ - 1350, facing = 2 },
          { mapSizeX - 1350, mapSizeZ - 1350, facing = 2 },
          { mapSizeX - 1350, mapSizeZ -  850, facing = 3 },
        },
        turretPositions = {
          -- lane turrets
          { 4463, 4583, "turret1" },
          { 6403, 2790, "turret1" },
          { 3125, 6655, "turret1" },
          { 7150, 4640, "turret2" },
          { 5675, 5684, "turret2" },
          { 4824, 7170, "turret2" },
          { 6524, 7664, "turret3" },
          { 7665, 6682, "turret3" },
          { 6666, 6666, "turret3" },
          -- base
          { mapSizeX - 1160, mapSizeX -  840, "turret2" },
          { mapSizeX -  840, mapSizeX - 1160, "turret2" },
        },
      },
    },

    creeperPathWaypoints = {
      [1] = { -- top right path
        { 4890, 1000 },
        --{ 6592, 1600 },
        { 6750, 2790 },
      },
      [2] = { -- middle path
        { 3980, 4100 },
      },
      [3] = { -- bottom left path
        { 1150, 5315 },
        --{ 1600, 6592 },
        { 3125, 6950 },
      },
    },
  },

  ["Sheva"] = "ShevaV2",
}


local config = mapConfigs[ Game.mapName ]

if (type(config) == "string") then
  config = mapConfigs[config]
end
if (type(config) ~= "table") then
  config = nil
end

return config