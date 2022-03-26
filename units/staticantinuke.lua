return { staticantinuke = {
  unitname                      = [[staticantinuke]],
  name                          = [[Antinuke]],
  description                   = [[Strategic Nuke Interception System]],
  activateWhenBuilt             = true,
  buildCostMetal                = 3000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[antinuke_decal.dds]],
  buildPic                      = [[staticantinuke.png]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[70 55 110]],
  collisionVolumeType           = [[box]],
  selectionVolumeOffsets        = [[0 0 0]],
  selectionVolumeScales         = [[70 55 110]],
  selectionVolumeType           = [[box]],
  corpse                        = [[DEAD]],

  customParams                  = {
    removewait     = 1,
    removestop     = 1,
    nuke_coverage  = 2500,
    modelradius      = [[50]],
    selectionscalemult = 1,

    outline_x = 185,
    outline_y = 185,
    outline_yoff = 25,
  },

  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 5,
  footprintZ                    = 8,
  iconType                      = [[antinuke]],
  levelGround                   = false,
  maxDamage                     = 3300,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  objectName                    = [[staticantinuke.s3o]],
  radarDistance                 = 2500,
  radarEmitHeight               = 24,
  script                        = [[staticantinuke.lua]],
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  sightDistance                 = 660,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardmap                       = [[oooooooooooooooooooooooooooooooooooooooo]],

  weapons                       = {

    {
      def = [[AMD_ROCKET]],
    },

  },


  weaponDefs                    = {

    AMD_ROCKET = {
      name                    = [[Anti-Nuke Missile Fake]],
      areaOfEffect            = 420,
      avoidFriendly           = false,
      avoidGround             = false,
      avoidFeature           = false,
      collideFriendly         = false,
      collideGround           = false,
      collideFeature          = false,
      coverage                = 100000,
      craterBoost             = 1,
      craterMult              = 2,
      
      customParams            = {
        reaim_time = 15,
        nuke_coverage = 2500,
      },
      
      damage                  = {
        default = 1500,
      },

      --spawning the intercept explosion is handled by exp_nuke_effect_chooser.lua
      explosionGenerator      = [[custom:lrpc_expl]],
      fireStarter             = 100,
      flightTime              = 20,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      interceptor             = 1,
      model                   = [[staticantinuke_projectile.s3o]],
      noSelfDamage            = true,
      range                   = 3800,
      reloadtime              = 6,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/missile_launch]],
      startVelocity           = 400,
      tolerance               = 4000,
      tracks                  = true,
      turnrate                = 65535,
      weaponAcceleration      = 800,
      weaponTimer             = 0.4,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1600,
    },

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 8,
      object           = [[staticantinuke_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 5,
      footprintZ       = 8,
      object           = [[debris4x4a.s3o]],
    },

  },

} }
