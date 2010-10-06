unitDef = {
  unitname            = [[armsh]],
  name                = [[Skimmer]],
  description         = [[Fast Attack Hovercraft]],
  acceleration        = 0.132,
  bmcode              = [[1]],
  brakeRate           = 0.112,
  buildCostEnergy     = 110,
  buildCostMetal      = 110,
  builder             = false,
  buildPic            = [[ARMSH.png]],
  buildTime           = 110,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[HOVER]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Hovercraft d'Attaque ?clair]],
    helptext       = [[The Skimmer is a fast, expendable armed scout. Though its main purpose is reconnaissance, it can also raid undefended economy structures.]],
    helptext_fr    = [[Le Skimmer est petit, maniable, rapide et n'a qu'une faible puissance de feu. Id?al pour les attaques surprises depuis la mer, il surprendra bien des ennemis. Son blindage est cependant trop faible pour faire face ? une quelquonque r?sistance.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[SMALL_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverraider]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 55,
  maxDamage           = 260,
  maxSlope            = 36,
  maxVelocity         = 4.69,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[armsh.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[SMALL_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HOVERS_ON_GROUND]],
      [[custom:emg_shells_l]],
      [[custom:flashmuzzle1]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 582,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[TANK]],
  turninplace         = 0,
  turnRate            = 640,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    EMG = {
      name                    = [[EMG]],
      areaOfEffect            = 8,
      burst                   = 2,
      burstrate               = 0.12,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 6,
        planes  = 6,
        subs    = 0.3,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:EMG_HIT]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 180,
      reloadtime              = 0.14,
      renderType              = 0,
      rgbColor                = [[1 0.95 0.4]],
      size                    = 1.75,
      soundStart              = [[flashemg]],
      sprayAngle              = 1180,
      startsmoke              = [[0]],
      tolerance               = 10000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 750,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Skimmer]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 260,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 44,
      object           = [[armsh_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 44,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Skimmer]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 260,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 44,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 44,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Skimmer]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 260,
      energy           = 0,
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 22,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 22,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armsh = unitDef })
