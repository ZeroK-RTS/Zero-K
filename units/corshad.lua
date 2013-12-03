unitDef = {
  unitname            = [[corshad]],
  name                = [[Shadow]],
  description         = [[Precision Bomber]],
  amphibious          = true,
  buildCostEnergy     = 300,
  buildCostMetal      = 300,
  builder             = false,
  buildPic            = [[CORSHAD.png]],
  buildTime           = 300,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[80 10 30]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],
  cruiseAlt           = 240,

  customParams        = {
    description_bp = [[Bombardeiro de precis?o]],
    description_fr = [[Bombardier de Précision]],
	description_de = [[Präzisionsbomber]],
	description_pl = [[Bombowiec precyzyjny]],
    helptext       = [[The Shadow drops a single high damage, low AoE energy bomb that is effective against stationary targets, but falls far too slowly to hit most mobiles.]],
    helptext_bp    = [[Shadow lança uma única bomba a cada ataque, com pouca área de efeito mas grande poder. Em matéria de custo-benefício, é eficiente contra alvos caros e imóveis, mas funciona mal contra unidades móveis principalmente devido a dificuldade de acertar um alvo móvel com uma única bomba.]],
    helptext_fr    = [[Le Shadow largue des bombes de haute précision, parfait pour les frappes chirurgicales comme une défense antimissile ou une tourelle genante, mais peu efficace contre une armée massive.]],
	helptext_de    = [[Der Shadow wirft eine einzige Bombe mit hohem Schaden ab. Ideal fungiert er dazu, einzelne, strategisch wichtige Gebäude wie z.B. Anti-Atom zu zerstören, um dann mit seinen Haupteinheiten einzufallen. Kleinere Einheiten werden aber nur schwelich getroffen und sollten von daher auf anderem Wege bekämpft werden.]],
	helptext_pl    = [[Shadow zrzuca pojedyncza bombe o wysokich obrazeniach i malym obszarze wybuchu. Swietnie nadaje sie do niszczenia ciezszych celow, jednak po kazdym zrzucie musi zaladowac nowa bombe na lotnisku lub stacji dozbrajania.]],
		modelradius    = [[10]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[bomberassault]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1380]],
  mass                = 234,
  maxAileron          = 0.026,
  maxAcc              = 0.5,
  maxDamage           = 1400,
  maxElevator         = 0.02,
  maxRudder           = 0.01,
  maxFuel             = 1000000,
  maxVelocity         = 7.2,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[corshad.s3o]],
  script			  = [[corshad.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:light_red]],
      [[custom:light_green]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 660,
  turnRadius          = 60,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[BOGUS_BOMB]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },


    {
      def                = [[ENERGYBOMB]],
      mainDir            = [[0 -1 0]],
      maxAngleDif        = 180,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },
	
    {
      def                = [[SHIELD_CHECK]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },

  },


  weaponDefs          = {

    BOGUS_BOMB = {
      name                    = [[Fake Bomb]],
      areaOfEffect            = 80,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0,
      },

      dropped                 = true,
      edgeEffectiveness       = 0,
      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      manualBombSettings      = true,
      model                   = [[]],
      myGravity               = 1000,
      range                   = 10,
      reloadtime              = 10,
      scale                   = [[0]],
      weaponType              = [[AircraftBomb]],
    },

    ENERGYBOMB = {
      name                    = [[Energy Bomb]],
      areaOfEffect            = 40,
      avoidFriendly           = false,
      cegTag                  = [[sonictrail]],
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      
      damage                  = {
	default = 800,
      },
      
      explosionGenerator      = [[custom:bluegreennovaexplo]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      myGravity               = 0.001,
      noSelfDamage            = true,
      range                   = 200,
      reloadtime              = 12,
      rgbColor                = [[0.2 0.8 0.6]],
      separation              = 0.5,
      size                    = 8,
      sizeDecay               = 0.05,
      soundHit                = [[explosion/ex_large11]],
      soundStart              = [[weapon/heatray_fire1]],
      soundTrigger            = true,
      tolerance               = 10000,
      stages                  = 20,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 100,
    },
	
    SHIELD_CHECK = {
      name                    = [[Fake Poker For Shields]],
      areaOfEffect            = 0,
      avoidFeature            = false,
      avoidFriendly           = false,
      collideFeature          = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = -1E-06,
      },

      explosionGenerator      = [[custom:NONE]],
      flightTime              = 2,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      range                   = 600,
      reloadtime              = 2,
      rgbColor                = [[0.5 1 1]],
      size                    = 1E-06,
      startVelocity           = 2000,
      turret                  = true,
      trajectoryHeight        = 1.5,
      weaponAcceleration      = 2000,
      weaponTimer             = 0,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 2000,
      waterWeapon             = true,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Shadow]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1400,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 180,
      object           = [[spirit_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 180,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP  = {
      description      = [[Debris - Shadow]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1400,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 90,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 90,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corshad = unitDef })
