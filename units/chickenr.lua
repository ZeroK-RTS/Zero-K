return { chickenr = {
  unitname            = [[chickenr]],
  name                = [[Lobber]],
  description         = [[Artillery]],
  acceleration        = 1.3,
  activateWhenBuilt   = true,
  brakeRate           = 1.5,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickenr.png]],
  buildTime           = 200,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],

  customParams        = {
    outline_x = 85,
    outline_y = 85,
    outline_yoff = 20,
  },

  explodeAs           = [[NOWEAPON]],
  footprintX          = 2,
  footprintZ          = 2,
  highTrajectory      = 1,
  iconType            = [[chickenr]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 500,
  maxSlope            = 36,
  maxVelocity         = 1.8,
  maxWaterDepth       = 5000,
  movementClass       = [[BHOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB MOBILE STUPIDTARGET MINE]],
  objectName          = [[chickenr.s3o]],
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
  sightDistance       = 1000,
  sonarDistance       = 1000,
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
      name                    = [[Blob]],
      areaOfEffect            = 32,
      craterBoost             = 0,
      craterMult              = 0,
            
            customParams            = {
        light_radius = 0,
      },
            
      damage                  = {
        default = 240,
      },

      explosionGenerator      = [[custom:lobber_goo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      mygravity               = 0.1,
      noSelfDamage            = true,
      range                   = 950,
      reloadtime              = 6,
      rgbColor                = [[0.2 0.6 0.0]],
      size                    = 8,
      sizeDecay               = 0,
      soundHit                = [[chickens/acid_hit]],
      soundStart              = [[chickens/acid_fire]],
      sprayAngle              = 256,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 300,
      waterWeapon             = true,
    },

  },

} }
