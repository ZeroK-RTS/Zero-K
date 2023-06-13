return { wolverine_mine = {
  unitname               = [[wolverine_mine]],
  name                   = [[Claw]],
  description            = [[Badger Mine]],
  activateWhenBuilt      = false,
  buildCostMetal         = 5,
  builder                = false,
  buildPic               = [[wolverine_mine.png]],
  canGuard               = false,
  canMove                = false,
  canPatrol              = false,
  category               = [[FLOAT MINE STUPIDTARGET]],
  cloakCost              = 0,
  collisionVolumeOffsets = [[0 -4 0]],
  collisionVolumeScales  = [[20 20 20]],
  collisionVolumeType    = [[ellipsoid]],

  customParams           = {
    bait_level_default = 0,
    bait_level_target  = 1, -- Just for safety.
    dontcount = [[1]],
    mobilebuilding = [[1]],
    idle_cloak = 1,
    has_parent_unit = 1,
  },

  explodeAs              = [[NOWEAPON]],
  footprintX             = 1,
  footprintZ             = 1,
  levelGround            = false,
  iconType               = [[mine]],
  idleAutoHeal           = 10,
  idleTime               = 300,
  initCloaked            = true,
  maxDamage              = 40,
  maxSlope               = 255,
  maxVelocity            = 0,
  minCloakDistance       = 80,
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[claw.s3o]],
  onoffable              = false,
  reclaimable            = false,
  repairable             = false, -- mostly not to waste constructor attention on area-repair; has regen anyway
  script                 = [[wolverine_mine.lua]],
  selfDestructAs         = [[NOWEAPON]],
  selfDestructCountdown  = 0,
  sightDistance          = 120,
  stealth                = true,
  waterline              = 1,
  workerTime             = 0,
  yardMap                = [[y]],

  weapons                = {

    {
      def                = [[BOMBLET]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER GUNSHIP]],
    },

  },


  weaponDefs             = {

    BOMBLET = {
      name                    = [[Bomblet]],
      areaOfEffect            = 16,
      burst                   = 5,
      burstrate               = 0.033,
      craterBoost             = 0,
      craterMult              = 0,

      customparams = {
        stats_hide_dps = 1, -- one use
        stats_hide_reload = 1,

        light_camera_height = 1600,
        light_color = [[0.45 0.26 0.068]],
        light_radius = 180,
      },
      
      damage                  = {
        default = 34.01,
        planes  = 34.01,
      },

      explosionGenerator      = [[custom:DEFAULT]],
      fireStarter             = 70,
      fixedlauncher           = 1,
      flightTime              = 1.7,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_b_fabby.s3o]],
      range                   = 115,
      reloadtime              = 20,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 5,
      soundStart              = [[weapon/missile/sabot_fire_short]],
      soundStartVolume        = 9,
      soundTrigger            = 1,
      startVelocity           = 70,
      texture2                = [[darksmoketrail]],
      tracks                  = true,
      turnRate                = 24000,
      turret                  = true,
      weaponAcceleration      = 50,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 130,
    },

  },

} }
