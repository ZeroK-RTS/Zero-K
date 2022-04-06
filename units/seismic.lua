return { seismic = {
  unitname                      = [[seismic]],
  name                          = [[Quake]],
  description                   = [[Seismic Missile]],
  buildCostMetal                = 400,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 3,
  buildingGroundDecalSizeY      = 3,
  buildingGroundDecalType       = [[seismic_aoplane.dds]],
  buildPic                      = [[seismic.png]],
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 15 0]],
  collisionVolumeScales         = [[20 50 20]],
  collisionVolumeType           = [[CylY]],

  customParams                  = {
    mobilebuilding = [[1]],

    outline_x = 55,
    outline_y = 80,
    outline_yoff = 55,
  },

  explodeAs                     = [[SEISMIC_WEAPON]],
  footprintX                    = 1,
  footprintZ                    = 1,
  iconType                      = [[cruisemissilesmall]],
  maxDamage                     = 1000,
  maxSlope                      = 18,
  objectName                    = [[wep_seismic.s3o]],
  script                        = [[cruisemissile.lua]],
  selfDestructAs                = [[SEISMIC_WEAPON]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
    },

  },

  sightDistance                 = 0,
  useBuildingGroundDecal        = false,
  yardMap                       = [[o]],

  weapons                       = {

    {
      def                = [[SEISMIC_WEAPON]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },

  weaponDefs                    = {

    SEISMIC_WEAPON = {
      name                    = [[Seismic Missile]],
      areaOfEffect            = 640,
      avoidFriendly           = false,
      cegTag                  = [[seismictrail]],
      collideFriendly         = false,
      craterBoost             = 32,
      craterMult              = 1,

      customParams            = {
        gatherradius = [[416]],
        smoothradius = [[320]],
        detachmentradius = [[320]],
        smoothmult   = [[1]],
        smoothexponent = [[0.45]],
        movestructures = [[1]],

        stats_hide_dps = 1, -- one use
        stats_hide_reload = 1,
        
        light_color = [[1.2 1.6 0.55]],
        light_radius = 550,
      },
      
      damage                  = {
        default = 20,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:bull_fade]],
      fireStarter             = 0,
      flightTime              = 100,
      interceptedByShieldType = 1,
      model                   = [[wep_seismic.s3o]],
      noSelfDamage            = true,
      range                   = 6000,
      reloadtime              = 10,
      smokeTrail              = false,
      soundHit                = [[explosion/ex_large4]],
      soundStart              = [[SiloLaunch]],
      tolerance               = 4000,
      turnrate                = 18000,
      waterWeapon             = true,
      weaponAcceleration      = 180,
      weaponTimer             = 3,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1200,
    },

  },

  featureDefs                   = {
  },

} }
