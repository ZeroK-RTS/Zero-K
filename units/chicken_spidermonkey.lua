unitDef = {
  unitname            = [[chicken_spidermonkey]],
  name                = [[Spidermonkey]],
  description         = [[All-Terrain Support]],
  acceleration        = 0.36,
  activateWhenBuilt   = true,
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken_spidermonkey.png]],
  buildTime           = 500,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],

  customParams        = {
  },

  explodeAs           = [[NOWEAPON]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[spiderskirm]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 1500,
  maxSlope            = 72,
  maxVelocity         = 2.2,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[ATKBOT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER STUPIDTARGET MINE]],
  objectName          = [[chicken_spidermonkey.s3o]],
  power               = 500,
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance       = 700,
  sonarDistance       = 700,
  trackOffset         = 0.5,
  trackStrength       = 9,
  trackStretch        = 1,
  trackType           = [[ChickenTrackPointy]],
  trackWidth          = 70,
  turnRate            = 1200,
  upright             = false,
  workerTime          = 0,

  weapons             = {
    {
      def                = [[WEB]],
			badTargetCategory	 = [[UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
			mainDir            = [[0 0 1]],
      maxAngleDif        = 180,	  
    },
  },

  weaponDefs          = {

    WEB    = {
      name                    = [[Web Weapon]],
      accuracy                = 800,
      
      customParams            = {
        impulse = [[-100]],
        timeslow_damagefactor = 1,
        timeslow_onlyslow = 1,
        timeslow_smartretarget = 0.33,
				light_radius = 0,
      },
      
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 30,
        subs    = 0.75,
      },

      dance                   = 150,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      fixedlauncher           = true,
      flightTime              = 3,
      impactOnly              = true,
      interceptedByShieldType = 2,
      range                   = 600,
      reloadtime              = 0.1,
      smokeTrail              = true,
      soundstart              = [[chickens/web]],
      startVelocity           = 600,
      texture2                = [[smoketrailthin]],
      tolerance               = 63000,
      tracks                  = true,
      turnRate                = 90000,
      turret                  = true,
      weaponAcceleration      = 400,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 2000,
    },

  },

}

return lowerkeys({ chicken_spidermonkey = unitDef })
