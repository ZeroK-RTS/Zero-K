unitDef = {
  unitname               = [[corgator]],
  name                   = [[Scorcher]],
  description            = [[Raider Vehicle]],
  acceleration           = 0.057,
  brakeRate              = 0.07,
  buildCostEnergy        = 130,
  buildCostMetal         = 130,
  builder                = false,
  buildPic               = [[corgator.png]],
  buildTime              = 130,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND TOOFAST]],
  collisionVolumeOffsets = [[0 -5 0]],
  collisionVolumeScales  = [[26 26 36]],
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[V?hicule Pilleur]],
	description_de = [[Raiderfahrzeug]],
    helptext       = [[Capable of taking damage and dishing it out, the Scorcher is a versatile unit that remains very useful for more than just raiding, though it pays the price in manueverability and in cost. Though able to hold its own in combat, it is no match for anti-swarm and riot units or defenses. The Scorcher's heatray deals more damage up close.]],
    helptext_fr    = [[Le Scorcher est rapide et solide. ?quip? d'une mitrailleuse laser il saura faire face de lui m?me ? un combat et ses nano-robots auto r?g?nerants se chargeront de le remettre sur pied pour la suite. Particuli?rement allergique aux anti-nu?es et au ?meutiers.]],
    helptext_de    = [[Der Scorcher ist fähig Schaden einzustecken und auszuteilen, was ihn zu einer vielseitigen Einheit macht, welche für mehr als nur Überfälle nützlich ist. All das aber zum Preis der Manövrierfähigkeit und der Kosten. Obwohl er sich im Kampf meist gut schlägt, taugt er nichts gegen Antischwarm- und Rioteinheiten oder Verteidigung. Der Scorcher mehr Schaden verursacht, je naher er ist.]],
	modelradius    = [[10]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[vehicleraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 420,
  maxSlope               = 18,
  maxVelocity            = 3.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TANK2]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[corgator_512.s3o]],
  script                 = [[corgator.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_ORANGE_SMALL]],
    },

  },
  sightDistance          = 400,
  trackOffset            = 5,
  trackStrength          = 5,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 21,
  turninplace            = 0,
  turnRate               = 703,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[HEATRAY]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    HEATRAY = {
      name                    = [[Heat Ray]],
      accuracy                = 512,
      areaOfEffect            = 20,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
		light_camera_height = 1500,
		light_color = [[0.9 0.4 0.12]],
		light_radius = 180,
		light_fade_time = 25,
		light_fade_offset = 10,
		light_beam_mult_frames = 9,
		light_beam_mult = 8,
      },

      damage                  = {
        default = 31.4,
        planes  = 31.4,
        subs    = 1.5,
      },

      duration                = 0.3,
      dynDamageExp            = 1,
      dynDamageInverted       = false,
      explosionGenerator      = [[custom:HEATRAY_HIT]],
      fallOffRate             = 1,
      fireStarter             = 90,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lodDistance             = 10000,
      noSelfDamage            = true,
      proximityPriority       = 10,
      range                   = 270,
      reloadtime              = 0.1,
      rgbColor                = [[1 0.1 0]],
      rgbColor2               = [[1 1 0.25]],
      soundStart              = [[weapon/heatray_fire]],
      thickness               = 3,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 500,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[gatorwreck.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ corgator = unitDef })
