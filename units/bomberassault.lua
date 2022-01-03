return { bomberassault = {
  unitname            = [[bomberassault]],
  name                = [[Eclipse]],
  description         = [[Assault Bomber (Anti-Static)]],
  --autoheal            = 25,
  brakerate           = 0.4,
  buildCostMetal      = 1000,
  builder             = false,
  buildPic            = [[bomberassault.png]],
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[-2 0 0]],
  collisionVolumeScales  = [[32 12 40]],
  collisionVolumeType    = [[box]],
  corpse              = [[DEAD]],
  crashDrag           = 0.02,
  cruiseAlt           = 250,

  customParams        = {
    requireammo      = [[1]],
    modelradius      = [[10]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[bombernuke]],
  maneuverleashlength = [[1280]],
  maxAcc              = 0.5,
  maxDamage           = 4000,
  maxElevator         = 0.01,
  maxRudder           = 0.003,
  maxFuel             = 1000000,
  maxVelocity         = 6,
  mygravity           = 1,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[zeppelin.dae]],
  --refuelTime        = 16,
  script              = [[bomberassault.lua]],
  selfDestructAs      = [[GUNSHIPEX]],
  sightDistance       = 660,
  turnRadius          = 90,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[ZEPPELIN_BOMB]],
      badTargetCategory  = [[GUNSHIP FIXEDWING]],
      onlyTargetCategory = [[SWIM LAND SINK SUB TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },

  },


  weaponDefs          = {
    ZEPPELIN_BOMB = {
      name                    = [[Heavy Superbomb]],
      areaOfEffect            = 100,
      avoidFeature            = false,
      avoidFriendly           = false,
      collideFeature          = false,
      collideFriendly         = false,
      craterBoost             = 10,
      craterMult              = 1,
      
      damage                  = {
        default = 2500,
        planes  = 2500,
      },

      edgeEffectiveness       = 0.7,
      explosionGenerator      = [[custom:slam]],
      impulseBoost            = 0,
      impulseFactor           = 0.1,
      interceptedByShieldType = 1,
      model                   = [[zeppelin_bomb.dae]],
      myGravity               = 0.15,
      noSelfDamage            = true,
      range                   = 500,
      reloadtime              = 10,
      soundHit                = [[weapon/missile/liche_hit]],
      soundStart              = [[weapon/missile/liche_fire]],
      weaponType              = [[AircraftBomb]],
    },


  },


  featureDefs         = {
    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[zeppelin_dead.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris3x3b.s3o]],
    },

  },

} }
