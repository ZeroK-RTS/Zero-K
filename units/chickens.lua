unitDef = {
  unitname            = [[chickens]],
  name                = [[Spiker]],
  description         = [[Skirmisher]],
  acceleration        = 0.36,
  bmcode              = [[1]],
  brakeRate           = 0.2,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickens.png]],
  buildTime           = 200,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[HOVER]],

  customParams        = {
    description_fr = [[Spike Spitter]],
    helptext       = [[The Spiker's razor sharp projectiles can pierce even the thickest armor. While it doesn't have much health, it remains a potent threat to both air and ground units. Counter with anything that can reliably outrange it.]],
    helptext_fr    = [[The Spiker's razor sharp projectiles can pierce even the thickest armor. While it doesn't have much health, it remains a potent threat to both air and ground units. Counter with anything that can reliably outrange it.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[NOWEAPON]],
  floater             = false,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[chickens]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 87,
  maxDamage           = 600,
  maxSlope            = 36,
  maxVelocity         = 2,
  minCloakDistance    = 75,
  movementClass       = [[BHOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[chickens.s3o]],
  power               = 150,
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
  sightDistance       = 550,
  smoothAnim          = true,
  sonarDistance       = 500,
  steeringmode        = [[2]],
  TEDClass            = [[AKBOT2]],
  trackOffset         = 6,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 30,
  turnRate            = 768,
  upright             = false,
  waterline           = 8,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[FIXEDWING LAND SINK SUB SHIP SWIM FLOAT GUNSHIP HOVER]],
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

      damage                  = {
        default = 160,
        planes  = 160,
        subs    = 7,
      },

      explosionGenerator      = [[custom:EMG_HIT]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      model                   = [[spike.s3o]],
      noSelfDamage            = true,
      propeller               = [[1]],
      range                   = 460,
      reloadtime              = 2,
      renderType              = 1,
      selfprop                = true,
      soundHit                = [[chickens/spike_hit]],
      soundStart              = [[chickens/spike_fire]],
      startVelocity           = 320,
      subMissile              = 1,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 100,
      weaponTimer             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 320,
    },

  },

}

return lowerkeys({ chickens = unitDef })
