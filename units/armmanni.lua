unitDef = {
  unitname            = [[armmanni]],
  name                = [[Penetrator]],
  description         = [[Anti-Heavy Artillery Hovercraft]],
  acceleration        = 0.016,
  activateWhenBuilt   = true,
  brakeRate           = 0.148,
  buildCostEnergy     = 1000,
  buildCostMetal      = 1000,
  builder             = false,
  buildPic            = [[armmanni.png]],
  buildTime           = 1000,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 -2 0]],
  collisionVolumeScales  = [[48 58 48]],
  collisionVolumeType    = [[cylY]], 
  corpse              = [[DEAD]],

  customParams        = {
    description_de = [[Mobiler Tachyonen Beschleuniger (Artillerie/Anti-Heavy)]],
    description_fr = [[Accelerateur Tachyon Mobile]],
    helptext       = [[The Penetrator's weapon, nicknamed 'the Blue Laser of Death', has the power and accuracy to skewer most units with a single shot. Use it against high armor units, but keep it behind the front lines - it has light armor and can't run from danger.]],
    helptext_de    = [[Penetrators Waffe, genannt "der Blaue Laser des Todes", hat die Macht und Präzision die meisten Einheiten mit einem einzigen Schuss zu vernichten. Nutze ihn gegen gut gepanzerte Einheiten, aber halte ihn hinter den Frontlinien - er besitzt nur wenig Durchhaltevermögen und kann nicht ruckartig weglaufen.]],
    helptext_fr    = [[Le surnon du Penetrator est 'le rayon bleu de la mort'. Le Penetrator est le tank le plus devastateur de tous, son laser peut traverser les rangs ennemis et décimer les plus lourds blindages ? grande distance. Il est cependant peu protégé et peu maniable.]],
	dontfireatradarcommand = '1',
    aimposoffset   = [[0 15 0]],
  },

  explodeAs           = [[MEDIUM_BUILDINGEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[mobiletachyon]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  losEmitHeight       = 40,
  maxDamage           = 1000,
  maxSlope            = 18,
  maxVelocity         = 2.4,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[penetrator_lordmuffe.s3o]],
  script	          = [[armmanni.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[MEDIUM_BUILDINGEX]],
  
  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
    },

  },
  
  sightDistance       = 660,
  sonarDistance       = 660,
  turninplace         = 0,
  turnRate            = 320,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[ATA]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP FIXEDWING HOVER]],
    },

  },


  weaponDefs          = {

    ATA = {
      name                    = [[Tachyon Accelerator]],
      areaOfEffect            = 20,
      beamTime                = 1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
		light_color = [[1.25 0.8 1.75]],
		light_radius = 320,
      },
      damage                  = {
        default = 3000.1,
        planes  = 3000.1,
        subs    = 150.1,
      },

      explosionGenerator      = [[custom:ataalaser]],
	  fireTolerance           = 8192, -- 45 degrees
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 10,
	  leadLimit               = 18,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 1020,
      reloadtime              = 20,
      rgbColor                = [[0.25 0 1]],
      soundStart              = [[weapon/laser/heavy_laser6]],
	  soundStartVolume        = 3,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 16.9373846859543,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 1500,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
	  collisionVolumeScales  = [[40 40 60]],
	  collisionVolumeType    = [[CylZ]],
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[Lordmuffe_Pene_dead.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3b.s3o]],
    },

  },

}

return lowerkeys({ armmanni = unitDef })
