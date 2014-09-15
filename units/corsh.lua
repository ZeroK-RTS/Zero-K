unitDef = {
  unitname            = [[corsh]],
  name                = [[Dagger]],
  description         = [[Fast Attack Hovercraft]],
  acceleration        = 0.066,
  activateWhenBuilt   = true,
  brakeRate           = 0.0835,
  buildCostEnergy     = 90,
  buildCostMetal      = 90,
  builder             = false,
  buildPic            = [[CORSH.png]],
  buildTime           = 90,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 -2 0]],
  collisionVolumeScales  = [[19 19 36]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylZ]],  
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Hovercraft d'Attaque Éclair]],
    description_de = [[Schnellangriff Luftkissenboot]],
    description_pl = [[Lekki poduszkowiec]],
    helptext       = [[The Dagger is the hover plant's scout. It provides a cheap, disposable method of getting intel, and can also hit economic targets of opportunity. Its light Phase gun can also hit underwater targets.]],
--    helptext_fr    = [[Le Dagger est petit, maniable, rapide et n'a qu'une faible puissance de feu. Idéal pour les attaques surprises depuis la mer, il surprendra bien des ennemis. Son blindage est cependant trop faible pour faire face r une quelquonque résistance.]],
--    helptext_de    = [[Der Dagger ist der Aufklärer unter den Luftkissenbooten. Es bietet dir eine kostengünstige, entbehrliche Möglichkeit deinen Feind frühzeitig um seine Rohstoffquellen zu bringen. Es kann auch U-Booten schiessen.]],
    helptext_pl    = [[Dagger to lekki poduszkowiec, ktory nadaje sie zarowno do zwiadu, jak i atakowania przeciwnika. Jest w stanie atakowac rowniez cele podwodne.]],
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
  noChaseCategory     = [[TERRAFORM FIXEDWING SUB]],
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
  sonarDistance       = 250,
  smoothAnim          = true,
  turninplace         = 0,
  turnRate            = 673,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[GAUSS]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SUB SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    GAUSS = {
      name                    = [[Phase Carbine]],
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
        default = 110,
        planes  = 110,
      },
      
      customParams = {
        single_hit = true,
      },

      explosionGenerator      = [[custom:gauss_hit_l]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      noExplode               = true,
      noSelfDamage            = true,
      numbounce               = 40,
      range                   = 220,
      reloadtime              = 3,
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
      turret                  = true,
      waterweapon			  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2200,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Dagger]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 300,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 36,
      object           = [[corsh_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 36,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Dagger]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 300,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 36,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 36,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Dagger]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 300,
      energy           = 0,
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 18,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 18,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corsh = unitDef })
