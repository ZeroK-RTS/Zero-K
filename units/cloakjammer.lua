return { cloakjammer = {
  unitname               = [[cloakjammer]],
  name                   = [[Iris]],
  description            = [[Area Cloaker/Jammer Walker]],
  acceleration           = 0.75,
  activateWhenBuilt      = true,
  brakeRate              = 4.5,
  buildPic               = [[cloakjammer.png]],
  canMove                = true,
  category               = [[LAND UNARMED]],
  corpse                 = [[DEAD]],

  customParams           = {

    morphto = [[staticjammer]],
    morphtime = 30,

    area_cloak = 1,
    area_cloak_upkeep = 15,
    area_cloak_radius = 350,
    area_cloak_recloak_rate = 800,
    
    priority_misc = 1,
    cus_noflashlight = 1,
  },

  energyUpkeep           = 1.5,
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotjammer]],
  leaveTracks            = true,
  maxDamage              = 600,
  maxSlope               = 36,
  maxVelocity            = 1.8,
  metalCost              = 600,
  minCloakDistance       = 210,
  movementClass          = [[AKBOT2]],
  objectName             = [[spherecloaker.s3o]],
  onoffable              = true,
  pushResistant          = 0,
  script                 = [[cloakjammer.lua]],
  radarDistanceJam       = 350,
  selfDestructAs         = [[BIG_UNITEX]],
  sightDistance          = 400,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 18,
  turnRate               = 2520,

  featureDefs            = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[eraser_d.dae]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

} }
