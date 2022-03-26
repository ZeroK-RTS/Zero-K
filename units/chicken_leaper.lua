return { chicken_leaper = {
  unitname            = [[chicken_leaper]],
  name                = [[Leaper]],
  description         = [[Hopping Raider]],
  acceleration        = 1.5,
  brakeRate           = 1.23,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken_leaper.png]],
  buildTime           = 100,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],

  customParams        = {
    outline_x = 145,
    outline_y = 145,
    outline_yoff = 17.5,
  },

  explodeAs           = [[NOWEAPON]],
  floater             = false,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[chickenleaper]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = false,
  maxDamage           = 720,
  maxSlope            = 36,
  maxVelocity         = 4,
  movementClass       = [[AKBOT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[chicken_leaper.s3o]],
  power               = 100,
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
  turnRate            = 1920,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Kick]],
      areaOfEffect            = 8,
      avoidFriendly           = true,
      burst                   = 5,
      burstrate               = 0.033,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 50,
        planes  = 50,
      },

      duration                = 0.0333,
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 8000,
      impulseFactor           = 1,
      intensity               = 0,
      interceptedByShieldType = 0,
      noSelfDamage            = true,
      range                   = 100,
      reloadtime              = 1,
      rgbColor                = [[0 0 0]],
      rgbColor2               = [[0 0 0]],
      size                    = 0,
      soundStart              = [[weapon/missile/rocket_hit]],
      soundTrigger            = true,
      thickness               = 0,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 3000,
    },

  },

} }
