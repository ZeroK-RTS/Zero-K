unitDef = {
  unitname            = [[planelightscout]],
  name                = [[Sparrow]],
  description         = [[Light Scout Plane]],
  brakerate           = 0.4,
  buildCostMetal      = 120,
  builder             = false,
  buildPic            = [[planelightscout.png]],
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[UNARMED FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[14 14 45]],
  collisionVolumeType    = [[cylZ]],
  corpse              = [[DEAD]],
  cruiseAlt           = 220,

  customParams        = {
    modelradius    = [[8]],
    refuelturnradius = [[160]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[scoutplane]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxAcc              = 0.5,
  maxDamage           = 400,
  maxAileron          = 0.018,
  maxElevator         = 0.02,
  maxRudder           = 0.008,
  maxVelocity         = 7.5,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[fairlight.s3o]],
  script              = [[planelightscout.lua]],
  selfDestructAs      = [[GUNSHIPEX]],
  sightDistance       = 950,
  turnRadius          = 70,
  workerTime          = 0,

  featureDefs         = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

}

return lowerkeys({ planelightscout = unitDef })
