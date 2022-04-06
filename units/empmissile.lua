return { empmissile = {
  unitname               = [[empmissile]],
  name                   = [[Shockley]],
  description            = [[EMP missile]],
  buildCostMetal         = 600,
  builder                = false,
  buildPic               = [[empmissile.png]],
  category               = [[SINK UNARMED]],
  collisionVolumeOffsets = [[0 15 0]],
  collisionVolumeScales  = [[20 50 20]],
  collisionVolumeType     = [[CylY]],

  customParams           = {
    mobilebuilding = [[1]],

    outline_x = 55,
    outline_y = 80,
    outline_yoff = 55,
  },

  explodeAs              = [[EMP_WEAPON]],
  footprintX             = 1,
  footprintZ             = 1,
  iconType               = [[cruisemissilesmall]],
  maxDamage              = 1000,
  maxSlope               = 18,
  objectName             = [[wep_empmissile.s3o]],
  script                 = [[cruisemissile.lua]],
  selfDestructAs         = [[EMP_WEAPON]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]]
    },

  },

  sightDistance          = 0,
  useBuildingGroundDecal = false,
  yardMap                = [[o]],

  weapons                = {

    {
      def                = [[EMP_WEAPON]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP SUB]],
    },

  },

  weaponDefs             = {

    EMP_WEAPON = {
      name                    = [[EMP Missile]],
      areaOfEffect            = 280,
      avoidFriendly           = false,
      cegTag                  = [[bigemptrail]],
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      customparams = {
        burst = Shared.BURST_RELIABLE,

        stats_hide_dps = 1, -- one use
        stats_hide_reload = 1,
        
        light_color = [[1.35 1.35 0.36]],
        light_radius = 450,
      },

      damage                  = {
        default = 30002.4,
      },

      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:EMPMISSILE_EXPLOSION]],
      fireStarter             = 0,
      flightTime              = 20,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      model                   = [[wep_empmissile.s3o]],
      paralyzer               = true,
      paralyzeTime            = 45,
      range                   = 3500,
      reloadtime              = 3,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/emp_missile_hit]],
      soundStart              = [[SiloLaunch]],
      tolerance               = 4000,
      tracks                  = false,
      turnrate                = 12000,
      weaponAcceleration      = 180,
      weaponTimer             = 5,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1200,
    },

  },

  featureDefs            = {
  },

} }
