unitDef = {
  unitname            = [[corsh]],
  name                = [[Dagger]],
  description         = [[Fast Attack Hovercraft]],
  acceleration        = 0.066,
  activateWhenBuilt   = true,
  brakeRate           = 0.0835,
  buildCostMetal      = 80,
  builder             = false,
  buildPic            = [[CORSH.png]],
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 -2 0]],
  collisionVolumeScales  = [[19 19 36]],
  collisionVolumeType    = [[cylZ]],  
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Hovercraft d'Attaque Éclair]],
    description_de = [[Schnellangriff Luftkissenboot]],
    helptext       = [[The Dagger is the hover plant's scout. It provides a cheap, disposable method of getting intel, and can also hit economic targets of opportunity. Its light Gauss gun can also hit underwater targets.]],
    helptext_fr    = [[Le Dagger est petit, maniable, rapide et n'a qu'une faible puissance de feu. Idéal pour les attaques surprises depuis la mer, il surprendra bien des ennemis. Son blindage est cependant trop faible pour faire face r une quelquonque résistance.]],
    helptext_de    = [[Der Dagger ist der Aufklärer unter den Luftkissenbooten. Es bietet dir eine kostengünstige, entbehrliche Möglichkeit deinen Feind frühzeitig um seine Rohstoffquellen zu bringen. Es kann auch U-Booten schiessen.]],
  },

  explodeAs           = [[SMALL_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[hoverraider]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 300,
  maxSlope            = 36,
  maxVelocity         = 4.8,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SUB]],
  objectName          = [[CORSH.s3o]],
  script              = "corsh.lua",
  selfDestructAs      = [[SMALL_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HOVERS_ON_GROUND]],
      [[custom:flashmuzzle1]],
    },

  },

  sightDistance       = 560,
  sonarDistance       = 560,
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

      customParams = {
        single_hit = true,
		
		light_camera_height = 1200,
		light_radius = 180,
      },
	  
      damage                  = {
        default = 110.1,
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
      range                   = 210,
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
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[corsh_dead.s3o]],
    },

    HEAP  = {
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

}

return lowerkeys({ corsh = unitDef })
