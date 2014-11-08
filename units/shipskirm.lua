unitDef = {
  unitname               = [[shipskirm]],
  name                   = [[Enforcer]],
  description            = [[Missile Cruiser (Skirmisher/Artillery)]],
  acceleration           = 0.039,
  activateWhenBuilt      = true,
  brakeRate              = 0.115,
  buildAngle             = 16384,
  buildCostEnergy        = 900,
  buildCostMetal         = 900,
  builder                = false,
  buildPic               = [[CORROY.png]],
  buildTime              = 900,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 10 0]],
  collisionVolumeScales  = [[48 48 110]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Destroyer Lance-Missile (Support/Anti-Air)]],
	description_de = [[Leichter Raketenkreuzer]],
	description_pl = [[Krazownik rakietowy]],
    helptext       = [[This cruiser packs powerful, long-range missiles, useful for bombarding sea and shore targets. Beware of subs and Corvettes.]],
    helptext_fr    = [[Le Enforcer embarque deux batteries de missiles: une lourde et longue port?e pour d?truire les navires et les installation c?ti?res, ainsi qu'un batterie longue port?e anti-air. Il est rapide mais peu solide.]],
	helptext_de    = [[Dieser Kreuzer vereint schlagkräftige, weitreichende Raketen, die nützlich zur Bombardierung von See- oder Küstenzielen, sowie gegen Flugzeuge, sind. Achte aber auf U-Boote und Korvetten.]],
	helptext_pl    = [[Enforcer posiada potezne rakiety o dobrym zasiegu, ktore swietnie nadaja sie do niszczenia wszystkiego, co plywa po morzu lub znajduje sie na jego brzegu, a nawet zestrzeliwania lotnictwa. Nie jest jednak w stanie celowac w jednostki podwodne i ma dlugi czas przeladowania.]],
	turnatfullspeed = [[1]],
    modelradius     = [[24]],
  },

  explodeAs              = [[BIG_UNIT]],
  floater                = true,
  footprintX             = 5,
  footprintZ             = 5,
  iconType               = [[enforcer]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 2800,
  maxVelocity            = 2.4,
  minCloakDistance       = 350,
  minWaterDepth          = 10,
  movementClass          = [[BOAT4]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[logsiren.s3o]],
  scale                  = [[0.6]],
  script		         = [[shipskirm.cob]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNIT]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:MISSILE_EXPLOSION]],
      [[custom:MEDMISSILE_EXPLOSION]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 700,
  smoothAnim             = true,
  turninplace            = 0,
  turnRate               = 230,
  waterline              = 4,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[MISSILE]],
	  badTargetCategory	 = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    MISSILE = {
      name                    = [[Heavy 4x Guided Missile]],
      areaOfEffect            = 128,
      cegTag                  = [[KBOTROCKETTRAIL]],
      craterBoost             = 1,
      craterMult              = 2,
	  burst					  = 4,
	  burstRate				  = 0.3,

      damage                  = {
        default = 220,
        subs    = 37.5,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:smallxamelimpact]],
      fireStarter             = 20,
      flightTime              = 5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      impactOnly              = false,
      interceptedByShieldType = 2,
      model                   = [[wep_m_havoc.s3o]],
      noSelfDamage            = true,
      range                   = 690,
      reloadtime              = 5.5,
      smokeTrail              = false,
      soundHit                = [[weapon/bomb_hit]],
      soundHitVolume          = 2.5,
      soundStart              = [[weapon/missile/banisher_fire]],
      soundStartVolume        = 2.5,
      startsmoke              = [[1]],
      startVelocity           = 100,
      tolerance               = 9000,
      tracks                  = true,
      trajectoryHeight        = 0.7,
      turnRate                = 2100,
      turret                  = true,
      weaponAcceleration      = 70,
      weaponTimer             = 5,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
    },

  },


  featureDefs            = {

    DEAD = {
      description      = [[Wreckage - Enforcer]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 2800,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 5,
      footprintZ       = 5,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 360,
      object           = [[logsiren_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 360,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP = {
      description      = [[Debris - Enforcer]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2800,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 180,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 180,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ shipskirm = unitDef })
