unitDef = {
  unitname               = [[factoryship]],
  name                   = [[Shipyard]],
  description            = [[Produces Ships, Builds at 10 m/s]],
  acceleration           = 0,
  brakeRate              = 0,
  buildCostEnergy        = 600,
  buildCostMetal         = 600,
  builder                = true,

  buildoptions           = {
    [[shipcon]],
    [[shipscout]],
    [[subraider]],
    [[shipraider]],
    [[shiptorp]],
    [[shipskirm]],
    [[shiparty]],
    [[subarty]],
    [[shipaa]],
    [[armtboat]],
  },

  buildPic               = [[FACTORYSHIP.png]],
  buildTime              = 600,
  canAttack              = true,
  canMove                = true,
  canPatrol              = true,
  canStop                = true,
  category               = [[UNARMED FLOAT]],
  collisionVolumeOffsets = [[-15 -20 -15]],
  collisionVolumeScales  = [[120 120 160]],
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Produziert Schiffe, Baut mit 10 M/s]],
    description_pl = [[Stocznia, moc 10 m/s]],
	helptext       = [[Shipyard is where both ships and submarines are built. Other waterborne units such as hovercraft and amphibious bots have separate factories.]],
	helptext_de    = [[Im Shipyard kannst du Schiffe jeder Art und für jeden Zweck bauen.]],
	helptext_pl    = [[Stocznia produkuje statki i lodzie podwodne; poduszkowce i boty amfibijne maja osobne fabryki.]],
    sortName       = [[7]],
	unstick_help   = 1,
  },

  energyMake             = 0.3,
  energyUse              = 0,
  explodeAs              = [[LARGE_BUILDINGEX]],
  footprintX             = 9,
  footprintZ             = 14,
  iconType               = [[facship]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 324,
  maxDamage              = 6000,
  maxSlope               = 15,
  maxVelocity            = 0,
  metalMake              = 0.3,
  minCloakDistance       = 150,
  minWaterDepth          = 15,
  objectName             = [[seafac.s3o]],
  script				 = [[factoryship.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[LARGE_BUILDINGEX]],
  showNanoSpray          = false,
  side                   = [[CORE]],
  sightDistance          = 273,
  turnRate               = 0,
  waterline              = 0,
  workerTime             = 10,
  yardMap                = [[yyyyyyyyy yoooooooy yoooooooy yooccccoy yooccccoy yooccccoy yooccccoy yooccccoy yooccccoy yooccccoy yooccccoy yooccccoy yocccccoy yocccccoy]],

  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 9,
      footprintZ       = 14,
      object           = [[seafac_dead.s3o]],
    },



    HEAP  = {
      blocking         = false,
      footprintX       = 8,
      footprintZ       = 8,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ factoryship = unitDef })
