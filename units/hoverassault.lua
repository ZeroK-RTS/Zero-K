unitDef = {
  unitname            = [[hoverassault]],
  name                = [[Halberd]],
  description         = [[Assault Hover]],
  acceleration        = 0.048,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.043,
  buildCostEnergy     = 250,
  buildCostMetal      = 250,
  builder             = false,
  buildPic            = [[hoverassault.png]],
  buildTime           = 250,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[HOVER]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Hovecraft d'Assaut Lourd]],
    helptext       = [[The Halberd is a heavy-duty assault hovertank, the Can of the sea. It is slow and short-ranged, making it easy prey for skirmishers - however, anything it gets close to is expected to die very quickly.]],
    helptext_fr    = [[Équivalent des mers du Can, le Halberd est etrememnt résistant et posscde une portée de tir trcs réduite.]],
  },

  damageModifier      = 0.15,
  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverassault]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 180,
  maxDamage           = 1200,
  maxSlope            = 36,
  maxVelocity         = 3.2,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[hoverassault.s3o]],
  onoffable           = true,
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 385,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[TANK]],
  turninplace         = 0,
  turnRate            = 616,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[ROCKET]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    ROCKET = {
      name                    = [[Rocket]],
      areaOfEffect            = 48,
      cegTag                  = [[missiletrailredsmall]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 140,
        planes  = 140,
        subs    = 7,
      },

      fireStarter             = 70,
      flightTime              = 2.2,
      guidance                = false,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      model                   = [[wep_m_ajax.s3o]],
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 270,
      reloadtime              = 1.2,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[.1]],
      smokeTrail              = true,
      soundHit                = [[weapon/missile/sabot_hit]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/sabot_fire]],
      soundStartVolume        = 7,
      startsmoke              = [[1]],
      startVelocity           = 150,
      texture2                = [[darksmoketrail]],
      tracks                  = false,
      trajectoryHeight        = 0.05,
      turret                  = true,
      weaponAcceleration      = 130,
      weaponTimer             = 3,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 130,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Halberd]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 1200,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 100,
      object           = [[hoverassault_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Halberd]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1200,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 100,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Halberd]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1200,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 50,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 50,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ hoverassault = unitDef })
