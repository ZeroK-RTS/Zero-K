return { napalmmissile = {
  unitname                      = [[napalmmissile]],
  name                          = [[Inferno]],
  description                   = [[Napalm Missile]],
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
  },

  explodeAs                     = [[WEAPON]],
  footprintX                    = 1,
  footprintZ                    = 1,
  iconType                      = [[cruisemissilesmall]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 1000,
  maxSlope                      = 18,
  minCloakDistance              = 150,
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
      name                    = [[Napalm Missile]],
      cegTag                  = [[napalmtrail]],
      areaOfEffect            = 512,
      craterAreaOfEffect      = 64,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 4,
      craterMult              = 3.5,

      customParams            = {
        setunitsonfire = "1",
        burntime = 90,

        restrict_in_widgets = 1,

        stats_hide_dps = 1, -- one use
        stats_hide_reload = 1,

        area_damage = 1,
        area_damage_radius = 256,
        area_damage_dps = 20,
        area_damage_duration = 45,
        
        light_color = [[1.35 0.5 0.36]],
        light_radius = 550,
      },

      damage                  = {
        default = 151,
        subs    = 7.5,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:napalm_missile]],
      fireStarter             = 220,
      flightTime              = 100,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      model                   = [[wep_napalm.s3o]],
      noSelfDamage            = true,
      range                   = 3500,
      reloadtime              = 10,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/nalpalm_missile_hit]],
      soundStart              = [[weapon/missile/tacnuke_launch]],
      tolerance               = 4000,
      turnrate                = 18000,
      weaponAcceleration      = 180,
      weaponTimer             = 3,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1200,
    },

  },

  featureDefs                   = {
  },

} }
