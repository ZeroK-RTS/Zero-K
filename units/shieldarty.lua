unitDef = {
  unitname               = [[shieldarty]],
  name                   = [[Racketeer]],
  description            = [[Disarming Artillery]],
  acceleration           = 0.25,
  brakeRate              = 0.75,
  buildCostEnergy        = 380,
  buildCostMetal         = 380,
  buildPic               = [[SHIELDARTY.png]],
  buildTime              = 380,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
    helptext       = [[The Racketeer launches long range missiles that can disarm key enemy defenses or units before assaulting them. Only one Racketeer is needed to keep a target disarmed, so pick a different target for each Racketeer. It is excellent at depleting the energy of enemy shields and rendering large units harmless.]],
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
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP UNARMED]],
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
      name                    = [[Disarm Cruise Missile]],
      areaOfEffect            = 24,
      cegTag                  = [[disarmtrail]],
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        = {
	    disarmDamageMult = 1,
		disarmDamageOnly = 1,
		disarmTimer      = 8, -- seconds
	  
		light_camera_height = 1500,
		light_color = [[1 1 1]],
	  },
	  
      damage                  = {
        default        = 1500,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:WHITE_LIGHTNING_BOMB]],
      fireStarter             = 0,
      flightTime              = 6,
	  impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 2,
      model                   = [[wep_merl.s3o]],
      noSelfDamage            = true,
	  paralyzer               = true, -- to deal no damage to wrecks
      range                   = 940,
      reloadtime              = 6,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/vlaunch_emp_hit]],
      soundHitVolume          = 9.0,
      soundStart              = [[weapon/missile/missile_launch_high]],
      soundStartVolume        = 11.0,
      startvelocity           = 250,
	  --texture1                = [[spark]], --flare
      texture3                = [[spark]], --flame
      tolerance               = 4000,
      tracks                  = true,
      turnRate                = 54000,
      weaponAcceleration      = 300,
      weaponTimer             = 1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1500,
    },
  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[dominator_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ shieldarty = unitDef })
