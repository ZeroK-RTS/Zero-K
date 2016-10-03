unitDef = {
  unitname            = [[corfast]],
  name                = [[Constable]],
  description         = [[Jumpjet Constructor, Builds at 5 m/s]],
  acceleration        = 0.26,
  brakeRate           = 0.26,
  buildCostEnergy     = 160,
  buildCostMetal      = 160,
  buildDistance       = 120,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[CORFAST.png]],
  buildTime           = 160,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canreclamate        = [[1]],
  category            = [[LAND UNARMED]],
  corpse              = [[DEAD]],

  customParams        = {
    canjump            = 1,
    jump_range         = 400,
    jump_speed         = 6,
    jump_reload        = 10,
    jump_from_midair   = 1,

    description_bp = [[Construtor saltador, produz a 5 m/s]],
    description_es = [[Constructor jumpjet, construye a 5 m/s]],
    description_fr = [[Constructeur r Jetpack, Construit r 5 m/s]],
    description_it = [[Costruttore jumpjet, costruisce a 5 m/s]],
	description_de = [[Konstruktionsjumpjet, Baut mit 5 M/s]],
	description_pl = [[Skaczacy konstruktor, moc 5 m/s]],
    helptext       = [[Fast and capable of jumping over short distances or heights, the Constable is the ideal constructor for rapid expansion. Armed with a light slowbeam, it can also provide combat support.]],
    helptext_bp    = [[Rápido e capaz de saltar por sobre distâncias curtas ou pequenos obstáculos, Constable é ideal para expans?o rápida.]],
    helptext_es    = [[Rápido y capaz de brincar sobre cortas distancias o alturas, el Constable es el constructor ideal para la expansión rápida]],
    helptext_fr    = [[R la fois rapide et capable de sauter sur de courtes distances grâce r son jetpack, le Constable est un superbe outil pour favoriser son expansion.]],
    helptext_it    = [[Veloce e capace di saltare per corte distanze o altezze, il Constable é il costruttore ideale per l'espanzione rapida]],
	helptext_de    = [[Schnell und mit der Möglichkeit ausgestattet über kurze Distanzen oder Höhen zu springen, eignet sich der Constable als ideale Konstruktionseinheit für rasche Expansion.]],
	helptext_pl    = [[Predki i majacy mozliwosc skoku, Constable to idealny konstruktor do szybkiej rozbudowy. Posiada takze lekki promien spowalniajacy, dzieki ktoremu zapewnia wsparcie w walce.]],
  },

  energyMake          = 0.15,
  energyUse           = 0,
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  healtime            = [[8]],
  iconType            = [[builder]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  mass                = 159,
  maxDamage           = 550,
  maxSlope            = 36,
  maxVelocity         = 2.1,
  maxWaterDepth       = 22,
  metalMake           = 0.15,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[behe_coroner.s3o]],
  script              = [[corfast.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:VINDIMUZZLE]],
      [[custom:VINDIBACK]],
    },

  },

  showNanoSpray       = false,
  side                = [[CORE]],
  sightDistance       = 375,
  smoothAnim          = true,
  TEDClass            = [[CNSTR]],
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  terraformSpeed      = 450,
  turnRate            = 1400,
  upright             = true,
  workerTime          = 5,
 
  weapons             = {

    {
      def                = [[SLOWBEAM]],
      badTargetCategory  = [[FIXEDWING UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs          = {

    SLOWBEAM = {
      name                    = [[Slowing Beam]],
      areaOfEffect            = 8,
      beamDecay               = 0.9,
      beamTime                = 0.1,
      beamttl                 = 40,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      customparams = {
        timeslow_damagefactor = 1,
        timeslow_onlyslow = 1,
        timeslow_smartretarget = 0.33,
		
		light_camera_height = 1800,
		light_color = [[0.4 0.15 0.55]],
		light_radius = 150,
      },

      damage                  = {
        default = 180,
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
      range                   = 320,
      reloadtime              = 2,
      rgbColor                = [[0.3 0 0.4]],
      soundStart              = [[weapon/laser/pulse_laser2]],
      soundStartVolume        = 11,
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
  
  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Constable]],
      blocking         = true,
      category         = [[corpses]],
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      object           = [[behe_coroner_dead.s3o]],
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP  = {
      description      = [[Debris - Constable]],
      blocking         = false,
      category         = [[heaps]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      object           = [[debris2x2c.s3o]],
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corfast = unitDef })
