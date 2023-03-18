return { missileslow = {
  unitname                      = [[missileslow]],
  name                          = [[Tortise]],
  description                   = [[Homing Slow Missile - High single-target damage followed by lingering slow]],
  buildCostMetal                = 500,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 3,
  buildingGroundDecalSizeY      = 3,
  buildingGroundDecalType       = [[napalmmissile_aoplane.dds]],
  buildPic                      = [[napalmmissile.png]],
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 15 0]],
  collisionVolumeScales         = [[20 60 20]],
  collisionVolumeType            = [[CylY]],

  customParams                  = {
    mobilebuilding = [[1]],

    outline_x = 55,
    outline_y = 80,
    outline_yoff = 55,
  },

  explodeAs                     = [[WEAPON]],
  footprintX                    = 1,
  footprintZ                    = 1,
  iconType                      = [[cruisemissilesmall]],
  maxDamage                     = 1000,
  maxSlope                      = 18,
  objectName                    = [[wep_napalm.s3o]],
  script                        = [[cruisemissile.lua]],
  selfDestructAs                = [[WEAPON]],

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
      def                = [[WEAPON]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

  },

  weaponDefs                    = {

    WEAPON = {
      name                    = [[Slow Missile]],
      cegTag                  = [[beamweapon_muzzle_purple]],
      avoidFriendly           = false,
      collideFriendly         = false,

      customParams            = {
        timeslow_onlyslow = 1,
        
        light_color = [[0.6 0.22 0.8]],
        light_radius = 550,

        stats_hide_dps = 1, -- one use
        stats_hide_reload = 1,
        stats_aoe = 0,

        area_damage = 1,
        area_damage_radius = 384,
        area_damage_dps = 200,
        area_damage_duration = 30,
        area_damage_update_mult = 5,
        area_damage_is_slow = "1",

        gui_aoe = 384,
        gui_ee = 0.4,
      },

      damage                  = {
        default = 10000,
      },

      explosionGenerator      = [[custom:purple_missile]],
      flightTime              = 100,
      impulseBoost            = 0,
      impulseFactor           = 0,
      impactOnly              = true,
      interceptedByShieldType = 1,
      model                   = [[wep_napalm.s3o]],
      noSelfDamage            = true,
      range                   = 6000,
      reloadtime              = 10,
      smokeTrail              = false,
      soundHit                = [[weapon/aoe_aura2]],
      soundHitVolume          = 15,
      soundStart              = [[SiloLaunch]],
      tolerance               = 4000,
      tracks                  = true,
      turnrate                = 12000,
      weaponAcceleration      = 60,
      weaponTimer             = 6,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 480,
    },
  },

  featureDefs                   = {
  },

} }
