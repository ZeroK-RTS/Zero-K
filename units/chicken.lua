unitDef = {
  unitname            = [[chicken]],
  name                = [[Chicken]],
  description         = [[Swarmer]],
  acceleration        = 0.36,
  activateWhenBuilt   = true,
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken.png]],
  buildTime           = 25,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND SINK]],

  customParams        = {
  },

  explodeAs           = [[NOWEAPON]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[chicken]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 270,
  maxSlope            = 36,
  maxVelocity         = 2.9,
  minCloakDistance    = 75,
  movementClass       = [[AKBOT2]],
  noAutoFire          = false,
  noChaseCategory     = [[SHIP FLOAT SWIM TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[chicken.s3o]],
  power               = 100,
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
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 18,
  turnRate            = 806,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Claws]],
      avoidFeature            = false,
      avoidFriendly           = false,
      collideFeature          = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 80,
        planes  = 80,
        subs    = 80,
      },

      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      range                   = 80,
      reloadtime              = 1.2,
      size                    = 0,
      soundHit                = [[chickens/chickenbig2]],
      soundStart              = [[chickens/chicken]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },

}

return lowerkeys({ chicken = unitDef })
