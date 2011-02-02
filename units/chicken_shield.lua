unitDef = {
  unitname            = [[chicken_shield]],
  name                = [[Toad]],
  description         = [[Shield/AA]],
  acceleration        = 0.36,
  bmcode              = [[1]],
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken_shield.png]],
  buildTime           = 1200,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],

  customParams        = {
    description_fr = [[Bouclier mobile/AA l?ger]],
    helptext       = [[Protects adjacent chickens.]],
    helptext_fr    = [[Le Toad est une sorte de crapaud g?ant avec comme particularit? de poss?der un puissant bouclier ?nerg?tique prot?geant les unit?s amies proches des tirs adverses lors de leur progression vers l'adversaire. Il utilise aussi des spores basiques pour se d?fendre des unit?s a?riennes.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[NOWEAPON]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[walkershield]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 346,
  maxDamage           = 1600,
  maxSlope            = 37,
  maxVelocity         = 1.8,
  maxWaterDepth       = 5000,
  minCloakDistance    = 75,
  movementClass       = [[AKBOT6]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[chicken_shield.s3o]],
  power               = 350,
  seismicSignature    = 4,
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side                = [[THUNDERBIRDS]],
  sightDistance       = 512,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  trackOffset         = 7,
  trackStrength       = 9,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 34,
  turnRate            = 806,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[FAKE_WEAPON]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },


    {
      def = [[SHIELD]],
    },


    {
      def                = [[AEROSPORES]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    AEROSPORES  = {
      name                    = [[Anti-Air Spores]],
      areaOfEffect            = 24,
      avoidFriendly           = false,
      burst                   = 3,
      burstrate               = 0.2,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 60,
        planes  = 60,
        subs    = 6,
      },

      dance                   = 60,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      fixedlauncher           = 1,
      flightTime              = 5,
      groundbounce            = 1,
      guidance                = true,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[chickeneggblue.s3o]],
      noSelfDamage            = true,
      range                   = 700,
      reloadtime              = 2.5,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      startsmoke              = [[1]],
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


    FAKE_WEAPON = {
      name                    = [[Fake]],
      areaOfEffect            = 8,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0.01,
        planes  = 0.01,
        subs    = 0.01,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 420,
      reloadtime              = 10,
      size                    = 0,
      soundHit                = [[]],
      soundStart              = [[]],
      startsmoke              = [[0]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = false,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },


    SHIELD      = {
      name                    = [[Shield]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      isShield                = true,
      shieldAlpha             = 0.15,
      shieldBadColor          = [[1.0 1 0.1]],
      shieldGoodColor         = [[0.1 1.0 0.1]],
      shieldInterceptType     = 3,
      shieldPower             = 2500,
      shieldPowerRegen        = 180,
      shieldPowerRegenEnergy  = 0,
      shieldRadius            = 300,
      shieldRepulser          = false,
      smartShield             = true,
      texture1                = [[wakelarge]],
      visibleShield           = false,
      visibleShieldHitFrames  = 30,
      visibleShieldRepulse    = false,
      weaponType              = [[Shield]],
    },

  },

}

return lowerkeys({ chicken_shield = unitDef })
