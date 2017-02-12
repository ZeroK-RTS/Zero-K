unitDef = {
  unitname               = [[armjeth]],
  name                   = [[Gremlin]],
  description            = [[Cloaked Anti-Air Bot]],
  acceleration           = 0.5,
  brakeRate              = 0.32,
  buildCostEnergy        = 150,
  buildCostMetal         = 150,
  buildPic               = [[ARMJETH.png]],
  buildTime              = 150,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  cloakCost              = 0.1,
  cloakCostMoving        = 0.5,
  collisionVolumeOffsets = [[0 1 0]],
  collisionVolumeScales  = [[22 28 22]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Flugabwehr Roboter]],
    description_fr = [[Robot Anti-Air]],
    helptext       = [[Fast and fairly sturdy for its price, the Gremlin is good budget mobile anti-air. It can cloak, allowing it to provide unexpected anti-air protection or escape ground forces it's defenseless against.]],
    helptext_de    = [[Durch seine Fähigkeit mobile Kräft vor Luftangriffen zu beschützen, gibt der Gremlin den entsprechenden Einheiten einen wichtigen Vorteil gegenüber Lufteinheiten. Verteidigungslos gegenüber Landeinheiten.]],
    helptext_fr    = [[Se situant entre le Defender et le Razor pour la d?fense a?rienne, en ayant la faiblaisse d'aucun des deux et pouvant offrire un d?fense d?cissive pour les forces mobile, le Gremlin done un avantage d?finis pour les robots. Il est sans d?fense contre les unit?s terriennes.]],
	modelradius    = [[11]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotaa]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  initCloaked            = true,
  leaveTracks            = true,
  maxDamage              = 550,
  maxSlope               = 36,
  maxVelocity            = 2.9,
  maxWaterDepth          = 22,
  minCloakDistance       = 140,
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SWIM FLOAT SUB HOVER]],
  objectName             = [[spherejeth.s3o]],
	script		             = [[armjeth.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:NONE]],
      [[custom:NONE]],
    },

  },

  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 17,
  turnRate               = 2200,
  upright                = true,

  weapons                = {

    {
      def                = [[AA_LASER]],
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[GUNSHIP FIXEDWING]],
    },

  },

  weaponDefs             = {

    AA_LASER      = {
      name                    = [[Anti-Air Laser]],
      areaOfEffect            = 12,
      beamDecay               = 0.736,
      beamTime                = 1/30,
      beamttl                 = 15,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

	  customParams        	  = {
		isaa = [[1]],
		light_color = [[0.2 1.2 1.2]],
		light_radius = 120,
	  },

      damage                  = {
        default = 1.84,
        planes  = 18.4,
        subs    = 1,
      },

      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.25,
      minIntensity            = 1,
      range                   = 700,
      reloadtime              = 0.3,
      rgbColor                = [[0 1 1]],
      soundStart              = [[weapon/laser/rapid_laser]],
      soundStartVolume        = 4,
      thickness               = 2.3,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2200,
    },

  },

  featureDefs            = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[spherejeth_dead.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

}

return lowerkeys({ armjeth = unitDef })
