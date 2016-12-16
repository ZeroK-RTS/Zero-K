unitDef = {
  unitname            = [[corshad]],
  name                = [[Raven]],
  description         = [[Precision Bomber]],
  amphibious          = true,
  brakerate           = 0.4,
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
  collisionVolumeType    = [[box]],
  corpse              = [[DEAD]],
  cruiseAlt           = 220,

  customParams        = {
    description_fr = [[Bombardier de Précision]],
	description_de = [[Präzisionsbomber]],
    helptext       = [[The Raven drops a single high damage, low AoE bomb. Cost for cost, nothing quite matches it for taking out that antinuke or Reaper, but you should look elsewhere for something to use against smaller mobiles.]],
    helptext_fr    = [[Le Raven largue des bombes de haute précision, parfait pour les frappes chirurgicales comme une défense antimissile ou une tourelle genante, mais peu efficace contre une armée massive.]],
	helptext_de    = [[Der Raven wirft eine einzige Bombe mit hohem Schaden ab. Ideal fungiert er dazu, einzelne, strategisch wichtige Gebäude wie z.B. Anti-Atom zu zerstören, um dann mit seinen Haupteinheiten einzufallen. Kleinere Einheiten werden aber nur schwelich getroffen und sollten von daher auf anderem Wege bekämpft werden.]],
		modelradius    = [[15]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[bomberassault]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1380]],
  maxAcc              = 0.5,
  maxBank             = 0.6,
  maxDamage           = 1000,
  maxElevator         = 0.02,
  maxRudder           = 0.009,
  maxFuel             = 1000000,
  maxPitch            = 0.4,
  maxVelocity         = 7.8,
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
  sightDistance       = 660,
  turnRadius          = 160,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[BOGUS_BOMB]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },


    {
      def                = [[BOMBSABOT]],
      mainDir            = [[0 -1 0]],
      maxAngleDif        = 90,
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },
	
	{
      def                = [[SHIELD_CHECK]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
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

      edgeEffectiveness       = 0,
      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      model                   = [[]],
      myGravity               = 1000,
      range                   = 10,
      reloadtime              = 10,
      weaponType              = [[AircraftBomb]],
    },


    BOMBSABOT  = {
      name                    = [[Guided Bomb]],
      areaOfEffect            = 32,
      avoidFeature            = false,
      avoidFriendly           = false,
      cegTag                  = [[KBOTROCKETTRAIL]],
      collideFeature          = false,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,
	  cylinderTargeting	      = 1,

	  customParams        	  = {
		light_color = [[1.1 0.9 0.45]],
		light_radius = 220,
	  },

      damage                  = {
        default = 800.1,
        planes  = 800.1,
        subs    = 800.1,
      },
	  
	  customParams            = {
		torp_underwater = [[corshad_a_torpedo]],
	  },

      explosionGenerator      = [[custom:xamelimpact]],
      fireStarter             = 70,
      flightTime              = 3,
	  heightmod				  = 0,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_b_paveway.s3o]],
	  leadLimit               = 20,
      range                   = 150,
      reloadtime              = 5,
      smokeTrail              = false,
      soundHit                = [[weapon/bomb_hit]],
      soundStart              = [[weapon/bomb_drop]],
      startVelocity           = 200,
      tolerance               = 8000,
      tracks                  = false,
      turnRate                = 2500,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 50,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 200,
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
	  model                   = [[emptyModel.s3o]],
      range                   = 460,
      reloadtime              = 0.1,
      rgbColor                = [[0 0 0]],
	  startVelocity           = 2000,
	  texture1                = [[null]],
	  texture2                = [[null]],
	  texture3                = [[null]],
      turret                  = true,
	  trajectoryHeight        = 1.5,
      weaponAcceleration      = 2000,
	  weaponType              = [[MissileLauncher]],
      weaponVelocity          = 2000,
	  waterWeapon             = true,
    },

	A_TORPEDO = {
      name                    = [[Torpedo BombSabot For Bubble Effect]],
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 800,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      fixedLauncher           = true,
      flightTime              = 1.5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_b_paveway.s3o]],
	  numbounce               = 4,
      range                   = 225,
      reloadtime              = 5,
      soundHit                = [[explosion/wet/ex_underwater]],
      soundStart              = [[weapon/torpedo]],
      startVelocity           = 200,
      tracks                  = false,
      turnRate                = 3750,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 50,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 200,
    },	
  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[spirit_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ corshad = unitDef })
