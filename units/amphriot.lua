unitDef = {
  unitname               = [[amphriot]],
  name                   = [[Scallop]],
  description            = [[Amphibious Riot Bot (Land), Skirmish Bot (Sea)]],
  acceleration           = 0.18,
  activateWhenBuilt      = true,
  brakeRate              = 0.375,
  buildCostEnergy        = 280,
  buildCostMetal         = 280,
  buildPic               = [[amphriot.png]],
  buildTime              = 280,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND SINK]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_pl = [[Amfibijny bot wsparcia]],
    helptext       = [[A flexible unit, the Scallop is armed with impact explosives for underwater use and a quadruple shotgun when on land. It acts as a stealthy underwater skirmisher, capable of killing outnumbered enemies with low attrition.]],
    helptext_pl    = [[Scallop to wszechstronna jednostka, ktora oprocz torped ma takze shotgun do walk na ladzie.]],
    extradrawrange = 460,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[amphtorpriot]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 1100,
  maxSlope               = 36,
  maxVelocity            = 1.5,
  maxWaterDepth          = 5000,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER]],
  objectName             = [[amphriot.s3o]],
  script                 = [[amphriot.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
      [[custom:HEAVY_CANNON_MUZZLE]],
      [[custom:RIOT_SHELL_L]],
    },
  },

  sightDistance          = 430,
  sonarDistance          = 280,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 28,
  turnRate               = 1000,
  upright                = false,

  weapons                = {

    {
      def                = [[FLECHETTE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER]],
    },

  },

  weaponDefs             = {

    TORPEDO = {
      name                    = [[Undersea Charge Launcher]],
      areaOfEffect            = 64,
      burst		              = 4,
      burstRate		          = 0.15,
      avoidFriendly           = false,
      bouncerebound           = 1,
      bounceslip              = 1,
	  burnblow                = 1,
	  canAttackGround		  = false,	-- also workaround for range hax
	  flighttime              = 1.5,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 55,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.6,
      interceptedByShieldType = 1,
	  leadlimit               = 0,
	  myGravity               = 2,
      model                   = [[diskball.s3o]],
      numBounce               = 1,
      range                   = 430,
      reloadtime              = 6,
      soundHit                = [[TorpedoHitVariable]],
	  soundHitVolume          = 3.2,
      --soundStart              = [[weapon/torpedo]],
      startVelocity           = 100,
      tracks                  = true,
      turnRate                = 4000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 140,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 400,
    },

    FLECHETTE = {
      name                    = [[Flechette]],
      areaOfEffect            = 32,
      burst		              = 3,
      burstRate		          = 0.03,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
	    default = 26,
	    subs    = 1.6,
      },

      duration                = 0.02,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_YELLOW]],
      fireStarter             = 50,
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      projectiles	          = 3,
      range                   = 300,
      reloadtime              = 0.8,
      rgbColor                = [[1 1 0]],
      soundHit                = [[impacts/shotgun_impactv5]],
      soundStart              = [[weapon/shotgun_firev4]],
      soundStartVolume	      = 0.5,
      soundTrigger            = true,
      sprayangle	          = 1500,
      targetMoveError         = 0,
      thickness               = 2,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 880,
    }
  },

  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Scallop]],
      blocking         = true,
      damage           = 1600,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      metal            = 140,
      object           = [[amphriot_wreck.s3o]],
      reclaimable      = true,
      reclaimTime      = 140,
    },

    HEAP      = {
      description      = [[Debris - Scallop]],
      blocking         = false,
      damage           = 1600,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 70,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 70,
    },

  },

}

return lowerkeys({ amphriot = unitDef })
