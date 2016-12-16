unitDef = {
  unitname               = [[cormist]],
  name                   = [[Slasher]],
  description            = [[Deployable Missile Vehicle (must stop to fire)]],
  acceleration           = 0.0354,
  brakeRate              = 0.0358,
  buildCostEnergy        = 140,
  buildCostMetal         = 140,
  builder                = false,
  buildPic               = [[CORMIST.png]],
  buildTime              = 140,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 5 0]],
  collisionVolumeScales  = [[26 30 36]],
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Camion Lance-Missile]],
	description_de = [[Unterstütung/Flugabwehr Laster (muss zum Feuern anhalten)]],
    helptext       = [[Keep the Slasher at maximum range to harass the opponent's units. The Slasher's missiles track, so they are ideal to kill fast-moving raiders and crawling bombs. It is able to hit air, but is only really useful against fighters. Cannot fire over obstacles, and does poorly if enemies, particularly assault units, are allowed to close range. Unlike skirmishers, the Slasher cannot fire while moving.]],
    helptext_fr    = [[Le Slasher est un camion Tirailleur. Sa trcs grande portée compense un peu son manque de puissance de feu. Capable de tirer en l'air ou au sol, il saura quand meme trouver sa place dans votre armée.]],
	helptext_de    = [[Halte deinen Slasher immer auf maximaler Distanz zum Feind, um diesen am besten zu belagern. Seine Raketen sind gelenkt und somit ideal, um sich schnell bewegende Einheiten oder Crawling Bomben zu vernichten. Er kann sowohl Land-, als auch Lufteinheiten treffen, aber nicht über Wände und Hügel schießen. Außerdem versagt er kläglich, sobald sich Feinde dicht am ihm befinden. Im Gegensatz zu dem meisten normalen Skirmishern, kann der Slasher nicht Feuern, wenn er sich bewegt.]],
	modelradius    = [[13]],
	chase_everything = [[1]], -- Does not get stupidtarget added to noChaseCats
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[vehiclesupport]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 560,
  maxSlope               = 18,
  maxVelocity            = 2.8,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TANK3]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[cormist_512.s3o]],
  script                 = [[cormist.lua]],
  pushResistant          = 0,
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:SLASHMUZZLE]],
      [[custom:SLASHREARMUZZLE]],
    },

  },
  sightDistance          = 660,
  trackOffset            = -6,
  trackStrength          = 5,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 30,
  turninplace            = 0,
  turnRate               = 486,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[CORTRUCK_MISSILE]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    CORTRUCK_MISSILE = {
      name                    = [[Homing Missiles]],
      areaOfEffect            = 48,
      avoidFeature            = true,
      cegTag                  = [[missiletrailyellow]],
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
		light_camera_height = 2000,
		light_radius = 200,
      },

      damage                  = {
        default = 40,
        subs    = 2,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      flightTime              = 3,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_frostshard.s3o]],
      range                   = 600,
      reloadtime              = 0.75,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med17]],
      soundStart              = [[weapon/missile/missile_fire11]],
      startVelocity           = 450,
      texture2                = [[lightsmoketrail]],
      tolerance               = 8000,
      tracks                  = true,
      turnRate                = 33000,
      turret                  = true,
      weaponAcceleration      = 109,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 545,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[cormist_dead_new.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

}

return lowerkeys({ cormist = unitDef })
