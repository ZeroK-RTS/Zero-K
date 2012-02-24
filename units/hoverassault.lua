unitDef = {
  unitname            = [[hoverassault]],
  name                = [[Halberd]],
  description         = [[Blockade Runner Hover]],
  acceleration        = 0.048,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.043,
  buildCostEnergy     = 240,
  buildCostMetal      = 240,
  builder             = false,
  buildPic            = [[hoverassault.png]],
  buildTime           = 240,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[50 25 55]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],  
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Hovecraft d'Assaut Lourd]],
	description_de = [[Blockadebrecher Gleiter]],
    helptext       = [[The Halberd buttons down into its armored hull when not firing, offering 4x damage resistance. Its slow, short-ranged weapon is unsuitable for use against highly mobile targets.]],
	helptext_de    = [[Der Halberd zieht sich in seine gepanzerte Hülle zurück, sobald er nicht mehr feuert, was ihm einen exzellenten Schadenswiderstand bietet. Seine langsame, kurzreichweitige Waffe ist ungeeignet für den Einsatz gegen hochmobile Ziele.]],
  },

  damageModifier      = 0.25,
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverassault]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  mass                = 184,
  maxDamage           = 1250,
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
  turninplace         = 0,
  turnRate            = 616,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[ROCKET]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
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
        default = 130,
        planes  = 130,
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
      range                   = 300,
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
      weaponTimer             = 2.2,
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
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 96,
      object           = [[hoverassault_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 96,
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
      metal            = 48,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 48,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ hoverassault = unitDef })
