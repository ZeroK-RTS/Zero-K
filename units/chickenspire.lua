return { chickenspire = {
  unitname                      = [[chickenspire]],
  name                          = [[Chicken Spire]],
  description                   = [[Static Artillery]],
  activateWhenBuilt             = true,
  buildCostEnergy               = 0,
  buildCostMetal                = 0,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[chickenspire_aoplane.dds]],
  buildPic                      = [[chickenspire.png]],
  buildTime                     = 2500,
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 48 0]],
  collisionVolumeScales         = [[58 176 58]],
  collisionVolumeType           = [[CylY]],

  customParams                  = {
    outline_x = 155,
    outline_y = 200,
    outline_yoff = 75,
  },

  energyMake                    = 0,
  explodeAs                     = [[NOWEAPON]],
  floater                       = true,
  footprintX                    = 4,
  footprintZ                    = 4,
  highTrajectory                = 1,
  iconType                      = [[staticarty]],
  idleAutoHeal                  = 20,
  idleTime                      = 300,
  levelGround                   = false,
  maxDamage                     = 1500,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  maxWaterDepth                 = 20,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[spire.s3o]],
  onoffable                     = true,
  power                         = 2500,
  reclaimable                   = false,
  selfDestructAs                = [[NOWEAPON]],
  script                        = [[chickenspire.lua]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance                 = 512,
  sonarDistance                 = 512,
  upright                       = false,
  useBuildingGroundDecal        = true,
  yardMap                       = [[oooooooooooooooo]],

  weapons                       = {

    {
      def                = [[SLAMSPORE]],
      badTargetCategory  = [[MOBILE]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER]],
    },

  },


  weaponDefs                    = {
    SLAMSPORE = {
      name                    = [[Slammer Spore]],
      areaOfEffect            = 160,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,
            
            customParams            = {
        light_radius = 0,
      },

      damage                  = {
        default = 1000,
      },

      dance                   = 60,
      explosionGenerator      = [[custom:large_green_goo]],
      fireStarter             = 0,
      flightTime              = 30,
      groundbounce            = 1,
      heightmod               = 0.5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[chickenegggreen_big.s3o]],
      projectiles             = 4,
      range                   = 6300,
      reloadtime              = 14,
      smokeTrail              = true,
      startVelocity           = 40,
      texture1                = [[none]],
      texture2                = [[sporetrail2]],
      tolerance               = 10000,
      tracks                  = true,
      trajectoryHeight        = 2,
      turnRate                = 10000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 40,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 750,
      wobble                  = 24000,
    },

  },

} }
