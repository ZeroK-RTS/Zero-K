unitDef = {
  unitname            = [[armah]],
  name                = [[Swatter]],
  description         = [[Anti-Air Hovercraft]],
  acceleration        = 0.096,
  bmcode              = [[1]],
  brakeRate           = 0.112,
  buildCostEnergy     = 200,
  buildCostMetal      = 200,
  builder             = false,
  buildPic            = [[ARMAH.png]],
  buildTime           = 200,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[HOVER]],
  corpse              = [[DEAD]],

  customParams        = {
    description_es = [[Hovercraft Anti-Aérea]],
    description_fr = [[Hovercraft Anti-Air]],
    description_it = [[Hovercraft Anti-Aerea]],
    helptext       = [[The Anti-Air Hovercraft is more manouverable than a boat, and can go on land, which makes it a interesting Anti-Air defense]],
    helptext_es    = [[El Hovercraft anti-aérea es mas manejable que una nave, y puede ir sobre tierra, esto lo hace una defensa anti-aérea interesante]],
    helptext_fr    = [[Le Swatter est plus maniable qu'un navire et peut aller sur terre, cela en fait une défense Anti-Air interressante.]],
    helptext_it    = [[L'Hovercraft Anti-Aereo ? pi? manovrabile che una barca, e pu? anche andare sulla terra, ci? lo rende una difesa anti-aerea interessante]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoveraa]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 100,
  maxDamage           = 959,
  maxSlope            = 36,
  maxVelocity         = 3.54,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM LAND SINK SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName          = [[ARMAH]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HOVERS_ON_GROUND]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 660,
  smoothAnim          = true,
  sonarDistance       = 350,
  steeringmode        = [[1]],
  TEDClass            = [[TANK]],
  turninplace         = 0,
  turnRate            = 490,
  workerTime          = 0,

  weapons             = {

    {
      def               = [[BOGUS_MISSILE]],
      badTargetCategory = [[SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
    },


    {
      def                = [[ARMAH_WEAPON]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    ARMAH_WEAPON  = {
      name                    = [[Homing Missiles]],
      areaOfEffect            = 48,
      canattackground         = false,
      craterBoost             = 1,
      craterMult              = 2,
      cylinderTargetting      = 1,

      damage                  = {
        default = 11.5,
        planes  = 115,
        subs    = 5.75,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      flightTime              = 4,
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[missile]],
      noSelfDamage            = true,
      range                   = 700,
      reloadtime              = 2,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[OTAunit/XPLOMED2]],
      soundStart              = [[OTAunit/ROCKHVY2]],
      startsmoke              = [[1]],
      startVelocity           = 450,
      tolerance               = 10000,
      tracks                  = true,
      turnRate                = 63000,
      turret                  = true,
      weaponAcceleration      = 164,
      weaponTimer             = 5,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 670,
    },


    BOGUS_MISSILE = {
      name                    = [[Missiles]],
      areaOfEffect            = 48,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 0,
      },

      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      metalpershot            = 0,
      range                   = 800,
      reloadtime              = 0.5,
      renderType              = 1,
      startVelocity           = 450,
      tolerance               = 9000,
      turnRate                = 33000,
      turret                  = true,
      weaponAcceleration      = 101,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 650,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Swatter]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 959,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 80,
      object           = [[ARMAH_DEAD]],
      reclaimable      = true,
      reclaimTime      = 80,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Swatter]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 959,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 80,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Swatter]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 959,
      energy           = 0,
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 40,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 40,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armah = unitDef })
