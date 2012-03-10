unitDef = {
  unitname               = [[amphfloater]],
  name                   = [[Buoy]],
  description            = [[Amphibious Skirmisher Bot]],
  acceleration           = 0.2,
  activateWhenBuilt      = true,
  amphibious             = [[1]],
  brakeRate              = 0.4,
  buildCostEnergy        = 300,
  buildCostMetal         = 300,

  buildoptions           = {
  },

  buildPic               = [[amphfloater.png]],
  buildTime              = 300,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SINK]],
  collisionVolumeTest    = 1,
  corpse                 = [[DEAD]],

  customParams           = {
    floattoggle = [[1]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  hideDamage             = false,
  iconType               = [[amphskirm]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 411,
  maxDamage              = 1250,
  maxSlope               = 36,
  maxVelocity            = 1.5,
  maxWaterDepth          = 5000,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[can.s3o]],
  script                 = [[amphfloater.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
    },
  },

  side                   = [[ARM]],
  sightDistance          = 500,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1200,
  upright                = true,

  weapons                = {
    {
      def                = [[DISRUPTOR]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    --{
    --  def                = [[TORPEDO]],
    --  badTargetCategory  = [[FIXEDWING]],
    --  onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    --},
  },


  weaponDefs             = {

    DISRUPTOR = {
	name                    = [[Disruptor Pulse Beam]],
	areaOfEffect            = 32,
	beamdecay 		= 0.9,
	beamTime                = 0.2,
	beamttl                 = 50,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,
    
	damage                  = {
	    default = 300,
	},
    
	explosionGenerator      = [[custom:flash1teal]],
	fireStarter             = 30,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	largeBeamLaser          = true,
	laserFlareSize          = 4.33,
	minIntensity            = 1,
	noSelfDamage            = true,
	range                   = 430,
	reloadtime              = 3,
	rgbColor                = [[0.2 1 1]],
	soundStart              = [[weapon/laser/heavy_laser5]],
	soundStartVolume        = 3,
	soundTrigger            = true,
	sweepfire               = false,
	texture1                = [[largelaser]],
	texture2                = [[flare]],
	texture3                = [[flare]],
	texture4                = [[smallflare]],
	thickness               = 4.33,
	tolerance               = 18000,
	turret                  = true,
	weaponType              = [[BeamLaser]],
	weaponVelocity          = 500,
    },

  },


  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Buoy]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1250,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 120,
      object           = [[wreck2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP      = {
      description      = [[Debris - Buoy]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1250,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 60,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


  },

}

return lowerkeys({ amphfloater = unitDef })
