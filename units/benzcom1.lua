return { benzcom1 = {
  unitname            = [[benzcom1]],
  name                = [[Siege Commander]],
  description         = [[Standoff Combat Commander]],
  acceleration        = 0.54,
  activateWhenBuilt   = true,
  autoHeal            = 5,
  brakeRate           = 2.25,
  buildCostMetal      = 1200,
  buildDistance       = 128,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[benzcom.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[45 54 45]],
  collisionVolumeType    = [[CylY]],
  corpse              = [[DEAD]],

  customParams        = {
    level = [[1]],
    statsname = [[dynassault1]],
    soundok = [[heavy_bot_move]],
    soundselect = [[bot_select]],
    soundok_vol = [[0.58]],
    soundselect_vol = [[0.5]],
    soundbuild = [[builder_start]],
    commtype = [[5]],
  },

  energyMake          = 6,
  energyStorage       = 500,
  energyUse           = 0,
  explodeAs           = [[ESTOR_BUILDINGEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[commander1]],
  leaveTracks         = true,
  losEmitHeight       = 40,
  maxDamage           = 2250,
  maxSlope            = 36,
  maxVelocity         = 1.25,
  maxWaterDepth       = 5000,
  metalMake           = 4,
  metalStorage        = 500,
  movementClass       = [[AKBOT2]],
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  objectName          = [[benzcom1.s3o]],
  script              = [[benzcom.lua]],
  selfDestructAs      = [[ESTOR_BUILDINGEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:LEVLRMUZZLE]],
      [[custom:RAIDMUZZLE]],
    },

  },

  showNanoSpray       = false,
  showPlayerName      = true,
  sightDistance       = 500,
  sonarDistance       = 300,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  turnRate            = 1377,
  upright             = true,
  workerTime          = 10,

  weapons             = {
    [1] = {
      def                = [[FAKELASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    [5] = {
      def                = [[ASSAULT_CANNON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
  },


  weaponDefs          = {

    FAKELASER    = {
      name                    = [[Fake Laser]],
      areaOfEffect            = 12,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        bogus = 1,
      },

      damage                  = {
        default = 0,
      },

      edgeEffectiveness       = 0.99,
      explosionGenerator      = [[custom:flash1green]],
      fireStarter             = 70,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      laserFlareSize          = 5.53,
      minIntensity            = 1,
      range                   = 360,
      reloadtime              = 0.1,
      rgbColor                = [[0 1 0]],
      soundStart              = [[weapon/laser/pulse_laser3]],
      soundTrigger            = true,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 5.53,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },


    ASSAULT_CANNON = {
      name                    = [[Assault Cannon]],
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 3,
    
      damage                  = {
        default = 360,
        planes  = 360,
      },
      
      explosionGenerator      = [[custom:INGEBORG]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.25,
      range                   = 360,
      reloadtime              = 2,
      soundHit                = [[weapon/cannon/cannon_hit2]],
      soundStart              = [[weapon/cannon/medplasma_fire]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 300,
    },

  },


  featureDefs         = {

    DEAD      = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[benzcom1_wreck.s3o]],
    },


    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }