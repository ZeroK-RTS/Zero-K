unitDef = {
  unitname               = [[armsptk]],
  name                   = [[Recluse]],
  description            = [[Skirmisher Spider (Indirect Fire)]],
  acceleration           = 0.26,
  brakeRate              = 0.78,
  buildCostEnergy        = 280,
  buildCostMetal         = 280,
  buildPic               = [[ARMSPTK.png]],
  buildTime              = 280,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Skrimish Spinne (Indirektes Feuer)]],
    description_fr = [[Araignée à salve de missiles]],
    helptext       = [[An all terrain missile launching unit. Climb walls with this spider walker and take your enemy by surprise. The unguided rockets cannot hit a rapidly jinking target, but they have a fairly long range.]],
    helptext_de    = [[Eine raketenschiessende Einheit, die jedes Terrain betreten kann. Klettere mit der Spinne an Waeden hoch und ueberrasche deine Gegner mit Angriffen aus unmoeglichen Lagen. Die Raketen ohne Zielfuehrung treffen aber selten schnelle Ziele, trotzdem darf man ihre grosse Reichweite nicht vernachlaessigen.]],
    helptext_fr    = [[Une unité lance-missiles tout-terrain. Grimpe le long des parois et les reliefs impraticables pour surprendre vos ennemis. Les salves de roquettes non-guidées ne peuvent atteindre une cible très mobile que par chance mais elles ont une portée importante. Peut être aisément éliminée si utilisée sans soutien.]],
	midposoffset   = [[0 -5 0]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[spiderskirm]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 650,
  maxSlope               = 72,
  maxVelocity            = 1.6,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT3]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP SATELLITE SUB]],
  objectName             = [[recluse.s3o]],
  script				 = [[armsptk.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  sightDistance          = 627,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShort]],
  trackWidth             = 52,
  turnRate               = 1600,

  weapons                = {

    {
      def                = [[ADV_ROCKET]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER FIXEDWING GUNSHIP]],
    },

  },

  weaponDefs             = {

    ADV_ROCKET = {
      name                    = [[Rocket Volley]],
      areaOfEffect            = 48,
      burst                   = 3,
      burstrate               = 0.3,
      cegTag                  = [[missiletrailredsmall]],
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
		light_camera_height = 2500,
		light_color = [[0.90 0.65 0.30]],
		light_radius = 250,
      },

      damage                  = {
        default = 135,
        planes  = 135,
        subs    = 7,
      },

      edgeEffectiveness       = 0.5,
      fireStarter             = 70,
      flightTime              = 4,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[recluse_missile.s3o]],
      noSelfDamage            = true,
      range                   = 570,
      reloadtime              = 4,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_small13]],
      soundStart              = [[weapon/missile/missile_fire4]],
      soundTrigger            = true,
      startVelocity           = 150,
      texture2                = [[darksmoketrail]],
      trajectoryHeight        = 1.5,
      turnRate                = 4000,
      turret                  = true,
      weaponAcceleration      = 150,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
      wobble                  = 9000,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[recluse_wreck.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

}

return lowerkeys({ armsptk = unitDef })
