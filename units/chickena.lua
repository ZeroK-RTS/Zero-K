return { chickena = {
  unitname            = [[chickena]],
  name                = [[Cockatrice]],
  description         = [[Assault/Anti-Armor]],
  acceleration        = 1.08,
  activateWhenBuilt   = true,
  brakeRate           = 1.23,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickena.png]],
  buildTime           = 350,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND SINK]],

  customParams        = {
    outline_x = 235,
    outline_y = 235,
    outline_yoff = 25,
  },

  explodeAs           = [[NOWEAPON]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[chickena]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 2800,
  maxSlope            = 37,
  maxVelocity         = 1.8,
  maxWaterDepth       = 5000,
  movementClass       = [[AKBOT4]],
  noAutoFire          = false,
  noChaseCategory     = [[SHIP SWIM FLOAT TERRAFORM FIXEDWING SATELLITE GUNSHIP MINE]],
  objectName          = [[chickena.s3o]],
  power               = 420,
  reclaimable         = false,
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance       = 256,
  sonarDistance       = 256,
  trackOffset         = 7,
  trackStrength       = 9,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 34,
  turnRate            = 967,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER SUB SHIP FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {
    WEAPON     = {
      name                    = [[Claws]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1700.1,
      },

      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      noSelfDamage            = true,
      range                   = 140,
      reloadtime              = 7,
      size                    = 0,
      soundHit                = [[chickens/chickenbig2]],
      soundStart              = [[chickens/chickenbig2]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1000,
    },

  },

} }
