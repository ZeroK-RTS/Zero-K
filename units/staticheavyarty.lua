return { staticheavyarty = {
  name                          = [[Big Bertha]],
  description                   = [[Strategic Plasma Cannon]],
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[staticheavyarty_aoplane.dds]],
  buildPic                      = [[staticheavyarty.png]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 -7]],
  collisionVolumeScales         = [[65 194 65]],
  collisionVolumeType           = [[cylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    neededlink     = 50,
    pylonrange     = 50,
    keeptooltip    = [[any string I want]],

    bait_level_default = 1,
    want_proximity_targetting = 1,
    aimposoffset = [[0 50 -7]],
    modelradius    = [[35]],
    selectionscalemult = 1,

    outline_x = 270,
    outline_y = 270,
    outline_yoff = 90,
  },

  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 4,
  footprintZ                    = 4,
  health                        = 4800,
  iconType                      = [[lrpc]],
  levelGround                   = false,
  maxSlope                      = 18,
  maxWaterDepth                 = 0,
  metalCost                     = 6000,
  noChaseCategory               = [[FIXEDWING LAND SHIP SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[armbrtha.s3o]],
  script                        = [[staticheavyarty.lua]],
  selfDestructAs                = [[ATOMIC_BLAST]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:staticheavyarty_SHOCKWAVE]],
      [[custom:staticheavyarty_SMOKE]],
      [[custom:staticheavyarty_FLARE]],
    },

  },

  sightEmitHeight               = 90,
  sightDistance                 = 660,
  useBuildingGroundDecal        = true,
  yardMap                       = [[oooo oooo oooo oooo]],

  weapons                       = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[GUNSHIP LAND SHIP HOVER SWIM]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

  },

  weaponDefs                    = {

    PLASMA = {
      name                    = [[Very Heavy Plasma Cannon]],
      accuracy                = 500,
      areaOfEffect            = 176,
      avoidFeature            = false,
      cegTag                  = [[vulcanfx]],
      craterBoost             = 0.25,
      craterMult              = 0.5,

      customParams            = {
        gatherradius     = [[240]],
        smoothradius     = [[120]],
        smoothmult       = [[0.5]],
        movestructures   = [[0.25]],
        force_ignore_ground = "1",
        
        light_color = [[2.4 1.5 0.6]],
      },
      
      damage                  = {
        default = 2002.4,
      },

      explosionGenerator      = [[custom:lrpc_expl]],
      fireTolerance           = 1820, -- 10 degrees
      impulseBoost            = 0.5,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 5600,
      reloadtime              = 8,
      soundHit                = [[weapon/cannon/lrpc_hit]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/cannon/big_bertha_gun_fire2]],
      soundStartVolume        = 8,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1050,
    },

  },

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      collisionVolumeOffsets        = [[0 0 -7]],
      collisionVolumeScales         = [[65 194 65]],
      collisionVolumeType           = [[cylY]],
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[armbrtha_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
