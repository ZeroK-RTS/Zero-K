unitDef = {
  unitname               = [[scorpion]],
  name                   = [[Scorpion]],
  description            = [[Heavy Assault/Battle Spider]],
  acceleration           = 0.26,
  brakeRate              = 0.26,
  buildCostEnergy        = 2500,
  buildCostMetal         = 2500,
  builder                = false,
  buildPic               = [[scorpion.png]],
  buildTime              = 2500,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  cloakCost              = 2,
  cloakCostMoving        = 10,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[80 60 80]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    helptext       = [[The Scorpion paralyzes enemies with its lightning sting and then chews them up with its particle beam claws. Its tough carapace shrugs off most enemy fire, and can also turn the Scorpion transparent.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3generic]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  initCloaked			 = true,
  leaveTracks            = true,
  mass                   = 155,
  maxDamage              = 12000,
  maxSlope               = 72,
  maxVelocity            = 2,
  maxWaterDepth          = 22,
  minCloakDistance       = 150,
  movementClass          = [[TKBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[scorpion.s3o]],
  script				 = [[scorpion.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:zeusmuzzle]],
      [[custom:zeusgroundflash]],
    },

  },

  side                   = [[ARM]],
  sightDistance          = 440,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType				 = [[crossFoot]],
  trackWidth             = 76,
  turnRate               = 400,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[LIGHTNING]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[PARTICLEBEAM]],
	  mainDir            = [[-0.2 0 1]],
      maxAngleDif        = 240,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
	
    {
      def                = [[PARTICLEBEAM]],
	  mainDir            = [[0.2 0 1]],
      maxAngleDif        = 240,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
	
  },


  weaponDefs             = {

    LIGHTNING = {
      name                    = [[Lightning Gun]],
      areaOfEffect            = 8,
      beamWeapon              = true,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        extra_damage = [[360]],
      },

      cylinderTargetting      = 0,

      damage                  = {
        default        = 1080,
        empresistant75 = 270,
        empresistant99 = 10.8,
      },

      duration                = 10,
      explosionGenerator      = [[custom:LIGHTNINGPLOSION]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 12,
      interceptedByShieldType = 1,
      paralyzer               = true,
      paralyzeTime            = 3,
      range                   = 400,
      reloadtime              = 2,
      rgbColor                = [[0.5 0.5 1]],
      soundStart              = [[weapon/more_lightning]],
      soundTrigger            = true,
      startsmoke              = [[1]],
      targetMoveError         = 0.3,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 400,
    },

    PARTICLEBEAM = {
      name                    = [[Auto Particle Beam]],
      beamDecay               = 0.85,
      beamTime                = 0.01,
      beamttl                 = 45,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 60,
        subs    = 3,
      },

      explosionGenerator      = [[custom:flash1red]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 7.5,
      minIntensity            = 1,
      pitchtolerance          = 8192,
      range                   = 460,
      reloadtime              = 0.33,
      rgbColor                = [[1 0 0]],
      soundStart              = [[weapon/laser/mini_laser]],
      soundStartVolume        = 5,
      thickness               = 5,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Scorpion]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 12000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 1000,
      object           = [[venom_wreck.s3o]],
      reclaimable      = true,
      reclaimTime      = 1000,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
	  
    },
    HEAP  = {
      description      = [[Debris - Scorpion]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 12000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 500,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 500,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ scorpion = unitDef })
