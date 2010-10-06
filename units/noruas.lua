unitDef = {
  unitname              = [[noruas]],
  name                  = [[Chuck Noruas]],
  description           = [[Opens up a can of XTA, Builds at 45 m/s]],
  acceleration          = 0.18,
  activateWhenBuilt     = false,
  amphibious            = [[1]],
  autoHeal              = 12,
  bmcode                = [[1]],
  brakeRate             = 0.375,
  buildCostEnergy       = 10000,
  buildCostMetal        = 10000,
  buildDistance         = 120,
  builder               = true,

  buildoptions          = {
    [[core_egg_shell]],
    [[core_striker]],
  },

  buildPic              = [[noruas.png]],
  buildTime             = 10000,
  canAttack             = true,
  canCapture            = true,
  canDGun               = true,
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  canreclamate          = [[1]],
  canstop               = [[1]],
  captureSpeed          = 36,
  category              = [[LAND FIREPROOF]],
  cloakCost             = 10,
  cloakCostMoving       = 50,
  commander             = true,

  customParams          = {
    canjump   = [[1]],
    fireproof = [[1]],
    helptext  = [[Chuck Noruas laughs at you for needing him!]],
  },

  defaultmissiontype    = [[Standby]],
  energyMake            = 10,
  energyUse             = 0,
  explodeAs             = [[LARGE_BUILDING]],
  footprintX            = 2,
  footprintZ            = 2,
  hideDamage            = true,
  iconType              = [[armcommander]],
  idleAutoHeal          = 5,
  idleTime              = 1800,
  immunetoparalyzer     = true,
  maneuverleashlength   = [[640]],
  mass                  = 2500,
  maxDamage             = 4000,
  maxSlope              = 36,
  maxVelocity           = 3.45,
  maxWaterDepth         = 5000,
  metalMake             = 3,
  minCloakDistance      = 100,
  movementClass         = [[AKBOT2]],
  noChaseCategory       = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  norestrict            = [[1]],
  objectName            = [[noruas]],
  radarDistance         = 1200,
  reclaimable           = false,
  seismicSignature      = 16,
  selfDestructAs        = [[LARGE_BUILDING]],
  selfDestructCountdown = 10,

  sfxtypes              = {

    explosiongenerators = {
      [[custom:COMGATE]],
    },

  },

  showPlayerName        = false,
  side                  = [[ARM]],
  sightDistance         = 800,
  smoothAnim            = true,
  sonarDistance         = 300,
  steeringmode          = [[2]],
  TEDClass              = [[COMMANDER]],
  terraformSpeed        = 2250,
  turnRate              = 1148,
  upright               = true,
  workerTime            = 45,

  weapons               = {

    [1] = {
      def               = [[NoruasThrow]],
      badTargetCategory = [[FIXEDWING GUNSHIP SATELLITE]],
    },


    [3] = {
      def = [[EYEDISINTEGRATOR]],
    },


    [4] = {
      def               = [[DirtyJump]],
      badTargetCategory = [[FIXEDWING GUNSHIP SATELLITE]],
    },


    [5] = {
      def               = [[ExplosiveLanding]],
      badTargetCategory = [[FIXEDWING GUNSHIP SATELLITE]],
    },

  },


  weaponDefs            = {

    DirtyJump        = {
      name                    = [[HeavyCannon]],
      areaOfEffect            = 100,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 2000,
        planes  = 1000,
        subs    = 500,
      },

      explosionGenerator      = [[custom:TESS]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 1,
      reloadtime              = 4.5,
      renderType              = 4,
      startsmoke              = [[1]],
      turret                  = true,
      weaponVelocity          = 1,
    },


    ExplosiveLanding = {
      name                    = [[HeavyCannon]],
      areaOfEffect            = 300,
      craterBoost             = 0.5,
      craterMult              = 1,

      damage                  = {
        default = 3000,
        planes  = 1000,
        subs    = 500,
      },

      explosionGenerator      = [[custom:ROACHPLOSION]],
      impulseBoost            = 0,
      impulseFactor           = 0.8,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 1,
      reloadtime              = 4.5,
      renderType              = 4,
      soundHit                = [[golgotha/supergun]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponVelocity          = 1,
    },


    EYEDISINTEGRATOR = {
      name                    = [[Disintegrator]],
      areaOfEffect            = 36,
      avoidFriendly           = false,
      commandfire             = true,
      craterBoost             = 1,
      craterMult              = 6,

      damage                  = {
        default    = 9999,
        commanders = [[1]],
      },

      energypershot           = 1000,
      explosionGenerator      = [[custom:DGUNTRACE]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      noExplode               = true,
      noSelfDamage            = true,
      range                   = 240,
      reloadtime              = 1,
      renderType              = 3,
      soundHit                = [[OTAunit/XPLOMAS2]],
      soundStart              = [[OTAunit/DISIGUN1]],
      soundTrigger            = true,
      tolerance               = 10000,
      turret                  = true,
      weaponTimer             = 4.2,
      weaponVelocity          = 200,
    },


    NoruasThrow      = {
      name                    = [[HeavyCannon]],
      areaOfEffect            = 150,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 1280,
        planes  = 474,
        subs    = 29,
      },

      explosionGenerator      = [[custom:xamelimpact]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 4.5,
      renderType              = 4,
      startsmoke              = [[1]],
      turret                  = true,
      weaponVelocity          = 310,
    },

  },

}

return lowerkeys({ noruas = unitDef })
