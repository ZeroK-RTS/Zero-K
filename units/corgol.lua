unitDef = {
  unitname            = [[corgol]],
  name                = [[Goliath]],
  description         = [[Very Heavy Tank Buster]],
  acceleration        = 0.0282,
  brakeRate           = 0.052,
  buildCostEnergy     = 2200,
  buildCostMetal      = 2200,
  builder             = false,
  buildPic            = [[corgol.png]],
  buildTime           = 2200,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Tanque dispersador pesado]],
    description_fr = [[Tank Émeutier Lourd]],
	description_de = [[Sehr schwerer Panzerknacker]],
    helptext       = [[The Goliath is the single heaviest tank on the field. Its main gun is a hefty cannon designed to smash lesser tanks into oblivion, while mounted on the turret is a short-range slowgun to prevent quicker foes escaping its grasp. However, it turns like a tub of water, its short range makes it easy prey for advanced skirmishers or air attacks, and its slow rate of fire makes it vulnerable to massed raider attacks. The heavy main cannon can shake walls down so it is somewhat able to spearhead assaults against areas with terraformed fortifications.]],
    helptext_bp    = [[Goliath é o tanque mais pesado do jogo, uma prova do poder de fogo de Logos. Sua arma principal é um grande canh?o que acaba facilmente com unidades pequenas, e seu lança chamas pode destruir rapidamente qualquer coisa que se aproxime demais. Porém, ele manobra lentamente e seu curto alcançe o torna presa fácil para escaramuçadores e ataques aéreos.]],
    helptext_fr    = [[Le Goliath est tout simplement le plus gros tank jamais construit. Un blindage lourd, un énorme canon plasma r moyenne portée fera voler en éclat les ennemis apeurés tandis que son lance flamme s'occupera des plus téméraires. Le Goliath est facile r repérer, il ne laisse que des ruines derricre lui.]],
	helptext_de    = [[Der Goliath ist der stärkste Panzer auf dem Platz. Seine mächtige Hauptkanone wurde entwickelt, um kleinere Panzer ins Nirvana zu schicken, während der aufgesetzte Flammenwerfer alle Einheiten, die dem Goliath zu nahe kommen, kurz und schmervoll verbrennt. Trotzdem bewegt sich der Panzer wie eine Wasserwanne und seine kurze Reichweite macht ihn zur einfachen Beute von hochentwickelten Skirmishern oder Luftattacken.]],
	extradrawrange = 350,
  },

  explodeAs           = [[BIG_UNIT]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[tankskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  mass                = 613,
  maxDamage           = 12000,
  maxSlope            = 18,
  maxVelocity         = 2.05,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[corgol_512.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNIT]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:LARGE_MUZZLE_FLASH_FX]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 540,
  smoothAnim          = true,
  trackOffset         = 8,
  trackStrength       = 10,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 45,
  turninplace         = 0,
  turnRate            = 312,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[COR_GOL]],
	  badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },
    {
      def                = [[SLOWBEAM]],
      badTargetCategory  = [[FIXEDWING UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs          = {

    COR_GOL             = {
      name                    = [[Tankbuster Cannon]],
      areaOfEffect            = 32,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
	    gatherradius = [[105]],
	    smoothradius = [[70]],
	    smoothmult   = [[0.4]],
	  },
      
      damage                  = {
        default = 1000,
        planes  = 1000,
        subs    = 50,
      },

      explosionGenerator      = [[custom:TESS]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 450,
      reloadtime              = 3.5,
      soundHit                = [[weapon/cannon/supergun_bass_boost]],
      soundStart              = [[weapon/cannon/rhino]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 310,
    },
	
	SLOWBEAM = {
      name                    = [[Slowing Beam]],
      areaOfEffect            = 8,
      beamDecay               = 0.9,
      beamlaser               = 1,
      beamTime                = 0.12,
      beamttl                 = 50,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 600,
      },

      explosionGenerator      = [[custom:flashslow]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 350,
      reloadtime              = 3,
      rgbColor                = [[0.27 0 0.36]],
      soundStart              = [[weapon/laser/pulse_laser2]],
      soundStartVolume        = 15,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 11,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },

    CORGOL_FLAMETHROWER = {
      name                    = [[Flamethrower]],
      areaOfEffect            = 64,
      avoidFeature            = false,
      avoidFriendly           = false,
      collideFeature          = false,
      collideGround           = false,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        	  = {
		flamethrower = [[1]],
	    setunitsonfire = "1",
		burntime = [[360]],
	  },
	  
      damage                  = {
        default = 5,
        subs    = 0.05,
      },

      duration                = 0.1,
      explosionGenerator      = [[custom:SMOKE]],
      fallOffRate             = 1,
      fireStarter             = 100,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 0.1,
      interceptedByShieldType = 0,
      noExplode               = true,
      noSelfDamage            = true,
      --predictBoost			  = 1,
      range                   = 280,
      reloadtime              = 0.16,
      rgbColor                = [[1 1 1]],
      soundStart              = [[weapon/flamethrower]],
      soundTrigger            = true,
      texture1				  = [[fireball]],
      texture2				  = [[fireball]],
      thickness	              = 12,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 800,
    },


  },


  featureDefs         = {

    DEAD       = {
      description      = [[Wreckage - Goliath]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 12000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 880,
      object           = [[golly_d.s3o]],
      reclaimable      = true,
      reclaimTime      = 880,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

	
    HEAP       = {
      description      = [[Debris - Goliath]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 12000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 440,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 440,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corgol = unitDef })
