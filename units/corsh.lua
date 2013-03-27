unitDef = {
  unitname            = [[corsh]],
  name                = [[Scrubber]],
  description         = [[Fast Attack Hovercraft]],
  acceleration        = 0.066,
  brakeRate           = 0.0835,
  buildCostEnergy     = 85,
  buildCostMetal      = 85,
  builder             = false,
  buildPic            = [[CORSH.png]],
  buildTime           = 85,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[35 18 50]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],  
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Hovercraft d'Attaque Éclair]],
	description_de = [[Schnellangriff Luftkissenboot]],
    helptext       = [[The Scrubber is the hover plant's scout. It provides a cheap, disposable method of getting intel, and can also hit economic targets of oppurtunity.]],
    helptext_fr    = [[Le Scrubber est petit, maniable, rapide et n'a qu'une faible puissance de feu. Idéal pour les attaques surprises depuis la mer, il surprendra bien des ennemis. Son blindage est cependant trop faible pour faire face r une quelquonque résistance. ]],
	helptext_de    = [[Der Scrubber ist der Aufklärer unter den Luftkissenbooten. Es bietet dir eine kostengünstige, entbehrliche Möglichkeit deinen Feind frühzeitig um seine Rohstoffquellen zu bringen.]],
  },

  explodeAs           = [[SMALL_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[hoverraider]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  mass                = 97,
  maxDamage           = 300,
  maxSlope            = 36,
  maxVelocity         = 4.8,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[CORSH.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[SMALL_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HOVERS_ON_GROUND]],
      [[custom:flashmuzzle1]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 450,
  smoothAnim          = true,
  turninplace         = 0,
  turnRate            = 673,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[GAUSS]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    GAUSS = {
      name                    = [[Gauss Cannon]],
      alphaDecay              = 0.12,
      areaOfEffect            = 16,
	  avoidfeature            = false,
      bouncerebound           = 0.15,
      bounceslip              = 1,
      burst                   = 1,
      cegTag                  = [[gauss_tag_l]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 90,
        planes  = 90,
        subs    = 4.5,
      },

      explosionGenerator      = [[custom:gauss_hit_l]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      lineOfSight             = true,
      minbarrelangle          = [[-15]],
      noExplode               = true,
      noSelfDamage            = true,
      numbounce               = 40,
      range                   = 220,
      reloadtime              = 3,
      renderType              = 4,
      rgbColor                = [[0.5 1 1]],
      separation              = 0.5,
      size                    = 0.8,
      sizeDecay               = -0.1,
      soundHit                = [[weapon/gauss_hit]],
      soundHitVolume          = 2.5,
      soundStart              = [[weapon/gauss_fire]],
	  soundTrigger            = true,
      soundStartVolume        = 2,
      sprayangle              = 400,
      stages                  = 32,
      startsmoke              = [[1]],
      turret                  = true,
      waterbounce             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2200,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Scrubber]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 300,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 34,
      object           = [[corsh_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 34,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Scrubber]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 300,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 34,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 34,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Scrubber]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 300,
      energy           = 0,
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 17,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 17,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corsh = unitDef })
