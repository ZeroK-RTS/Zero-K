unitDef = {
  unitname            = [[chickenbroodqueen]],
  name                = [[Chicken Brood Queen]],
  description         = [[Tends the Nest]],
  acceleration        = 0.2,
  autoHeal            = 10,
  bmcode              = [[1]],
  brakeRate           = 0.2,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  buildDistance       = 240,
  builder             = true,

  buildoptions        = {
    [[chicken_drone]],
    [[chicken_pigeon]],
    [[chicken]],
    [[chicken_leaper]],
    [[chickens]],
    [[chicken_dodo]],
    [[chickenf]],
    [[chicken_blimpy]],
    [[chicken_digger]],
    [[chickena]],
    [[chickenr]],
    [[chicken_spidermonkey]],
    [[chickenc]],
    [[chicken_listener]],
    [[chicken_shield]],
    [[chicken_tiamat]],
    [[chickenq]],
  },

  buildPic            = [[chickenbroodqueen.png]],
  buildTime           = 1000,
  canAttack           = true,
  CanBeAssisted       = 0,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  canSubmerge         = true,
  cantBeTransported   = true,
  category            = [[LAND]],
  commander           = true,

  customParams        = {
    helptext = [[The egg-laying brood queen is not quite as fearsome in combat as the other queen, but can in the long run present an even bigger threat. It produces all the different chicken breeds of the Thunderbirds.]],
  },

  defaultmissiontype  = [[standby]],
  energyStorage       = 0,
  explodeAs           = [[SMALL_UNITEX]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[chickenc]],
  idleAutoHeal        = 0,
  idleTime            = 300,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 250,
  maxDamage           = 3000,
  maxSlope            = 72,
  maxVelocity         = 2,
  maxWaterDepth       = 22,
  metalMake           = 0.4,
  metalStorage        = 0,
  minCloakDistance    = 75,
  movementClass       = [[TKBOT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  objectName          = [[chickenbroodqueen.s3o]],
  power               = 2500,
  reclaimable         = false,
  seismicSignature    = 4,
  selfDestructAs      = [[SMALL_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  showPlayerName      = true,
  side                = [[THUNDERBIRDS]],
  sightDistance       = 1024,
  smoothAnim          = true,
  sonarDistance       = 450,
  steeringmode        = [[2]],
  TEDClass            = [[COMMANDER]],
  trackOffset         = 8,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 40,
  turnRate            = 200,
  upright             = false,
  workerTime          = 8,

  weapons             = {

    {
      def                = [[MELEE]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SUB SINK FLOAT SHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    MELEE  = {
      name                    = [[ChickenClaws]],
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 0,

      damage                  = {
        default = 40,
        planes  = 40,
        subs    = 40,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 1,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 120,
      reloadtime              = 0.4,
      size                    = 0,
      soundStart              = [[others/bigchickenbreath]],
      startsmoke              = [[0]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },


    SPORES = {
      name                    = [[Missiles]],
      areaOfEffect            = 24,
      avoidFriendly           = false,
      burst                   = 4,
      burstrate               = 0.1,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 30,
        subs    = 1.5,
      },

      dance                   = 60,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      flightTime              = 4,
      groundbounce            = 1,
      guidance                = true,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[chickeneggpink.s3o]],
      noSelfDamage            = true,
      range                   = 240,
      reloadtime              = 3,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[OTAunit/XPLOSML2]],
      startsmoke              = [[1]],
      startVelocity           = 200,
      texture1                = [[]],
      texture2                = [[sporetrail]],
      tolerance               = 10000,
      tracks                  = true,
      trajectoryHeight        = 2,
      turnRate                = 48000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 200,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 1000,
      wobble                  = 64000,
    },

  },

}

return lowerkeys({ chickenbroodqueen = unitDef })
