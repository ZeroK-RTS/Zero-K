return { striderfunnelweb = {
  name                   = [[Funnelweb]],
  description            = [[Shield Support Strider]],
  acceleration           = 0.166,
  activateWhenBuilt      = true,
  brakeRate              = 0.825,
  buildPic               = [[striderfunnelweb.png]],
  builder                = true,
  
  buildoptions        = {
  },

  buildDistance          = 400,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND UNARMED]],
  collisionVolumeOffsets        = [[0 10 -10]],
  collisionVolumeScales         = [[60 50 80]],
  collisionVolumeType           = [[elipsoid]],
  selectionVolumeOffsets        = [[0 0 0]],
  selectionVolumeScales         = [[120 120 120]],
  selectionVolumeType           = [[Sphere]],

  corpse                 = [[DEAD]],

  customParams           = {
    modelradius    = [[50]],
    priority_misc  = 1, -- Medium
    shield_emit_height = 45,
    unarmed       = true,
    shield_power_gfx_override = 10000,
    selection_rank = 3,
    disable_radar_preview = 1,
    selection_scale = 1.36,

    outline_x = 160,
    outline_y = 160,
    outline_yoff = 25,
  },

  explodeAs              = [[ESTOR_BUILDING]],
  footprintX             = 4,
  footprintZ             = 4,
  health                 = 4500,
  iconType               = [[t3spiderbuilder]],
  leaveTracks            = true,
  maxSlope               = 36,
  maxWaterDepth          = 22,
  metalCost              = 4000,
  movementClass          = [[TKBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[funnelweb.dae]],
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
  speed                  = 41,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 85,
  turnRate               = 624,
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
      shieldPower             = 19400,
      shieldPowerRegen        = 300,
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

} }
