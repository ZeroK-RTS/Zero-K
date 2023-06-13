return { roost = {
  unitname          = [[roost]],
  name              = [[Roost]],
  description       = [[Spawns Chicken]],
  activateWhenBuilt = true,
  buildCostMetal    = 340,
  builder           = false,
  buildPic          = [[roost.png]],
  category          = [[SINK]],

  customParams      = {
  },
  
  energyMake        = 0,
  explodeAs         = [[NOWEAPON]],
  footprintX        = 3,
  footprintZ        = 3,
  iconType          = [[special]],
  idleAutoHeal      = 20,
  idleTime          = 300,
  levelGround       = false,
  maxDamage         = 1800,
  maxSlope          = 36,
  maxVelocity       = 0,
  metalMake         = 2.5,
  noAutoFire        = false,
  objectName        = [[roost.s3o]],
  script            = [[roost.lua]],
  selfDestructAs    = [[NOWEAPON]],

  sfxtypes          = {

    explosiongenerators = {
      [[custom:dirt2]],
      [[custom:dirt3]],
    },

  },
  sightDistance     = 273,
  upright           = false,
  waterline         = 0,
  workerTime        = 0,
  yardMap           = [[ooooooooo]],

  weapons           = {

    {
      def                = [[AEROSPORES]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs        = {

    AEROSPORES = {
      name                    = [[Anti-Air Spores]],
      areaOfEffect            = 24,
      avoidFriendly           = false,
      burst                   = 4,
      burstrate               = 0.2,
      canAttackGround         = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        light_radius = 0,
      },
      
      damage                  = {
        default = 80,
        planes  = 80,
      },

      dance                   = 60,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      fixedlauncher           = 1,
      flightTime              = 5,
      groundbounce            = 1,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[chickeneggblue.s3o]],
      range                   = 600,
      reloadtime              = 3,
      smokeTrail              = true,
      startVelocity           = 100,
      texture1                = [[]],
      texture2                = [[sporetrailblue]],
      tolerance               = 10000,
      tracks                  = true,
      turnRate                = 24000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 500,
      wobble                  = 32000,
    },

  },


  featureDefs       = {
  },

} }
