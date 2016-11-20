unitDef = {
  unitname               = [[corned]],
  name                   = [[Mason]],
  description            = [[Construction Vehicle, Builds at 5 m/s]],
  acceleration           = 0.066,
  brakeRate              = 1.5,
  buildCostEnergy        = 140,
  buildCostMetal         = 140,
  buildDistance          = 180,
  builder                = true,

  buildoptions           = {
  },

  buildPic               = [[corned.png]],
  buildTime              = 140,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canreclamate           = [[1]],
  canstop                = [[1]],
  category               = [[LAND UNARMED]],
  collisionVolumeOffsets = [[0 5 0]],
  collisionVolumeScales  = [[28 28 40]],
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Veículo construtor, constrói a 5 m/s]],
    description_es = [[vehículo para Construcción, construye a 5 m/s]],
    description_fr = [[V?hicule de Construction, Construit ? 5 m/s]],
    description_it = [[Veicolo da Costruzzione, costruisce a 5 m/s]],
	description_de = [[Konstruktionsfahrzeug, Baut mir 5 M/s]],
	description_pl = [[Pojazd konstruktor, moc 5 m/s]],
    helptext       = [[Highly mobile and capable of taking a beating, the Mason can quickly expand over a large area.]],
    helptext_bp    = [[Altamente móvel e capaz de suportar uma boa surra, o veículo de construç?o permite ao jogar expandir rapidamente por uma grande área.]],
    helptext_es    = [[Altamente móbil y capaz de recibir una paliza, el Mason puede ampliar tu territorio sobre una vasta área rápidamente]],
    helptext_fr    = [[Alliant rapidit? et blindage important, le Mason permet de s'?tendre rapidement en s?curit?.]],
    helptext_it    = [[Altamente mobile e capace di prendere parecchi colpi, il Mason pu? rapidamente espandere il tuo territorio in una grande area]],
	helptext_de    = [[Hochmobiles, bewaffnetes Konstruktionsfahrzeug, das sich ideal für schnelle Expansionen über große Flächen eignet.]],
	helptext_pl    = [[Szybki i dosc wytrzymaly, Mason pozwala na szybka ekspansje na duzym obszarze.]],
	modelradius    = [[14]],
  },

  energyMake             = 0.15,
  energyUse              = 0,
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[builder]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 147,
  maxDamage              = 900,
  maxSlope               = 18,
  maxVelocity            = 2.4,
  maxWaterDepth          = 22,
  metalMake              = 0.15,
  minCloakDistance       = 75,
  movementClass          = [[TANK3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[corcv.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  showNanoSpray          = false,
  sightDistance          = 255,
  terraformSpeed         = 300,
  trackOffset            = 3,
  trackStrength          = 6,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 32,
  turninplace            = 0,
  turnRate               = 625,
  workerTime             = 5,

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[DEAD2]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[corcv_dead.s3o]],
    },


    DEAD2 = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3b.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3b.s3o]],
    },

  },

}

return lowerkeys({ corned = unitDef })
