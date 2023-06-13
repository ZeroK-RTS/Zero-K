return { staticcon = {
  unitname                      = [[staticcon]],
  name                          = [[Caretaker]],
  description                   = [[Construction Assistant]],
  buildCostMetal                = 180,
  buildDistance                 = 500,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[staticcon_aoplane.dds]],
  buildPic                      = [[staticcon.png]],
  canGuard                      = true,
  canMove                       = false,
  canPatrol                     = true,
  cantBeTransported             = true,
  category                      = [[FLOAT UNARMED]],
  collisionVolumeOffsets        = [[0 4 0]],
  collisionVolumeScales         = [[48 56 48]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    aimposoffset     = [[0 18 0]],
    midposoffset     = [[0 -4 0]],
    modelradius      = [[24]],
    default_spacing  = 1,
    like_structure   = 1,
    select_show_eco  = 1,

    outline_x = 80,
    outline_y = 85,
    outline_yoff = 13.5,
  },

  explodeAs                     = [[NANOBOOM2]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[staticbuilder]],
  levelGround                   = false,
  maxDamage                     = 500,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  movementClass                 = [[KBOT2]],
  objectName                    = [[armsenan.s3o]],
  script                        = [[staticcon.lua]],
  selfDestructAs                = [[NANOBOOM2]],
  showNanoSpray                 = false,
  sightDistance                 = 380,
  upright                       = true,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,

  featureDefs                   = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[armsenan_dead.dae]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4a.s3o]],
    },

  },

    weaponDefs = {
        NANOBOOM2 = {
            name = "Nano Explosion",
            areaofeffect = 128,
            craterboost = 1,
            cratermult = 3.5,
            edgeeffectiveness = 0.75,
            explosiongenerator = [[custom:FLASH1]],
            impulseboost = 0,
            impulsefactor = 0.4,
            soundhit = [[explosion/ex_small1]],

            damage = {
                default = 500,
            },
        },
    },
} }
