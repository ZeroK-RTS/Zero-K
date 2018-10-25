unitDef = {
  unitname            = [[chickens]],
  name                = [[Spiker]],
  description         = [[Skirmisher]],
  acceleration        = 0.36,
  activateWhenBuilt   = true,
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickens.png]],
  buildTime           = 200,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[SWIM]],

  customParams        = {
  },

  explodeAs           = [[NOWEAPON]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[chickens]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 600,
  maxSlope            = 36,
  maxVelocity         = 2,
  minCloakDistance    = 75,
  movementClass       = [[BHOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB STUPIDTARGET]],
  objectName          = [[chickens.s3o]],
  power               = 200,
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance       = 550,
  sonarDistance       = 550,
  trackOffset         = 6,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 30,
  turnRate            = 806,
  upright             = false,
  waterline           = 22,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SUB SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Spike]],
      areaOfEffect            = 16,
      avoidFeature            = true,
      avoidFriendly           = true,
      burnblow                = true,
      cegTag                  = [[small_green_goo]],
      collideFeature          = true,
      collideFriendly         = true,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        light_radius = 0,
      },
      
      damage                  = {
        default = 180,
        planes  = 180,
        subs    = 180,
      },

      explosionGenerator      = [[custom:EMG_HIT]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[spike.s3o]],
      range                   = 460,
      reloadtime              = 3,
      soundHit                = [[chickens/spike_hit]],
      soundStart              = [[chickens/spike_fire]],
      startVelocity           = 320,
      subMissile              = 1,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 100,
      weaponType              = [[Cannon]],
      weaponVelocity          = 280,
    },

  },

}

return lowerkeys({ chickens = unitDef })
