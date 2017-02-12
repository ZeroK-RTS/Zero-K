unitDef = {
  unitname               = [[armrectr]],
  name                   = [[Conjurer]],
  description            = [[Cloaked Construction Bot, Builds at 5 m/s]],
  acceleration           = 0.5,
  activateWhenBuilt      = true,
  brakeRate              = 1.5,
  buildCostEnergy        = 140,
  buildCostMetal         = 140,
  buildDistance          = 128,
  builder                = true,

  buildoptions           = {
  },

  buildPic               = [[ARMRECTR.png]],
  buildTime              = 140,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND UNARMED]],
  cloakCost              = 0.1,
  cloakCostMoving        = 0.5,
  collisionVolumeOffsets = [[0 4 0]],
  collisionVolumeScales  = [[28 40 28]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Getarnter Konstruktionsroboter, Baut mit 5 M/s]],
    description_fr = [[Robot de Construction/Capture, Construit ? 5 m/s]],
    helptext       = [[The Conjurer packs a short-ranged jammer and a cloaking device for stealthy expansion and base maintenance.]],
    helptext_fr    = [[]],
    helptext_de    = [[Der Conjurer besitzt einen Störsender mit kurzer Reichweite und ein Tarngerät, um geheim und unerkannt expandieren zu können.]],
	modelradius    = [[14]],
  },

  energyMake             = 0.15,
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[builder]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  initCloaked            = true,
  leaveTracks            = true,
  maxDamage              = 450,
  maxSlope               = 36,
  maxVelocity            = 1.9,
  maxWaterDepth          = 22,
  metalMake              = 0.15,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  objectName             = [[spherecon.s3o]],
  radarDistanceJam       = 256,
	script                 = [[armrectr.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  showNanoSpray          = false,
  sightDistance          = 375,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 18,
  terraformSpeed         = 300,
  turnRate               = 2200,
  upright                = true,
  workerTime             = 5,

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[spherejeth_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ armrectr = unitDef })
