unitDef = {
  unitname               = [[shieldarty]],
  name                   = [[Racketeer]],
  description            = [[Disarming Artillery]],
  acceleration           = 0.25,
  brakeRate              = 0.25,
  buildCostEnergy        = 350,
  buildCostMetal         = 350,
  buildPic               = [[SHIELDARTY.png]],
  buildTime              = 350,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_pl = [[Artyleria rozbrajajaca]],
    helptext       = [[The Racketeer launches long range missiles that can disarm key enemy defenses or units before assaulting them. Only one Racketeer is needed to keep a target disarmed, so pick a different target for each Racketeer. It is excellent at depleting the energy of enemy shields and rendering large units harmless.]],
    helptext_pl    = [[Racketeer to wyrzutnia pociskow dalekiego zasiegu, ktore rozbrajaja trafione jednostki. Swietnie nadaje sie do unieszkodliwiania ciezkich jednostek i do wyczerpywania wrogich tarcz.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkerlrarty]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 950,
  maxSlope               = 36,
  maxVelocity            = 1.8,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP]],
  objectName             = [[dominator.s3o]],
  script                 = [[shieldarty.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:STORMMUZZLE]],
      [[custom:STORMBACK]],
    },

  },

  sightDistance          = 325,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1800,
  upright                = true,

  weapons                = {

    {
      def                = [[EMP_ROCKET]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },

  weaponDefs             = {
    EMP_ROCKET = {
      name                    = [[EMP Cruise Missile]],
      areaOfEffect            = 24,
      cegTag                  = [[disarmtrail]],
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        = {
	    disarmDamageMult = 1,
		disarmDamageOnly = 1,
		disarmTimer      = 8, -- seconds
	  
	  },
	  
      damage                  = {
        default        = 1500,
        planes         = 1500,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:WHITE_LIGHTNING_BOMB]],
      fireStarter             = 0,
      flighttime              = 12,
	  impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 2,
      model                   = [[wep_merl.s3o]],
      noSelfDamage            = true,
      paralyzer               = true,
      range                   = 940,
      reloadtime              = 5,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/vlaunch_emp_hit]],
      soundStart              = [[weapon/missile/missile_launch_high]],
      startvelocity           = 250,
--      texture1                = [[spark]], --flare
      texture3                = [[spark]], --flame
      tolerance               = 4000,
      tracks                  = true,
      turnRate                = 54000,
      weaponAcceleration      = 300,
      weaponTimer             = 1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 7000,
    },
  },

  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Racketeer]],
      blocking         = true,
      damage           = 950,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 140,
      object           = [[dominator_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 140,
    },

    HEAP  = {
      description      = [[Debris - Racketeer]],
      blocking         = false,
      damage           = 950,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 70,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 70,
    },

  },

}

return lowerkeys({ shieldarty = unitDef })
