unitDef = {
  unitname            = [[armasp]],
  name                = [[Air Repair/Rearm Pad]],
  description         = [[Repairs and Rearms Aircraft, repairs at 2.5 e/s per pad]],
  acceleration        = 0,
  activateWhenBuilt   = true,
  brakeRate           = 0,
  buildCostEnergy     = 350,
  buildCostMetal      = 350,
  buildDistance       = 6,
  builder             = true,
  buildPic            = [[ARMASP.png]],
  buildTime           = 350,
  canMove             = true,
  canAttack           = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[UNARMED FLOAT]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[130 40 130]],
  collisionVolumeType    = [[box]],
  corpse              = [[DEAD]],

  customParams        = {
    pad_count = 4,
    description_de = [[Repariert automatisch eigene/verbündete Lufteinheiten, jedes Pad repariert mit 2.5 e/s]],
    helptext       = [[The Air Repair/Rearm Pad repairs up to four aircraft at a time. It also refuels/rearms bombers.]],
    helptext_de    = [[Das Air Repair/Rearm Pad repariert bis zu vier Flugzeuge gleichzeitig. Es befüllt und betankt außerdem die Bomber.]],
	nobuildpower   = 1,
	notreallyafactory = 1,
  },

  explodeAs           = [[LARGE_BUILDINGEX]],
  footprintX          = 9,
  footprintZ          = 9,
  iconType            = [[building]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 1860,
  maxSlope            = 18,
  maxVelocity         = 0,
  minCloakDistance    = 150,
  objectName          = [[airpad.s3o]],
  script			  = [[armasp.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[LARGE_BUILDINGEX]],
  showNanoSpray       = false,
  sightDistance       = 273,
  turnRate            = 0,
  waterline           = 8,
  workerTime          = 10,
  yardMap             = [[ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo]],

  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 9,
      footprintZ       = 9,
      object           = [[airpad_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 1,
      footprintZ       = 1,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ armasp = unitDef })
