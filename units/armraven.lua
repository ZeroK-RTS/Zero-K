unitDef = {
  unitname               = [[armraven]],
  name                   = [[Catapult]],
  description            = [[Heavy Saturation Artillery Strider]],
  acceleration           = 0.1092,
  brakeRate              = 0.1942,
  buildCostEnergy        = 3500,
  buildCostMetal         = 3500,
  builder                = false,
  buildPic               = [[ARMRAVEN.png]],
  buildTime              = 3500,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[65 65 65]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Schwerer Raketen-Artillerie Läufer]],
    description_fr = [[Mechwarrior Lance-Roquette Lourd]],
    helptext       = [[The Catapult is an MLRS strider. It can launch a volley of rockets that guarantees the destruction of almost anything in the target area, then quickly retreat behind friendly forces.]],
    helptext_de    = [[Das Catapult ist ein Läufer mit Mehrfachraketenwerfer-Artilleriesystem. Es kann eine Salve von Raketen starten, was die Zerstörung von fast allem im Zielgebiet garantieren kann. Infolgedessen kann es sich schnell in freundliches Gebiet hinter den Fronteinheiten zurückziehen.]],
    helptext_fr    = [[Le Catapult est le plus fragile des Mechwarriors. Il est cependant trcs rapide et tire un nombre incalculable de roquettes r grande distance grâce r ses deux batteries lance missiles embarquées. Une seule salve peut tapisser une large zone, et rares sont les survivant.]],
  },

  explodeAs              = [[ATOMIC_BLASTSML]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3arty]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 4000,
  maxSlope               = 36,
  maxVelocity            = 1.8,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT4]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName             = [[catapult.s3o]],
  script		 = [[armraven.cob]],
  seismicSignature       = 4,
  selfDestructAs         = [[ATOMIC_BLASTSML]],
  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 36,
  turnRate               = 990,
  upright                = true,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[ROCKET]],
	  badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

  },


  weaponDefs             = {

    ROCKET = {
      name                    = [[Long-Range Rocket Battery]],
      areaOfEffect            = 128,
	  avoidFeature            = false,
	  avoidGround             = false,
      burst                   = 20,
      burstrate               = 0.1,
      cegTag                  = [[RAVENTRAIL]],
      craterBoost             = 1,
      craterMult              = 2,
	  
	  customParams        	  = {
		light_camera_height = 2500,
		light_color = [[0.35 0.17 0.04]],
		light_radius = 400,
	  },
	  
      damage                  = {
        default = 220.5,
        planes  = 220.5,
        subs    = 11,
      },

      dance                   = 20,
      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:MEDMISSILE_EXPLOSION]],
      fireStarter             = 100,
      flightTime              = 8,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[hobbes.s3o]],
      noSelfDamage            = true,
      projectiles             = 2,
      range                   = 1450,
      reloadtime              = 30,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/rapid_rocket_hit]],
      soundHitVolume          = 5,
      soundStart              = [[weapon/missile/rapid_rocket_fire]],
      soundStartVolume        = 5,
      startVelocity           = 100,
      tolerance               = 512,
      trajectoryHeight        = 1,
      turnRate                = 2500,
      turret                  = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 250,
      wobble                  = 7000,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[catapult_wreck.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3b.s3o]],
    },

  },

}

return lowerkeys({ armraven = unitDef })
