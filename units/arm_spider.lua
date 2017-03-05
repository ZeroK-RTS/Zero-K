unitDef = {
  unitname               = [[arm_spider]],
  name                   = [[Weaver]],
  description            = [[Construction Spider, Builds at 7.5 m/s]],
  acceleration           = 0.2,
  activateWhenBuilt      = true,
  brakeRate              = 0.6,
  buildCostEnergy        = 200,
  buildCostMetal         = 200,
  buildDistance          = 220,
  builder                = true,

  buildoptions           = {
  },

  buildPic               = [[arm_spider.png]],
  buildTime              = 200,
  canAttack              = false,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND UNARMED]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[30 30 30]],
  collisionVolumeType    = [[ellipsoid]], 
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Konstruktionsspinne, Baut mit 7.5 M/s]],
    description_fr = [[Araignée de Construction, construit à 7.5 m/s]],
    helptext       = [[The Weaver is a constructor that can climb over any obstacle and build defenses on high ground. It is also equipped with a short range radar.]],
    helptext_de    = [[Der Weaver ist eine bauende Einheit, die Hindernisse überwinden und somit Verteidigungsanlagen auf Erhöhungen bauen kann. Er hat auch ein Radar.]],
    helptext_fr    = [[Le Weaver est un robot de construction arachnide tout terrain pouvant atteindre des zones élevées. Il a un radar.]],
	modelradius    = [[15]],
  },

  energyMake             = 0.225,
  energyUse              = 0,
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[builder]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 820,
  maxSlope               = 72,
  maxVelocity            = 1.8,
  maxWaterDepth          = 22,
  metalMake              = 0.225,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT3]],
  objectName             = [[weaver.s3o]],
  radarDistance          = 1200,
  radarEmitHeight        = 12,
  script                 = [[arm_spider.lua]],
  selfDestructAs         = [[BIG_UNITEX]],
  showNanoSpray          = false,
  sightDistance          = 380,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShort]],
  trackWidth             = 54,
  terraformSpeed         = 450,
  turnRate               = 1400,
  workerTime             = 7.5,

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[weaver_wreck.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3b.s3o]],
    },

  },

}

return lowerkeys({ arm_spider = unitDef })
