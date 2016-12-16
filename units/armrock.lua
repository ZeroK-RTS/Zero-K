unitDef = {
  unitname               = [[armrock]],
  name                   = [[Rocko]],
  description            = [[Skirmisher Bot (Direct-Fire)]],
  acceleration           = 0.32,
  brakeRate              = 0.2,
  buildCostEnergy        = 90,
  buildCostMetal         = 90,
  buildPic               = [[ARMROCK.png]],
  buildTime              = 90,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 -5 0]],
  collisionVolumeScales  = [[26 39 26]],
  collisionVolumeType    = [[CylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Skirmisher Roboter (Direkt-Feuer)]],
    description_fr = [[Robot Tirailleur]],
    helptext       = [[The Rocko's low damage, low speed unguided rockets are redeemed by their range. They are most effective in a line formation, firing at maximum range and kiting the enemy. Counter them by attacking them with fast units which can close range and dodge their missiles.]],
    helptext_de    = [[Rockos geringer Schaden und die geringe Geschwindigkeit der Raketen wird durch seine Reichweite aufgehoben. Sie sind an Fronten sehr effektiv, da sie dort mit maximaler Reichweite agieren können. Kontere sie, indem du schnelle Einheiten schickst oder Verteidigung hinter einer Terraformmauer baust.]],
    helptext_fr    = [[La faible puissance de feux et la lenteur des roquettes non guid?s du Rocko son conpens?es par sa port?e de tire. Ils sont le plus ?fficace en formation de ligne, en tirant ? port?e maximale. Contrez le en attaquant avec des unit?s rapide ou bien placer vos d?fenses derriere un mure t?rraform?.]],
	modelradius    = [[13]],
	midposoffset   = [[0 6 0]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotskirm]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 390,
  maxSlope               = 36,
  maxVelocity            = 2.2,
  maxWaterDepth          = 20,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB]],
  objectName             = [[sphererock.s3o]],
  script                 = "armrock.lua",
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:rockomuzzle]],
    },

  },

  sightDistance          = 523,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 18,
  turnRate               = 2200,
  upright                = true,

  weapons                = {

    {
      def                = [[BOT_ROCKET]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    BOT_ROCKET = {
      name                    = [[Rocket]],
      areaOfEffect            = 48,
      burnblow                = true,
      cegTag                  = [[missiletrailredsmall]],
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
		light_camera_height = 1600,
		light_color = [[0.90 0.65 0.30]],
		light_radius = 250,
      },

      damage                  = {
        default = 180,
        subs    = 9,
      },

      fireStarter             = 70,
      flightTime              = 2.45,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_ajax.s3o]],
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 455,
      reloadtime              = 3.8,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/sabot_hit]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/sabot_fire]],
      soundStartVolume        = 7,
      startVelocity           = 190,
      texture2                = [[darksmoketrail]],
      tracks                  = false,
      turret                  = true,
      weaponAcceleration      = 190,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 190,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[rocko_d.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ armrock = unitDef })
