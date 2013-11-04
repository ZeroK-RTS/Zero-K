unitDef = {
  unitname               = [[armjeth]],
  name                   = [[Jethro]],
  description            = [[Anti-air Bot]],
  acceleration           = 0.5,
  brakeRate              = 0.32,
  buildCostEnergy        = 150,
  buildCostMetal         = 150,
  buildPic               = [[ARMJETH.png]],
  buildTime              = 150,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  cloakCost              = 0.1,
  cloakCostMoving        = 0.5,
  collisionVolumeOffsets = [[0 1 0]],
  collisionVolumeScales  = [[22 28 22]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    cloakstealth   = [[1]],
    description_bp = [[Robô anti-ar]],
    description_de = [[Flugabwehr Roboter]],
    description_es = [[Robot Antiaéreo]],
    description_fi = [[Ilmatorjuntarobotti]],
    description_fr = [[Robot Anti-air]],
    description_it = [[Robot da contraerea]],
    description_pl = [[Bot Przeciwlotniczy z Maskowaniem]],
    helptext       = [[Fast and fairly sturdy for its price, the Jethro is good budget mobile anti-air. It can cloak, allowing it to provide unexpected anti-air protection or escape ground forces it's defenseless against.]],
    helptext_bp    = [[Jethro ? um rob? barato dedicado a defesa anti-a?rea. est? entre defenders e packos, sem as fraquezas de nenhum deles, e pode com certeza proteger uma for?a m?vel, dando aos rob?s uma vantagem definitiva contra aeronaves. Nao pode se defender de unidades terrestres.]],
    helptext_de    = [[Durch seine Fähigkeit mobile Kräft vor Luftangriffen zu beschützen, gibt der Jethro den entsprechenden Einheiten einen wichtigen Vorteil gegenüber Lufteinheiten. Verteidigungslos gegenüber Landeinheiten.]],
    helptext_es    = [[Un paso entre un defender y un pack0 en términos de defensa antiaérea, sin sus debilidades, y con la abilidad de defender unidades móbiles bien, el Jethro ofrece una ventaja definitiva para los kbots contra aviones. No tiene defensas contra unidades de tierra.]],
    helptext_fi    = [[Kevyell? hakeutuvalla ohjuksella varustettu Jethro on tehokas nopeita, mutta kevyesti panssaroituja ilma-aluksia vastaan. Soveltuu hyvin yksik?iden puolustamiseen ketter?n liikkuvuutensa takia. Ei pysty ampumaan maayksik?it? kohti.]],
    helptext_fr    = [[Se situant entre le Defender et le Packo pour la d?fense a?rienne, en ayant la faiblaisse d'aucun des deux et pouvant offrire un d?fense d?cissive pour les forces mobile, le Jethro done un avantage d?finis pour les robots. Il est sans d?fense contre les unit?s terriennes.]],
    helptext_it    = [[Un passo tra un defender ed un pack0, senza le sue debolezze, e con l'abilitá di proteggere bene una forza mobile, il Jethro offre ai kbot un vantaggio decisivo contro aerei. Non ha difese contro forze terrestre.]],
    helptext_pl    = [[Szybki i dość wytrzymały jak na swoją cenę, Jethro jest w stanie zapewnić obronę przeciwlotniczą. Jest bezbronny przeciw wojskom lądowym, ale posiada opcję maskowania.]],
	modelradius    = [[11]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotaa]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  initCloaked            = true,
  leaveTracks            = true,
  maxDamage              = 550,
  maxSlope               = 36,
  maxVelocity            = 2.9,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SWIM FLOAT SUB HOVER]],
  objectName             = [[spherejeth.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:NONE]],
      [[custom:NONE]],
    },

  },

  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 17,
  turnRate               = 2200,
  upright                = true,

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
      cylinderTargeting       = 1,

	  customParams        	  = {
		isaa = [[1]],
	  },

      damage                  = {
        default = 2.09,
        planes  = 20.9,
        subs    = 1,
      },

      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.25,
      minIntensity            = 1,
      range                   = 700,
      reloadtime              = 0.3,
      rgbColor                = [[0 1 1]],
      soundStart              = [[weapon/laser/rapid_laser]],
      soundStartVolume        = 4,
      thickness               = 2.3,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2200,
    },

  },

  featureDefs            = {

    DEAD = {
      description      = [[Wreckage - Jethro]],
      blocking         = true,
      damage           = 550,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 60,
      object           = [[spherejeth_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
    },

    HEAP = {
      description      = [[Debris - Jethro]],
      blocking         = false,
      damage           = 550,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 30,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 30,
    },

  },

}

return lowerkeys({ armjeth = unitDef })
