unitDef = {
  unitname            = [[chickenblobber]],
  name                = [[Blobber]],
  description         = [[Heavy Artillery]],
  acceleration        = 0.36,
  bmcode              = [[1]],
  brakeRate           = 0.2,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickenblobber.png]],
  buildTime           = 900,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],

  customParams        = {
    description_fr = [[Artillery]],
    helptext       = [[The Lobber's big brother, the Blobber hurls a wide-scatter rain of acid goo. It can pummel even the toughest shield network very quickly, but remains relatively prone to direct attack.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[NOWEAPON]],
  footprintX          = 4,
  footprintZ          = 4,
  highTrajectory      = 1,
  iconType            = [[walkerlrarty]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 616,
  maxDamage           = 2400,
  maxSlope            = 36,
  maxVelocity         = 1.8,
  maxWaterDepth       = 5000,
  minCloakDistance    = 75,
  movementClass       = [[KBOT4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[chickenblobber.s3o]],
  power               = 400,
  seismicSignature    = 4,
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side                = [[THUNDERBIRDS]],
  sightDistance       = 2000,
  smoothAnim          = true,
  sonarDistance       = 450,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  trackOffset         = 6,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 30,
  turnRate            = 768,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      badTargetCategory  = [[SWIM SHIP HOVER]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Scatterblob]],
      areaOfEffect            = 96,
      burst                   = 11,
      burstrate               = 0.01,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 180,
        planes  = 180,
        subs    = 8,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:blobber_goo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      mygravity               = 0.1,
      noSelfDamage            = true,
      range                   = 1250,
      reloadtime              = 8,
      renderType              = 4,
      rgbColor                = [[0.2 0.6 0.0]],
      size                    = 8,
      sizeDecay               = 0,
      soundHit                = [[chickens/acid_hit]],
      soundStart              = [[chickens/acid_fire]],
      sprayAngle              = 1792,
      startsmoke              = [[0]],
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.2,
      weaponType              = [[Cannon]],
      weaponVelocity          = 350,
    },

  },

}

return lowerkeys({ chickenblobber = unitDef })
