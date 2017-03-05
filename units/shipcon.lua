unitDef = {
  unitname               = [[shipcon]],
  name                   = [[Mariner]],
  description            = [[Construction Ship, Builds at 7.5 m/s]],
  acceleration           = 0.051375,
  activateWhenBuilt   = true,
  brakeRate              = 0.061,
  buildCostEnergy        = 220,
  buildCostMetal         = 220,
  buildDistance          = 330,
  builder                = true,

  buildoptions           = {
  },

  buildPic               = [[shipcon.png]],
  buildTime              = 220,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SHIP UNARMED]],
  collisionVolumeOffsets = [[0 8 0]],
  collisionVolumeScales  = [[25 25 96]],

  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Navire de Construction, Construit r 7.5 m/s]],
	description_de = [[Konstruktionsschiff, Baut mit 7,5 M/s]],
    helptext       = [[Although expensive, the Construction Ship boasts extremely high nano power, combined with tough armor and good speed.]],
    helptext_fr    = [[Meme si il est couteux, le Shipcon construit plus vite qu'un constructeur terrestre et est aussi rapide que solide.]],
	helptext_de    = [[Obwohl teuer, bietet diese Konstruktionseinheit extrem hohe Nanoleistung, kombiniert mit robuster Panzerung und Schnelligkeit.]],
	modelradius    = [[40]],
	turnatfullspeed = [[1]],
  },

  energyMake             = 0.225,
  energyUse              = 0,
  explodeAs              = [[SMALL_UNITEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[builder]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 1400,
  maxVelocity            = 2.5,
  metalMake              = 0.225,
  minCloakDistance       = 75,
  minWaterDepth          = 5,
  movementClass          = [[BOAT3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[shipcon.s3o]],
  script                 = [[shipcon.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],
  showNanoSpray          = false,
  sightDistance          = 325,
  sonarDistance          = 325,
  terraformSpeed         = 600,
  turninplace            = 0,
  turnRate               = 508,
  workerTime             = 7.5,

  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[shipcon_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ shipcon = unitDef })
