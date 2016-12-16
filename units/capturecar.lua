unitDef = {
  unitname            = [[capturecar]],
  name                = [[Dominatrix]],
  description         = [[Capture Vehicle]],
  acceleration        = 0.0444,
  brakeRate           = 0.0385,
  buildCostEnergy     = 420,
  buildCostMetal      = 420,
  builder             = false,
  buildPic            = [[capturecar.png]],
  buildTime           = 420,
  canAttack           = false,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[26 26 50]],
  collisionVolumeType    = [[cylZ]],
  corpse              = [[DEAD]],

  customParams        = {
    post_capture_reload = 360,
    description_de = [[Kaperungsfahrzeug]],
    helptext       = [[The Dominatrix captures enemies, turning them against their former allies. Multiple Dominatrix can capture a single target faster, although only one becomes the controller. After taking control of a unit the Dominatrix cannot fire for 12 seconds. If a Dominatrix is destroyed all units it controls are freed.]],
	helptext_de    = [[Der Dominatrix erobert Einheiten, hetzt sie gegen die ehemaligen Verbündeten auf. Mehrere Dominatrixe können ein Ziel schneller erobern, obwohl nur einer von ihnen der Kontrolleur dieser Einheit wird. Nachdem eine gegnerische Einheit unter Kontrolle gebracht wurde, kann der Dominatrix für fünf Sekunden nicht schießen. Sobald ein Dominatrix zerstört wurde, sind alle Einheiten unter seiner Kontrolle wieder frei.]],
	modelradius    = [[13]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[vehiclespecial]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 820,
  maxSlope            = 18,
  maxVelocity         = 2.2,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP]],
  objectName          = [[corvrad_big.s3o]],
  script              = [[capturecar.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  sightDistance       = 550,
  trackOffset         = -7,
  trackStrength       = 5,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 26,
  turninplace         = 0,
  turnRate            = 420,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[CAPTURERAY]],
      badTargetCategory  = [[UNARMED FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    CAPTURERAY = {
      name                    = [[Capture Ray]],
      beamdecay               = 0.9,
      beamTime                = 1/30,
      beamttl                 = 3,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      customparams = {
        capture_scaling = 0,
        is_capture = 1,

		stats_hide_damage = 1, -- continuous laser
		stats_hide_reload = 1,
		
		light_radius = 120,
		light_color = [[0 0.6 0.15]],
      },

      damage                  = {
        default = 2.6,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      largeBeamLaser          = true,
      laserFlareSize          = 0,
      minIntensity            = 1,
      range                   = 450,
      reloadtime              = 1/30,
      rgbColor                = [[0 0.8 0.2]],
      scrollSpeed             = 2,
      soundStart              = [[weapon/laser/pulse_laser2]],
      soundStartVolume        = 0.5,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[dosray]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 4.2,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },

  },


  featureDefs         = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[corvrad_big_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ capturecar = unitDef })
