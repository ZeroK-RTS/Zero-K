unitDef = {
  unitname          = [[chicken_digger]],
  name              = [[Digger]],
  description       = [[Burrowing Scout/Raider]],
  acceleration      = 0.36,
  activateWhenBuilt = true,
  brakeRate         = 0.205,
  buildCostEnergy   = 0,
  buildCostMetal    = 0,
  builder           = false,
  buildPic          = [[chicken_digger.png]],
  buildTime         = 40,
  canAttack         = true,
  canGuard          = true,
  canMove           = true,
  canPatrol         = true,
  canstop           = [[1]],
  category          = [[LAND]],

  customParams      = {
    description_fr = [[Taupe Scout/Raider]],
    helptext       = [[The Digger's strong claws can scoop through the hardest rock like gravy. As such, it can burrow and travel underground (very slowly), where the only way to locate it is with sesimic detection equipment.]],
    helptext_fr    = [[Les griffes puissantes du Digger lui permettent de creuser avec facilit? m?me dans les sols les plus durs. Cela lui permet donc de s'enterrer et de creuser des galeries sous terre, bien que tr?s lentement, mais n?cessitant alors pour le localiser un ?quipement de d?tection sismique.]],
  },

  explodeAs         = [[SMALL_UNITEX]],
  fireState         = 1,
  floater           = false,
  footprintX        = 2,
  footprintZ        = 2,
  iconType          = [[chicken]],
  idleAutoHeal      = 20,
  idleTime          = 300,
  leaveTracks       = true,
  mass              = 67,
  maxDamage         = 180,
  maxSlope          = 36,
  maxVelocity       = 1.8,
  maxWaterDepth     = 22,
  minCloakDistance  = 75,
  movementClass     = [[KBOT2]],
  noAutoFire        = false,
  noChaseCategory   = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName        = [[chicken_digger.s3o]],
  onoffable         = true,
  power             = 40,
  seismicSignature  = 4,
  selfDestructAs    = [[SMALL_UNITEX]],

  sfxtypes          = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side              = [[THUNDERBIRDS]],
  sightDistance     = 256,
  smoothAnim        = true,
  TEDClass          = [[KBOT]],
  trackOffset       = 1,
  trackStrength     = 6,
  trackStretch      = 1,
  trackType         = [[ChickenTrack]],
  trackWidth        = 10,
  turnRate          = 806,
  upright           = false,
  waterline         = 8,
  workerTime        = 0,

  weapons           = {

    {
      def                = [[WEAPON]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SUB SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs        = {

    WEAPON = {
      name                    = [[Claws]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 40,
        planes  = 40,
        subs    = 40,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 60,
      reloadtime              = 1.2,
      size                    = 0,
      soundHit                = [[weapon/missile/rocket_hit]],
      soundStart              = [[weapon/hiss]],
      startsmoke              = [[0]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },

}

return lowerkeys({ chicken_digger = unitDef })
