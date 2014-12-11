unitDef = {
  unitname            = [[armmanni]],
  name                = [[Lance]],
  description         = [[Mobile Tachyon Projector (Artillery/Anti-Heavy)]],
  acceleration        = 0.016,
  brakeRate           = 0.148,
  buildCostEnergy     = 1000,
  buildCostMetal      = 1000,
  builder             = false,
  buildPic            = [[armmanni.png]],
  buildTime           = 1000,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 -10 0]],
  collisionVolumeScales  = [[48 54 48]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylY]], 
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Acelerador the Tachyons móvel]],
    description_de = [[Mobiler Tachyonen Beschleuniger (Artillerie/Anti-Heavy)]],
    description_fr = [[Accelerateur Tachyon Mobile]],
    description_pl = [[Mobilny Akcelerator Tachionow]],
    helptext       = [[The Lance's weapon, nicknamed 'the Blue Laser of Death', has the power and accuracy to skewer most units with a single shot. Use it against high armor units, but keep it behind the front lines - it has light armor and can't run from danger.]],
    helptext_bp    = [[A arma do Lance, apelidada de "O laser azul da morte", tem o poder e a precis?o para destruir a maioria das unidades com um único tiro. Use-o contra unidades muito resistentes, mas mantenha-o atras da linha de frente: Sua armadura é fina e ele é lento demais para fugir do perigo.]],
    helptext_de    = [[Penetrators Waffe, genannt "der Blaue Laser des Todes", hat die Macht und Präzision die meisten Einheiten mit einem einzigen Schuss zu vernichten. Nutze ihn gegen gut gepanzerte Einheiten, aber halte ihn hinter den Frontlinien - er besitzt nur wenig Durchhaltevermögen und kann nicht ruckartig weglaufen.]],
    helptext_fr    = [[Le surnon du Lance est 'le rayon bleu de la mort'. Le Lance est le tank le plus devastateur de tous, son laser peut traverser les rangs ennemis et décimer les plus lourds blindages ? grande distance. Il est cependant peu protégé et peu maniable.]],
    helptext_pl    = [[Bron Lacy ma wystarczajaca sile i celnosc, by jednym strzalem zniszczyc lub powaznie uszkodzic wiekszosc jednostek. Jest jednak wolny i ma niska wytrzymalosc, a zatem warto trzymac go za linia frontu - ma wystarczajaco duzy zasieg, by nadal prowadzic ostrzal.]],
	dontfireatradarcommand = '1',
  },

  explodeAs           = [[MEDIUM_BUILDINGEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[mobiletachyon]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  mass                = 304,
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
  
  side                = [[ARM]],
  sightDistance       = 660,
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
      beamlaser               = 1,
      beamTime                = 1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        statsprojectiles = 1,
        statsdamage = 3000,
      },
      damage                  = {
        default = 600,
        planes  = 600,
        subs    = 30,
      },

      explosionGenerator      = [[custom:ataalaser]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 10,
      lineOfSight             = true,
      minIntensity            = 1,
      noSelfDamage            = true,
	  projectiles             = 5,
      range                   = 1020,
      reloadtime              = 20,
      renderType              = 0,
      rgbColor                = [[0.25 0 1]],
      soundStart              = [[weapon/laser/heavy_laser6]],
	  soundStartVolume        = 3,
      targetMoveError         = 0.3,
      texture1                = [[largelaserdark]],
      texture2                = [[flaredark]],
      texture3                = [[flaredark]],
      texture4                = [[smallflaredark]],
      thickness               = 16.9373846859543,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 1500,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Penetrator]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1000,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 400,
      object           = [[Lordmuffe_Pene_dead.dae]],
      reclaimable      = true,
      reclaimTime      = 400,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Penetrator]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 400,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 400,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Penetrator]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 200,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 200,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armmanni = unitDef })
