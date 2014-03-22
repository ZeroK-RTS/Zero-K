unitDef = {
  unitname               = [[nebula]],
  name                   = [[Nebula]],
  description            = [[Atmospheric Mothership]],
  acceleration           = 0.04,
  activateWhenBuilt      = true,
  airStrafe              = 0,
  amphibious             = true,
  bankingAllowed         = false,
  brakeRate              = 0.6,
  buildCostEnergy        = 6000,
  buildCostMetal         = 6000,
  builder                = false,
  buildPic               = [[nebula.png]],
  buildTime              = 6000,
  canAttack              = true,
  canFly                 = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collide                = true,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[40 50 220]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[box]],

  corpse                 = [[DEAD]],
  cruiseAlt              = 300,

  customParams           = {
   -- description_bp = [[Fortaleza voadora]],
   -- description_fr = [[Forteresse Volante]],
    description_de = [[Lufttraeger]], -- "aerial carrier"
    description_pl = [[Statek-matka]],
    helptext       = [[As maneuverable as a brick and barely armed itself, the Nebula is still a fearsome force due to its ability to survive long-range attacks due to its shield, as well as shred lesser foes with its fighter-drone complement.]],
   -- helptext_bp    = [[Aeronave flutuante armada com lasers para ataque terrestre. Muito cara e muito poderosa.]],
   -- helptext_fr    = [[La Forteresse Volante est l'ADAV le plus solide jamais construit, est ?quip?e de nombreuses tourelles laser, elle est capable de riposter dans toutes les directions et d'encaisser des d?g?ts importants. Id?al pour un appuyer un assaut lourd ou monopiler l'Anti-Air pendant une attaque a?rienne.]],
    helptext_de    = [[Die Nebula ist stark und ungeschickt, aber sie hat ein Schild um sich zu schutzen und kann seine einige Jaegerdrohne herstellen.]],
    helptext_pl    = [[Nebula jest wytrzymala i ma problemy ze zwrotnoscia niczym latajaca cegla, jednak jest ona uzbrojona w oddzial dronow bojowych oraz tarcze obszarowa do ich ochrony.]],
   modelradius    = [[40]],
  },

  explodeAs              = [[LARGE_BUILDINGEX]],
  floater                = true,
  footprintX             = 5,
  footprintZ             = 5,
  hoverAttack            = true,
  iconType               = [[supergunship]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maneuverleashlength    = [[500]],
  mass                   = 886,
  maxDamage              = 17500,
  maxVelocity            = 3.3,
  minCloakDistance       = 150,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[picarrier.dae]],
  scale                  = [[1]],
  script                 = [[nebula.lua]],
  seismicSignature       = 0,
  selfDestructAs         = [[LARGE_BUILDINGEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_RED]],
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 633,
  turnRate               = 100,
  upright                = true,
  workerTime             = 0,
  
  weapons                = {

    {
      def                = [[KROWLASER]],
	  mainDir            = [[0.38 0.1 0.2]],
	  maxAngleDif        = 180,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def         = [[COR_SHIELD_SMALL]],
      maxAngleDif = 1,
    },
  },


  weaponDefs             = {

    KROWLASER  = {
      name                    = [[Laserbeam]],
      areaOfEffect            = 8,
      avoidFeature            = false,
      canattackground         = true,
      collideFriendly         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 36,
        subs    = 1.8,
      },

      duration                = 0.02,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      range                   = 450,
      reloadtime              = 0.2,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/heavylaser_fire2]],
	  soundStartVolume		  = 0.7,
      soundTrigger            = true,
      targetMoveError         = 0.2,
      thickness               = 3.25,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2300,
    },

    COR_SHIELD_SMALL = {
      name                    = [[Energy Shield]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[1 0.1 0.1]],
      shieldGoodColor         = [[0.1 0.1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 3600,
      shieldPowerRegen        = 50,
      shieldPowerRegenEnergy  = 9,
      shieldRadius            = 350,
      shieldRepulser          = false,
      smartShield             = true,
      texture1                = [[shield3mist]],
      visibleShield           = true,
      visibleShieldHitFrames  = 4,
      visibleShieldRepulse    = true,
      weaponType              = [[Shield]],
    },
  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Nebula]],
      blocking         = true,
      category         = [[corpses]],
	  collisionVolumeOffsets = [[0 0 0]],
	  collisionVolumeScales  = [[80 30 80]],
	  collisionVolumeTest    = 1,
	  collisionVolumeType    = [[ellipsoid]],	  
      damage           = 17500,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 5,
      footprintZ       = 5,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 2400,
      object           = [[krow_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 2400,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Nebula]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 17500,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 1200,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 1200,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ nebula = unitDef })
