unitDef = {
  unitname                      = [[striderhub]],
  name                          = [[Strider Hub]],
  description                   = [[Constructs Striders, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 1.5,
  buildCostMetal                = 600,
  buildDistance                 = 300,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[armnanotc_aoplane.dds]],

  buildoptions                  = {
    [[armcomdgun]],
	[[scorpion]],
    [[dante]],
    [[armraven]],
    [[funnelweb]],
    [[armbanth]],
    [[armorco]],
    [[shipheavyarty]],
	[[shipcarrier]],
	[[subtacmissile]],
  },

  buildPic                      = [[striderhub.png]],
  canGuard                      = true,
  canMove                       = false,
  canPatrol                     = true,
  canstop                       = [[1]],
  cantBeTransported             = true,
  category                      = [[FLOAT UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[70 70 70]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Erzeugt Strider, Baut mit 10 M/s]],
    helptext       = [[The Strider Hub deploys striders, the "humongous mecha" that inspire awe and fear on the battlefield. Unlike a normal factory, the hub is only required to start a project, not to finish it.]],
	helptext_de    = [[Das Strider Hub erzeugt Strider, welche sehr gefürchtet sind auf dem Schlachtfeld. Anders als normale Fabriken, wird dieser Hub nur benötigt, um ein Projekt zu starten, nicht, um es zu vollenden.]],
	aimposoffset   = [[0 0 0]],
	midposoffset   = [[0 -10 0]],
	modelradius    = [[35]],
	isfakefactory  = [[1]],
  },

  explodeAs                     = [[ESTOR_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 4,
  footprintZ                    = 4,
  iconType                      = [[t3hub]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  maneuverleashlength           = [[380]],
  maxDamage                     = 2000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  movementClass                 = [[KBOT4]],
  noAutoFire                    = false,
  objectName                    = [[striderhub.s3o]],
  script                        = [[striderhub.lua]],
  selfDestructAs                = [[ESTOR_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 380,
  turnRate                      = 1,
  upright                       = true,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,

  featureDefs                   = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[striderhub_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ striderhub = unitDef })
