unitDef = {
  unitname            = [[battledrone]],
  name                = [[Viper]],
  description         = [[Advanced Battle Drone]],
  acceleration        = 0.3,
  airHoverFactor      = 4,
  amphibious          = true,
  brakeRate           = 4.18,
  buildCostEnergy     = 120,
  buildCostMetal      = 120,
  builder             = false,
  buildPic            = [[battledrone.png]],
  buildTime           = 120,
  canAttack           = true,
  canCloak            = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collide             = false,
  
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[28 12 26]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[ellipsoid]],    
  
  cruiseAlt           = 100,
  explodeAs           = [[TINY_BUILDINGEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverAttack         = true,
  iconType            = [[gunship]],
  initCloaked         = true,
  mass                = 84,
  maxDamage           = 480,
  maxVelocity         = 5,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[battledrone.s3o]],
  script              = [[battledrone.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[SMALL_BUILDINGEX]],
  
  customParams        = {
	description_de = [[Trägerdrohne]],
	description_fr = [[Drone d'attaque]],
	helptext_de    = [[]],
	helptext_fr    = [[]],
  },
  
  
  sfxtypes            = {

    explosiongenerators = {
    },

  },

  side                = [[ARM]],
  sightDistance       = 500,
  turnRate            = 792,
  upright             = true,

  weapons             = {

    {
      def                = [[DISRUPTOR]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 20,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    DISRUPTOR      = {
      name                    = [[Disruptor Pulse Beam]],
      areaOfEffect            = 24,
      beamdecay 				= 0.9,
      beamTime                = 0.03,
      beamttl                 = 50,
      coreThickness           = 0.25,
      craterBoost             = 0,
      craterMult              = 0,
  
      customParams			= {
	timeslow_damagefactor = [[2]],
      },
	  
      damage                  = {
	default = 200,
      },
  
      explosionGenerator      = [[custom:flash2purple]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4.33,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 450,
      reloadtime              = 2,
      rgbColor                = [[0.3 0 0.4]],
      soundStart              = [[weapon/laser/heavy_laser5]],
      soundStartVolume        = 3,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 8,
      tolerance               = 18000,
      turret                  = false,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },
  },

}

return lowerkeys({ battledrone = unitDef })
