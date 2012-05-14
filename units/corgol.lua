unitDef = {
  unitname            = [[corgol]],
  name                = [[Goliath]],
  description         = [[Very Heavy Tank Buster]],
  acceleration        = 0.0282,
  brakeRate           = 0.052,
  buildCostEnergy     = 2100,
  buildCostMetal      = 2100,
  builder             = false,
  buildPic            = [[corgol.png]],
  buildTime           = 2100,
  canAttack           = true,
  canGuard            = true,
  --canManualFire       = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Tanque dispersador pesado]],
    description_fr = [[Tank Émeutier Lourd]],
	description_de = [[Sehr schwerer Panzerknacker]],
    helptext       = [[The Goliath is the single heaviest tank on the field. Its main gun is a hefty cannon designed to smash lesser tanks into oblivion, while mounted on the turret is a disruptor beam that lames its prey. However, it turns like a tub of water, and it has no real way of dealing with raider swarms or air attacks. The heavy main cannon can shake walls down so it is somewhat able to spearhead assaults against areas with terraformed fortifications.]],
    helptext_bp    = [[Goliath é o tanque mais pesado do jogo, uma prova do poder de fogo de Logos. Sua arma principal é um grande canh?o que acaba facilmente com unidades pequenas, e seu lança chamas pode destruir rapidamente qualquer coisa que se aproxime demais. Porém, ele manobra lentamente e seu curto alcançe o torna presa fácil para escaramuçadores e ataques aéreos.]],
    helptext_fr    = [[Le Goliath est tout simplement le plus gros tank jamais construit. Un blindage lourd, un énorme canon plasma r moyenne portée fera voler en éclat les ennemis apeurés tandis que son lance flamme s'occupera des plus téméraires. Le Goliath est facile r repérer, il ne laisse que des ruines derricre lui.]],
	helptext_de    = [[Der Goliath ist der stärkste Panzer auf dem Platz. Seine mächtige Hauptkanone wurde entwickelt, um kleinere Panzer ins Nirvana zu schicken, während der aufgesetzte Flammenwerfer alle Einheiten, die dem Goliath zu nahe kommen, kurz und schmervoll verbrennt. Trotzdem bewegt sich der Panzer wie eine Wasserwanne und seine kurze Reichweite macht ihn zur einfachen Beute von hochentwickelten Skirmishern oder Luftattacken.]],
	extradrawrange = 300,
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
      [[custom:ARMBRTHA_FLARE]],
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
      def                = [[DISRUPTOR]],
      badTargetCategory  = [[FIREPROOF]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },

    --{
    --  def                = [[DISINTEGRATOR]],
    --  onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    --},    
    
  },


  weaponDefs          = {

    COR_GOL             = {
      name                    = [[Tankbuster Cannon]],
      areaOfEffect            = 40,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
	    gatherradius = [[105]],
	    smoothradius = [[70]],
	    smoothmult   = [[0.35]],
      },
      
      damage                  = {
        default = 1200,
        planes  = 1200,
        subs    = 60,
      },

      explosionGenerator      = [[custom:TESS]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 450,
      reloadtime              = 4,
      soundHit                = [[weapon/cannon/supergun_bass_boost]],
      soundStart              = [[weapon/cannon/rhino]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 310,
    },


    DISRUPTOR = {
      name                    = [[Disruptor Pulse Beam]],
      areaOfEffect            = 32,
      beamdecay		      = 0.9,
      beamTime                = 0.2,
      beamttl                 = 50,
      coreThickness           = 0.1,
      craterBoost             = 0,
      craterMult              = 0,
  
      customParams			= {
	timeslow_damagefactor = [[2]],
      },
	  
      damage = {
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
      range                   = 300,
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
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },
    
    DISINTEGRATOR = {
      name                    = [[Disintegrator]],
      areaOfEffect            = 48,
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidNeutral            = false,
      commandfire             = true,
      craterBoost             = 1,
      craterMult              = 6,

      damage                  = {
	default    = 1200,
      },
  
      explosionGenerator      = [[custom:DGUNTRACE]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      noExplode               = true,
      noSelfDamage            = true,
      range                   = 250,
      reloadtime              = 25,
      size                    = 6,
      soundHit                = [[explosion/ex_med6]],
      soundStart              = [[weapon/laser/heavy_laser4]],
      soundTrigger            = true,
      tolerance               = 10000,
      turret                  = true,
      weaponTimer             = 4.2,
      weaponType              = [[DGun]],
      weaponVelocity          = 300,
    }

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
      metal            = 840,
      object           = [[golly_d.s3o]],
      reclaimable      = true,
      reclaimTime      = 840,
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
      metal            = 420,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 420,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corgol = unitDef })
