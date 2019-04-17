unitDef = {
  unitname            = [[hoverriot]],
  name                = [[Mace]],
  description         = [[Riot Hover]],
  acceleration        = 0.03,
  activateWhenBuilt   = true,
  brakeRate           = 0.036,
  buildCostMetal      = 400,
  builder             = false,
  buildPic            = [[hoverriot.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 -8 0]],
  collisionVolumeScales  = [[48 36 48]],
  collisionVolumeType    = [[cylY]], 
  corpse              = [[DEAD]],

  customParams        = {
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[hoverriot]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 1300,
  maxSlope            = 36,
  maxVelocity         = 2.2,
  minCloakDistance    = 75,
  movementClass       = [[HOVER4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[hoverriot.s3o]],
  script              = [[hoverriot.lua]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
    },

  },

  sightDistance       = 407,
  sonarDistance       = 407,  
  turninplace         = 0,
  turnRate            = 560,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[LASER1]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    LASER1 = {
      name                    = [[High Intensity Laserbeam]],
      areaOfEffect            = 8,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

	  customparams = {
		stats_hide_damage = 1, -- continuous laser
		stats_hide_reload = 1,
		
		light_color = [[0.25 1 0.25]],
		light_radius = 120,
	  },

      damage                  = {
        default = 29.68,
        subs    = 1.75,
      },

      explosionGenerator      = [[custom:flash1green]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4.33,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 345,
      reloadtime              = 0.1,
      rgbColor                = [[0 1 0]],
      soundStart              = [[weapon/laser/laser_burn10]],
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


  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[hoverriot_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

}

return lowerkeys({ hoverriot = unitDef })
