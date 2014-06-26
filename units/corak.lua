unitDef = {
  unitname               = [[corak]],
  name                   = [[Bandit]],
  description            = [[Medium-Light Raider Bot]],
  acceleration           = 0.5,
  brakeRate              = 0.4,
  buildCostEnergy        = 75,
  buildCostMetal         = 75,
  buildPic               = [[CORAK.png]],
  buildTime              = 75,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[24 29 24]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô agressor]],
    description_es = [[Robot de invasión]],
    description_fr = [[Robot Pilleur]],
    description_it = [[Robot d'invasione]],
	description_de = [[Mittel-leichter Raider Roboter]],
	description_pl = [[Lekki bot]],
    helptext       = [[The Bandit outranges and is somewhat tougher than the Glaive, but still not something that you hurl against entrenched forces. Counter with riot units and LLTs.]],
    helptext_bp    = [[O AK é um rob? agressor. ? um pouco mais forte que seu equivalente de Nova, mas ainda algo que voç? n?o envia contra forças entrincheiradas. Defenda-se dele com unidades dispersadoras e torres de laser leve.]],
    helptext_es    = [[Como unidad de invasión, el Bandit sacrifica poder de fuego en favor de supervivencia. es un poco mas resistente de su euivalente Nova, pero como quiera no es para lanzarlo en contra de enemigos atrincherados. Se contrastan con unidades de alboroto y llt.]],
    helptext_fr    = [[Le Bandit est plus puissant que sa contre partie ennemie, le Glaive. Il n'est cependant pas tr?s puissant et ne passera pas contre quelques d?fenses: LLT ou ?meutiers. ]],
    helptext_it    = [[Come unita d'invasione, il Bandit sacrifica potenza di fuoco per sopravvivenza. ? pi? resistente del suo equivalente Nova, ma comnque non ? da mandare contro nemici ben difesi. Si contrastano con unita da rissa ed llt.]],
	helptext_de    = [[Als Raider opfert der Bandit die rohe Feuerkraft der Überlebensfähigkeit. Er ist etwas stärker als der Glaive, aber immer noch nicht stark genug, um gegen größere Kräfte zu bestehen. Mit Rioteinheiten und LLT entgegenwirken.]],
	helptext_pl    = [[Bandit jest szybkim i lekkim botem - jest troche wytrzymalszy niz jego odpowiednik Glaive. Nie jest jednak na tyle mocny, by mozna go bylo uzywac przeciwko obwarowanym przeciwnikom. Przegrywa w bezposrednim starciu z jednostkami wsparcia i wiezyczkami.]],
	modelradius    = [[12]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkerraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 250,
  maxSlope               = 36,
  maxVelocity            = 3,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB]],
  objectName             = [[mbot.s3o]],
  script				 = [[corak.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  sightDistance          = 500,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 18,
  turnRate               = 2500,
  upright                = true,

  weapons                = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    LASER = {
      name                    = [[Laser Blaster]],
      areaOfEffect            = 8,
      beamWeapon              = true,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 9.77,
        planes  = 9.77,
        subs    = 0.61,
      },

      duration                = 0.02,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
      fireStarter             = 50,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 245,
      reloadtime              = 0.1,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/small_laser_fire2]],
      soundTrigger            = true,
      targetMoveError         = 0.15,
      thickness               = 2.55,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 880,
    },

  },

  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Bandit]],
      blocking         = false,
      damage           = 250,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 30,
      object           = [[mbot_d.s3o]],
      reclaimable      = true,
      reclaimTime      = 30,
    },

    DEAD2 = {
      description      = [[Debris - Bandit]],
      blocking         = false,
      damage           = 250,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 30,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 30,
    },

    HEAP  = {
      description      = [[Debris - Bandit]],
      blocking         = false,
      damage           = 250,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 15,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 15,
    },

  },

}

return lowerkeys({ corak = unitDef })
