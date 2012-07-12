unitDef = {
  unitname            = [[corshad]],
  name                = [[Shadow]],
  description         = [[Precision Bomber]],
  amphibious          = true,
  buildCostEnergy     = 450,
  buildCostMetal      = 450,
  builder             = false,
  buildPic            = [[CORSHAD.png]],
  buildTime           = 450,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 -5]],
  collisionVolumeScales  = [[85 20 40]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],
  cruiseAlt           = 200,

  customParams        = {
    description_bp = [[Bombardeiro de precis?o]],
    description_fr = [[Bombardier de Précision]],
	description_de = [[Präzisionsbomber]],
    helptext       = [[The Shadow drops a single high damage, low AoE bomb. Cost for cost, nothing quite matches it for taking out that antinuke or Reaper, but you should look elsewhere for something to use against smaller mobiles.]],
    helptext_bp    = [[Shadow lança uma única bomba a cada ataque, com pouca área de efeito mas grande poder. Em matéria de custo-benefício, é eficiente contra alvos caros e imóveis, mas funciona mal contra unidades móveis principalmente devido a dificuldade de acertar um alvo móvel com uma única bomba.]],
    helptext_fr    = [[Le Shadow largue des bombes de haute précision, parfait pour les frappes chirurgicales comme une défense antimissile ou une tourelle genante, mais peu efficace contre une armée massive.]],
	helptext_de    = [[Der Shadow wirft eine einzige Bombe mit hohem Schaden ab. Ideal fungiert er dazu, einzelne, strategisch wichtige Gebäude wie z.B. Anti-Atom zu zerstören, um dann mit seinen Haupteinheiten einzufallen. Kleinere Einheiten werden aber nur schwelich getroffen und sollten von daher auf anderem Wege bekämpft werden.]],
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
  maxAcc              = 0.5,
  maxDamage           = 1200,
  maxFuel             = 1000000,
  maxVelocity         = 8.8,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[spirit.s3o]],
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
  turnRadius          = 350,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[BOGUS_BOMB]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },


    {
      def                = [[BOMBSABOT]],
      mainDir            = [[0 -1 0]],
      maxAngleDif        = 120,
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
      commandfire             = true,
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


    BOMBSABOT  = {
      name                    = [[Guided Bomb]],
      areaOfEffect            = 32,
      avoidFeature            = false,
      avoidFriendly           = false,
      burnblow                = true,
      cegTag                  = [[KBOTROCKETTRAIL]],
      collideFriendly         = false,
      commandfire             = true,
      craterBoost             = 1,
      craterMult              = 2,
	  cylinderTargeting	  = 1,

      damage                  = {
        default = 1200,
        planes  = 1200,
        subs    = 1200,
      },

      explosionGenerator      = [[custom:xamelimpact]],
      fireStarter             = 70,
      flightTime              = 2,
	  heightmod				  = 0,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_b_paveway.s3o]],
      range                   = 120,
      reloadtime              = 5,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = false,
      soundHit                = [[weapon/bomb_hit]],
      soundStart              = [[weapon/bomb_drop]],
      startsmoke              = [[1]],
      startVelocity           = 300,
      targetMoveError         = 0,
      tolerance               = 8000,
      tracks                  = true,
      turnRate                = 2500,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 300,
      weaponTimer             = 0.1,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
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
      range                   = 850,
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
      damage           = 1250,
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
      damage           = 1250,
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
