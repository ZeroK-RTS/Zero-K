unitDef = {
  unitname               = [[armjeth]],
  name                   = [[Jethro]],
  description            = [[Anti-air Bot]],
  acceleration           = 0.5,
  brakeRate              = 0.32,
  buildCostEnergy        = 100,
  buildCostMetal         = 100,
  builder                = false,
  buildPic               = [[ARMJETH.png]],
  buildTime              = 100,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[35 40 35]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô anti-ar]],
    description_es = [[Robot Antiaéreo]],
    description_fi = [[Ilmatorjuntarobotti]],
    description_fr = [[Robot Anti-air]],
    description_it = [[Robot da contraerea]],
	description_de = [[Flugabwehr Roboter]],
    helptext       = [[Fast and fairly sturdy for its price, the Jethro is good budget mobile anti-air. Defenseless vs. land forces.]],
    helptext_bp    = [[Jethro ? um rob? barato dedicado a defesa anti-a?rea. est? entre defenders e packos, sem as fraquezas de nenhum deles, e pode com certeza proteger uma for?a m?vel, dando aos rob?s uma vantagem definitiva contra aeronaves. Nao pode se defender de unidades terrestres.]],
    helptext_es    = [[Un paso entre un defender y un pack0 en términos de defensa antiaérea, sin sus debilidades, y con la abilidad de defender unidades móbiles bien, el Jethro ofrece una ventaja definitiva para los kbots contra aviones. No tiene defensas contra unidades de tierra.]],
    helptext_fi    = [[Kevyell? hakeutuvalla ohjuksella varustettu Jethro on tehokas nopeita, mutta kevyesti panssaroituja ilma-aluksia vastaan. Soveltuu hyvin yksik?iden puolustamiseen ketter?n liikkuvuutensa takia. Ei pysty ampumaan maayksik?it? kohti.]],
    helptext_fr    = [[Se situant entre le Defender et le Packo pour la d?fense a?rienne, en ayant la faiblaisse d'aucun des deux et pouvant offrire un d?fense d?cissive pour les forces mobile, le Jethro done un avantage d?finis pour les robots. Il est sans d?fense contre les unit?s terriennes.]],
    helptext_it    = [[Un passo tra un defender ed un pack0, senza le sue debolezze, e con l'abilitá di proteggere bene una forza mobile, il Jethro offre ai kbot un vantaggio decisivo contro aerei. Non ha difese contro forze terrestre.]],
	helptext_de    = [[Durch seine Fähigkeit mobile Kräft vor Luftangriffen zu beschützen, gibt der Jethro den entsprechenden Einheiten einen wichtigen Vorteil gegenüber Lufteinheiten. Verteidigungslos gegenüber Landeinheiten.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotaa]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 117,
  maxDamage              = 550,
  maxSlope               = 36,
  maxVelocity            = 3,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM LAND SINK SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName             = [[spherejeth.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:NONE]],
      [[custom:NONE]],
    },

  },

  side                   = [[ARM]],
  sightDistance          = 660,
  smoothAnim             = true,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 2200,
  upright                = true,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[AA_LASER]],
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[GUNSHIP FIXEDWING]],
    },

  },


  weaponDefs             = {

    AA_LASER      = {
      name                    = [[Anti-Air Laser]],
      areaOfEffect            = 12,
      beamDecay               = 0.736,
      beamTime                = 0.01,
      beamttl                 = 15,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargetting      = 1,

      damage                  = {
        default = 1.6,
        planes  = 16,
        subs    = 0.8,
      },

      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.25,
      minIntensity            = 1,
      pitchtolerance          = 8192,
      range                   = 760,
      reloadtime              = 0.4,
      rgbColor                = [[0 1 1]],
      soundStart              = [[weapon/laser/rapid_laser]],
      soundStartVolume        = 4,
      thickness               = 2.165,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2200,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Jethro]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 550,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 40,
      object           = [[spherejeth_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 40,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP  = {
      description      = [[Debris - Jethro]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 550,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 20,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 20,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armjeth = unitDef })
