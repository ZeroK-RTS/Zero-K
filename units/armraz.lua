unitDef = {
  unitname               = [[armraz]],
  name                   = [[Razorback]],
  description            = [[Assault/Riot Strider]],
  acceleration           = 0.156,
  brakeRate              = 0.262,
  buildCostEnergy        = 4000,
  buildCostMetal         = 4000,
  builder                = false,
  buildPic               = [[ARMRAZ.png]],
  buildTime              = 4000,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[65 65 65]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Mechwarrior d'Assaut]],
	description_de = [[Sturm/Riot Läufer]],
	description_pl = [[Robot szturmowy]],
    helptext       = [[The Razorback features twin multi-barelled pulse cannons for extreme crowd control, as well as a head-mounted short-range laser for close in work. Don't use recklessly - its short range can be a real liability.]],
    helptext_fr    = [[Le Razorback est un Robot au blindage lourd arm? de deux Miniguns et d'un canon laser continu ind?pendant. Son blindage et sa pr?cision le rendent utile contre nimporte quel type d'arm?e, ? l'exception des unit?s longues port?e. V?ritable rouleau compresseur, il est pourtant le moins cher et le plus faible des Mechs.]],
	helptext_de    = [[Der Razorback ist ausgerüstet mit doppelläufien Impulskanonen als Gegenwehr gegen viele Einheiten, sowie einen, am Kopf befestigten, Laser für den Nahbereich. Nutze ihn nicht unbesonnen - seine kurze Reichweite erzeugt eine große Anfälligkeit.]],
  },

  explodeAs              = [[CRAWL_BLASTSML]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3generic]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 11000,
  maxSlope               = 36,
  maxVelocity            = 1.9,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT5]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[ARMRAZ]],
  seismicSignature       = 4,
  selfDestructAs         = [[CRAWL_BLASTSML]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:WARMUZZLE]],
      [[custom:razorbackejector]],
    },

  },
  sightDistance          = 578,
  turnRate               = 515,
  upright                = true,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[RAZORBACK_EMG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[RAZORBACK_EMG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
      slaveTo            = 1,
    },


    {
      def                = [[LASER]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    LASER         = {
      name                    = [[High Intensity Laserbeam]],
      areaOfEffect            = 8,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 25,
        planes  = 25,
        subs    = 1.25,
      },

      explosionGenerator      = [[custom:flash1green]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 5.43,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 350,
      reloadtime              = 0.1,
      rgbColor                = [[0 1 0]],
      soundStart              = [[weapon/laser/laser_burn10]],
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 5.43426627982104,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },


    RAZORBACK_EMG = {
      name                    = [[Heavy Pulse Autocannon]],
      alphaDecay              = 0.7,
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 12,
        planes  = 12,
        subs    = 0.6,
      },

      explosionGenerator      = [[custom:EMG_HIT]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 400,
      reloadtime              = 0.03,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      size                    = 1.7,
      soundHit                = [[weapon/cannon/emg_hit]],
      soundStart              = [[weapon/heavy_emg]],
      soundStartVolume        = 4,
      sprayAngle              = 2048,
      stages                  = 10,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 550,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[DEAD2]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[ARMRAZ_DEAD]],
    },


    DEAD2 = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

}

return lowerkeys({ armraz = unitDef })
