unitDef = {
  unitname            = [[shieldfelon]],
  name                = [[Felon]],
  description         = [[Shielded Riot/Skirmisher Bot]],
  acceleration        = 0.25,
  activateWhenBuilt   = true,
  brakeRate           = 0.22,
  buildCostMetal      = 620,
  buildPic            = [[shieldfelon.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
	shield_emit_height = 25,
	shield_color_mult = 1.1,
	dontfireatradarcommand = '1',
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[walkersupport]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  losEmitHeight       = 40,
  maxDamage           = 1400,
  maxSlope            = 36,
  maxVelocity         = 1.5,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT3]],
  noChaseCategory     = [[TERRAFORM FIXEDWING SUB]],
  objectName          = [[shieldfelon.s3o]],
  onoffable           = false,
  script              = [[shieldfelon.lua]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:lightningplosion_smallbolts_purple]],
    },

  },

  sightDistance       = 520,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 30,
  turnRate            = 1000,
  upright             = true,

  weapons             = {
    {
      def                = [[SHIELDGUN]],
      badTargetCategory  = [[UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
	  --mainDir            = [[0 1 0]],
	  --maxAngleDif        = 270,
    },
    {
      def = [[SHIELD]],
    },
  },

  weaponDefs          = {

    SHIELD      = {
      name                    = [[Energy Shield]],

      damage                  = {
        default = 9.79,
      },

      exteriorShield          = true,
      shieldAlpha             = 0.4,
      shieldBadColor          = [[1 0.1 0.1 1]],
      shieldGoodColor         = [[0.1 0.1 1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 1600,
      shieldPowerRegen        = 18,
      shieldPowerRegenEnergy  = 0,
      shieldRadius            = 120,
      shieldRepulser          = false,
      shieldStartingPower     = 1066,
      smartShield             = true,
      visibleShield           = false,
      visibleShieldRepulse    = false,
      weaponType              = [[Shield]],
    },

    SHIELDGUN = {
      name                    = [[Shield Gun]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 0,

      customParams            = {
        shield_drain = 75,
		
		light_camera_height = 2500,
		light_color = [[0.66 0.32 0.90]],
		light_radius = 120,
      },

      damage                  = {
        default        = 108.4,
      },

      explosionGenerator      = [[custom:flash2purple]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 6,
      interceptedByShieldType = 1,
      range                   = 435,
      reloadtime              = 0.15,
      rgbColor                = [[0.5 0 0.7]],
      soundStart              = [[weapon/constant_electric]],
      soundStartVolume        = 9,
      soundTrigger            = true,
      texture1                = [[corelaser]],
      thickness               = 2,
      turret                  = true,
      weaponType              = [[LightningCannon]],
    },

  },

  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[shieldfelon_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ shieldfelon = unitDef })
