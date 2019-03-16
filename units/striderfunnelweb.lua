unitDef = {
  unitname               = [[striderfunnelweb]],
  name                   = [[Funnelweb]],
  description            = [[Shield Support Strider]],
  acceleration           = 0.0552,
  activateWhenBuilt      = true,
  brakeRate              = 0.1375,
  buildCostMetal         = 3500,
  buildPic               = [[striderfunnelweb.png]],
  builder                = true,
  
  buildoptions        = {
  },

  buildDistance          = 400,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND UNARMED]],
  corpse                 = [[DEAD]],

  customParams           = {
	priority_misc  = 1, -- Medium
	shield_emit_height = 45,
	unarmed       = true,
	shield_power_gfx_override = 10000,
	selection_rank = 3,
  },

  explodeAs              = [[ESTOR_BUILDING]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3special]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 6000,
  maxSlope               = 36,
  maxVelocity            = 1.8,
  maxWaterDepth          = 22,
  minCloakDistance       = 150,
  movementClass          = [[TKBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[funnelweb.s3o]],
  radarDistance          = 1400,
  radarEmitHeight        = 32,
  onoffable              = true,
  selfDestructAs         = [[ESTOR_BUILDING]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:emg_shells_l]],
      [[custom:flashmuzzle1]],
    },

  },
  script                 = [[striderfunnelweb.lua]],
  showNanoSpray          = false,
  sightDistance          = 650,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 85,
  turnRate               = 240,
  workerTime             = 40,

  weapons                = {

    {
      def                = [[SHIELD]],
    },

  },


  weaponDefs             = {

    SHIELD = {
      name                    = [[Energy Shield]],

      damage                  = {
        default = 10,
      },
      customParams            = {
        unlinked                = true,
        shield_recharge_delay   = 10,
      },

      exteriorShield          = true,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[1 0.1 0.1 1]],
      shieldGoodColor         = [[0.1 0.1 1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 28000,
      shieldPowerRegen        = 200,
      shieldPowerRegenEnergy  = 48,
      shieldRadius            = 550,
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
