unitDef = {
  unitname               = [[striderfunnelweb]],
  name                   = [[Funnelweb]],
  description            = [[Drone/Shield Support Strider]],
  acceleration           = 0.0552,
  activateWhenBuilt      = true,
  brakeRate              = 0.1375,
  buildCostMetal         = 4500,
  buildPic               = [[striderfunnelweb.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
	priority_misc  = 1, -- Medium
	shield_emit_height = 45,
  },

  explodeAs              = [[ESTOR_BUILDING]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3special]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 11000,
  maxSlope               = 36,
  maxVelocity            = 1.5,
  maxWaterDepth          = 22,
  minCloakDistance       = 150,
  movementClass          = [[TKBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[funnelweb.s3o]],
  onoffable              = true,
  selfDestructAs         = [[ESTOR_BUILDING]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:emg_shells_l]],
      [[custom:flashmuzzle1]],
    },

  },
  script                 = [[striderfunnelweb.lua]],
  sightDistance          = 650,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 85,
  turnRate               = 240,
  workerTime             = 0,

  weapons                = {

    {
      def                = "BOGUS_FAKE_TARGETER",
      badTargetCategory  = "FIXEDWING",
      onlyTargetCategory = "FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER",
    },

    {
      def                = [[SHIELD]],
    },

  },


  weaponDefs             = {

    BOGUS_FAKE_TARGETER = {
      name                    = [[Bogus Fake Targeter]],
      avoidGround             = false, -- avoid nothing, else attempts to move out to clear line of fine
      avoidFriendly           = false,
      avoidFeature            = false,
      avoidNeutral            = false,

      damage                  = {
        default = 11.34,
        planes  = 11.34,
        subs    = 0.567,
      },

      explosionGenerator      = [[custom:FLASHPLOSION]],
      noSelfDamage            = true,
      range                   = 800,
      reloadtime              = 1,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 500,
    },
	
    SHIELD = {
      name                    = [[Energy Shield]],

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[1 0.1 0.1 1]],
      shieldGoodColor         = [[0.1 0.1 1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 3600,
      shieldPowerRegen        = 50,
      shieldPowerRegenEnergy  = 12,
      shieldRadius            = 350,
      shieldRepulser          = false,
      smartShield             = true,
      visibleShield           = false,
      visibleShieldRepulse    = false,
      weaponType              = [[Shield]],
    },
	
  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[funnelweb_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ striderfunnelweb = unitDef })
