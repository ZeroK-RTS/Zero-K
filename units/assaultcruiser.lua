unitDef = {
  unitname               = [[assaultcruiser]],
  name                   = [[Vanquisher]],
  description            = [[Heavy Cruiser (Assault)]],
  acceleration           = 0.0768,
  activateWhenBuilt      = true,
  brakeRate              = 0.042,
  buildAngle             = 16384,
  buildCostEnergy        = 1600,
  buildCostMetal         = 1600,
  builder                = false,
  buildPic               = [[assaultcruiser.png]],
  buildTime              = 1600,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 4 -2]],
  collisionVolumeScales  = [[72 42 128]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[Box]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_pl = [[Ciezki krazownik szturmowy]],
    helptext       = [[The Vanquisher cruiser boasts excellent armor and lethal close-in firepower. Its phase cannons slice through surface and submerged targets, while its missiles support it against enemies above and below the water surface. Its short range and lack of anti-air firepower leaves it vulnerable to standoff units and aircraft.]],
    --helptext_pl    = [[Vanquisher to krazownik bojowy z duza sila ognia i wysoka wytrzymaloscia. Jego dziala bez problemu przebijaja sie przez cele na powierzchni, a jego rakiety niszcza cele pod i nad nia. Jego glownym problemem jest niski zasieg; ponadto, rakiety nie radza sobie z jednostkami latajacymi w duzych ilosciach.]],
  },

  explodeAs              = [[BIG_UNIT]],
  floater                = true,
  footprintX             = 5,
  footprintZ             = 5,
  iconType               = [[vanquisher]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 400,
  maxDamage              = 9600,
  maxVelocity            = 2.7,
  minCloakDistance       = 75,
  minWaterDepth          = 15,
  movementClass          = [[BOAT6]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB SINK TURRET]],
  objectName             = [[cremcrus.s3o]],
  script				 = [[assaultcruiser.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNIT]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:pulvmuzzle]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 600,
  sonarDistance			 = 800,
  turninplace            = 0,
  turnRate               = 260,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[FAKELASER]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
    },
	
    {
      def                = [[GAUSS]],
      mainDir            = [[-1 0 1]],
      maxAngleDif        = 240,
	  badTargetCategory	 = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
	
    {
      def                = [[GAUSS]],
      mainDir            = [[1 0 1]],
      maxAngleDif        = 240,
	  badTargetCategory	 = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SUB SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
	
    {
      def                = [[GAUSS]],
      mainDir            = [[-1 0 -1]],
      maxAngleDif        = 240,
	  badTargetCategory	 = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
	
    {
      def                = [[GAUSS]],
      mainDir            = [[1 0 -1]],
      maxAngleDif        = 240,
	  badTargetCategory	 = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },	
	
    {
      def                = [[MISSILE]],
      mainDir            = [[-1 0 0]],
      maxAngleDif        = 240,
	  badTargetCategory	 = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },	

    {
      def                = [[MISSILE]],
      mainDir            = [[1 0 0]],
      maxAngleDif        = 240,
	  badTargetCategory	 = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },		
	
  },


  weaponDefs             = {
  
    FAKELASER     = {
      name                    = [[Fake Laser]],
      areaOfEffect            = 12,
      beamlaser               = 1,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0,
        subs    = 0,
      },

      duration                = 0.11,
      fireStarter             = 70,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      laserFlareSize          = 5.53,
      range                   = 400,
      reloadtime              = 0.11,
      rgbColor                = [[0 1 0]],
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 5,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },	
	
    GAUSS = {
      name                    = [[Phase Cannon]],
      alphaDecay              = 0.12,
      areaOfEffect            = 16,
      bouncerebound           = 0.15,
      bounceslip              = 1,
      burst                   = 2,
      burstrate               = 0.4,
      cegTag                  = [[gauss_tag_l]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 200,
        planes  = 200,
        subs    = 10,
      },

      explosionGenerator      = [[custom:gauss_hit_m]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      minbarrelangle          = [[-15]],
      noExplode               = true,
      numbounce               = 40,
      range                   = 450,
      reloadtime              = 5,
      rgbColor                = [[0.5 1 1]],
      separation              = 0.5,
      size                    = 0.8,
      sizeDecay               = -0.1,
      soundHit                = [[weapon/gauss_hit]],
      soundStart              = [[weapon/gauss_fire]],
      sprayangle              = 800,
      stages                  = 32,
      startsmoke              = [[1]],
      turret                  = true,
      waterbounce             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2400,
    },
	
	MISSILE      = {
      name                    = [[Cruiser Missiles]],
      areaOfEffect            = 48,
	  burst					  = 2,
	  burstRate				  = 0.25,
      cegTag                  = [[missiletrailyellow]],
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 160,
        subs    = 160,
      },

      edgeEffectiveness       = 0.5,
      fireStarter             = 100,
	  fixedLauncher			  = true,	  
      flighttime              = 4,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_hailstorm.s3o]],
      noSelfDamage            = true,
      range                   = 420,
      reloadtime              = 3.2,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/missile_fire12]],
      soundStart              = [[weapon/missile/missile_fire10]],
      startVelocity			  = 300,
      tolerance               = 4000,
	  tracks				  = true,
	  trajectoryHeight		  = 0.5,
	  turnrate				  = 30000,
	  turret				  = true,	  
	  waterWeapon			  = true,
      weaponAcceleration      = 300,
      weaponTimer             = 1,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 600,
    },	
  },


  featureDefs            = {

    DEAD = {
      description      = [[Wreckage - Vanquisher]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 9600,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 5,
      footprintZ       = 5,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 640,
      object           = [[cremcrus_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 640,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP = {
      description      = [[Debris - Vanquisher]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 9600,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 320,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 320,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ assaultcruiser = unitDef })
