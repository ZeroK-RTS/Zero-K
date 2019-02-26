unitDef = {
  unitname            = [[gunshipcon]],
  name                = [[Wasp]],
  description         = [[Heavy Construction Aircraft, Builds at 7.5 m/s]],
  acceleration        = 0.1,
  airStrafe           = 0,
  brakeRate           = 0.08,
  buildCostMetal      = 260,
  buildDistance       = 160,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[GUNSHIPCON.png]],
  buildRange3D        = false,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP UNARMED]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[20 55 55]],
  collisionVolumeType    = [[cylX]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[52 52 52]],
  selectionVolumeType    = [[ellipsoid]],
  collide             = true,
  corpse              = [[DEAD]],
  cruiseAlt           = 80,

  customParams        = {
    airstrafecontrol = [[0]],
	modelradius    = [[15]],
    aimposoffset   = [[0 35 0]],
    midposoffset   = [[0 35 0]],
	custom_height  = [[55]],
  },

  energyUse           = 0,
  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverAttack         = true,
  iconType            = [[builderair]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 600,
  maxVelocity         = 3.1,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[bumblebee.dae]],
  script              = [[gunshipcon.lua]],
  selfDestructAs      = [[GUNSHIPEX]],
  showNanoSpray       = false,
  sightDistance       = 350,
  turnRate            = 500,
  workerTime          = 7.5,

  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[bumblebee_d.dae]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

}

return lowerkeys({ gunshipcon = unitDef })
