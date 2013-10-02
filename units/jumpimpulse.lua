unitDef = {
  unitname              = [[jumpimpulse]],
  name                  = [[Elevator]],
  description           = [[Impulse Shenanigans Jumpbot]],
  acceleration          = 0.4,
  brakeRate             = 0.4,
  buildCostEnergy       = 300,
  buildCostMetal        = 300,
  builder               = false,
  buildPic              = [[JUMPRIOT.png]],
  buildTime             = 300,
  canAttack             = true,
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  canstop               = [[1]],
  category              = [[LAND FIREPROOF]],
  corpse                = [[DEAD]],

  customParams          = {
    canjump        = [[1]],
    helptext       = [[Shenanigans jumpbot.]],
  },

  explodeAs             = [[BIG_UNITEX]],
  footprintX            = 2,
  footprintZ            = 2,
  iconType              = [[jumpjetriot]],
  idleAutoHeal          = 5,
  idleTime              = 1800,
  leaveTracks           = true,
  mass                  = 157,
  maxDamage             = 900,
  maxSlope              = 36,
  maxVelocity           = 2,
  maxWaterDepth         = 22,
  minCloakDistance      = 75,
  movementClass         = [[KBOT2]],
  noAutoFire            = false,
  noChaseCategory       = [[FIXEDWING SATELLITE GUNSHIP SUB TURRET UNARMED]],
  objectName            = [[freaker.s3o]],
  script		        = [[jumpriot.lua]],
  seismicSignature      = 4,
  selfDestructAs        = [[BIG_UNITEX]],
  selfDestructCountdown = 1,

  sfxtypes              = {

    explosiongenerators = {
      [[custom:PILOT]],
      [[custom:PILOT2]],
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
    },

  },

  side                  = [[CORE]],
  sightDistance         = 550,
  smoothAnim            = true,
  trackOffset           = 0,
  trackStrength         = 8,
  trackStretch          = 1,
  trackType             = [[ComTrack]],
  trackWidth            = 22,
  turnRate              = 1400,
  upright               = true,
  workerTime            = 0,

 weapons             = {

    {
      def                = [[IMPULSE_BEAM]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND SHIP GUNSHIP]],
    },

  },


  weaponDefs          = {

    IMPULSE_BEAM = {
      name                    = [[Impulse Beam]],
      areaOfEffect            = 8,
      beamDecay               = 0.9,
      beamlaser               = 1,
      beamTime                = 0.03,
      beamttl                 = 40,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams            = {
	    impulse = [[-300]],
		impulseup = [[1200]],
	  },

      damage                  = {
        default = 0,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 500,
      reloadtime              = 10,
      rgbColor                = [[0 0 1]],
      soundStart              = [[weapon/gravity_fire]],
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 8,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },

  },


  featureDefs           = {

    DEAD  = {
      description      = [[Wreckage - Placeholder]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 900,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 200,
      object           = [[m-5_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 200,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

	
    HEAP  = {
      description      = [[Debris - Placeholder]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 900,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 100,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ jumpimpulse = unitDef })
