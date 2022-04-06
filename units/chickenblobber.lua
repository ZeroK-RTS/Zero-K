return { chickenblobber = {
  unitname            = [[chickenblobber]],
  name                = [[Blobber]],
  description         = [[Heavy Artillery]],
  acceleration        = 1.3,
  activateWhenBuilt   = true,
  brakeRate           = 1.5,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickenblobber.png]],
  buildTime           = 900,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],

  customParams        = {
  },

  explodeAs           = [[NOWEAPON]],
  footprintX          = 4,
  footprintZ          = 4,
  highTrajectory      = 1,
  iconType            = [[walkerlrarty]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 2400,
  maxSlope            = 36,
  maxVelocity         = 1.8,
  maxWaterDepth       = 5000,
  movementClass       = [[BHOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB MOBILE STUPIDTARGET MINE]],
  objectName          = [[chickenblobber.s3o]],
  power               = 400,
  reclaimable         = false,
  selfDestructAs      = [[NOWEAPON]],
  

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance       = 1200,
  sonarDistance       = 1200,
  trackOffset         = 6,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 30,
  turnRate            = 1289,
  upright             = false,
  waterline           = 24,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      badTargetCategory  = [[SWIM SHIP HOVER MOBILE]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Scatterblob]],
      areaOfEffect            = 96,
      burst                   = 11,
      burstrate               = 0.033,
      craterBoost             = 0,
      craterMult              = 0,
            
            customParams            = {
        light_radius = 0,
      },

      damage                  = {
        default = 180,
        planes  = 180,
      },

      explosionGenerator      = [[custom:blobber_goo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      mygravity               = 0.1,
      range                   = 1350,
      reloadtime              = 8,
      rgbColor                = [[0.2 0.6 0.0]],
      size                    = 8,
      sizeDecay               = 0,
      soundHit                = [[chickens/acid_hit]],
      soundStart              = [[chickens/acid_fire]],
      sprayAngle              = 1792,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      waterWeapon             = true,
      weaponVelocity          = 350,
    },

  },

} }
