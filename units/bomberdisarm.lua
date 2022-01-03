return { bomberdisarm = {
  unitname            = [[bomberdisarm]],
  name                = [[Thunderbird]],
  description         = [[Disarming Lightning Bomber]],
  brakerate           = 0.4,
  buildCostMetal      = 550,
  buildPic            = [[bomberdisarm.png]],
  canFly              = true,
  canMove             = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[48 20 60]],
  collisionVolumeType    = [[ellipsoid]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[70 25 70]],
  selectionVolumeType    = [[cylY]],
  corpse              = [[DEAD]],
  cruiseAlt           = 180,

  customParams        = {
    modelradius    = [[10]],
    requireammo    = [[1]],
    refuelturnradius = [[170]],
    reammoseconds    = [[15]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[bomberriot]],
  maxAcc              = 0.5,
  maxDamage           = 1120,
  maxFuel             = 1000000,
  maxRudder           = 0.0052,
  maxVelocity         = 9,
  noChaseCategory     = [[TERRAFORM FIXEDWING LAND SHIP SWIM GUNSHIP SUB HOVER]],
  objectName          = [[stiletto.s3o]],
  script              = [[bomberdisarm.lua]],
  selfDestructAs      = [[GUNSHIPEX]],
  sightDistance       = 780,
  turnRadius          = 320,

  weapons             = {

    {
      def                = [[BOGUS_BOMB]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

    {
      def                = [[ARMBOMBLIGHTNING]],
      mainDir            = [[0 -1 0]],
      maxAngleDif        = 0,
      onlyTargetCategory = [[NONE]],
    },

  },

  weaponDefs          = {

    ARMBOMBLIGHTNING = {
      name                    = [[Lightning]],
      areaOfEffect            = 160,
      avoidFeature            = false,
      avoidFriendly           = false,
      beamTime                = 1/30,
      burst                   = 80,
      burstRate               = 0.3,
      cameraShake             = 150,
      canattackground         = false,
      collideFriendly         = false,
      coreThickness           = 0.6,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        reaim_time = 15, -- Fast update not required (maybe dangerous)
        disarmDamageMult = 1,
        disarmDamageOnly = 1,
        disarmTimer      = 16, -- seconds
      
        light_radius = 350,
        light_color = [[2 2 2]],
      },
 
      damage                  = {
        default        = 650,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:WHITE_LIGHTNING_BOMB]],
      fireStarter             = 90,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 5,
      minIntensity            = 1,
      range                   = 730,
      reloadtime              = 1,
      rgbColor                = [[1 1 1]],
      sprayAngle              = 5000,
      texture1                = [[lightning]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 10,
      tileLength              = 50,
      tolerance               = 32767,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2250,
    },


    BOGUS_BOMB       = {
      name                    = [[Fake Bomb]],
      avoidFeature            = false,
      avoidFriendly           = false,
      burst                   = 2,
      burstrate               = 1,
      collideFriendly         = false,

      customParams            = {
        bogus = 1,
      },

      damage                  = {
        default = 0,
      },

      explosionGenerator      = [[custom:NONE]],
      interceptedByShieldType = 1,
      intensity               = 0,
      myGravity               = 0.8,
      noSelfDamage            = true,
      range                   = 500,
      reloadtime              = 1,
      sprayangle              = 64000,
      weaponType              = [[AircraftBomb]],
    },

  },

  featureDefs         = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[Stiletto_dead.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
