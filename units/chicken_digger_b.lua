unitDef = {
  unitname            = [[chicken_digger_b]],
  name                = [[Digger (burrowed)]],
  description         = [[Burrowing Scout/Raider]],
  acceleration        = 0.26,
  activateWhenBuilt   = false,
  bmcode              = [[1]],
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken_digger.png]],
  buildTime           = 40,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND BURROWED]],

  customParams        = {
	description_fr = [[Taupe Scout/Raider]],
	helptext       = [[The Digger's strong claws can scoop through the hardest rock like gravy. As such, it can burrow and travel underground (very slowly), where the only way to locate it is with sesimic detection equipment.]],
	helptext_fr    = [[Les griffes puissantes du Digger lui permettent de creuser avec facilité même dans les sols les plus durs. Cela lui permet donc de s'enterrer et de creuser des galeries sous terre, bien que très lentement, mais nécessitant alors pour le localiser un équipement de détection sismique.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[SMALL_UNITEX]],
  fireState           = 1,
  floater             = false,
  footprintX          = 1,
  footprintZ          = 1,
  iconType            = [[chicken]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = false,
  maneuverleashlength = [[640]],
  mass                = 99999,
  maxDamage           = 180,
  maxSlope            = 72,
  maxVelocity         = 0.9,
  maxWaterDepth       = 15,
  minCloakDistance    = 75,
  movementClass       = [[TKBOT1]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[chicken_digger_b.s3o]],
  onoffable           = true,
  power               = 40,
  seismicSignature    = 4,
  selfDestructAs      = [[SMALL_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:emg_shells_l]],
      [[custom:flashmuzzle1]],
      [[custom:dirt]],
    },

  },

  side                = [[THUNDERBIRDS]],
  sightDistance       = 0,
  smoothAnim          = true,
  stealth             = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  trackOffset         = 0,
  trackStrength       = 6,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 18,
  turnRate            = 806,
  upright             = false,
  waterline           = 8,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Claws]],
      alphaDecay              = 0.1,
      areaOfEffect            = 8,
      colormap                = [[1 0.95 0.4 1   1 0.95 0.4 1    0 0 0 0.01    1 0.7 0.2 1]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 80,
        planes  = 80,
        subs    = 4,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:EMG_HIT]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noGap                   = false,
      noSelfDamage            = true,
      range                   = 100,
      reloadtime              = 1.2,
      renderType              = 4,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      size                    = 1.75,
      sizeDecay               = 0,
      soundHit                = [[chickens/chickenbig2]],
      soundStart              = [[chickens/chicken]],
      sprayAngle              = 1180,
      stages                  = 10,
      startsmoke              = [[0]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },

}

return lowerkeys({ chicken_digger_b = unitDef })
