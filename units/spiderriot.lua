unitDef = {
  unitname               = [[spiderriot]],
  name                   = [[Redback]],
  description            = [[Riot Spider]],
  acceleration           = 0.22,
  brakeRate              = 0.22,
  buildCostEnergy        = 280,
  buildCostMetal         = 280,
  buildPic               = [[spideraa.png]],
  buildTime              = 280,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Aranha anti-aérea]],
    description_fr = [[Araignée AA]],
	description_de = [[Flugabwehr Spinne]],
	description_pl = [[Pajak przeciwlotniczy]],
    helptext       = [[An all-terrain AA unit that supports other spiders against air with its medium-range missiles.]],
    helptext_bp    = [[Uma unidade escaladora anti-aérea. Use para proteger outras aranhas contra ataques aéreos.]],
    helptext_fr    = [[Une unité araignée lourde anti-air, son missile a décollage vertical est lent à tirer mais très efficace contre des cibles aériennes blindées.]],
	helptext_de    = [[Eine geländegängige Flugabwehreinheit, die andere Spinnen mit ihren mittellangen Raketen gegen Luftangriffe verteidigt.]],
	helptext_pl    = [[Jako pajak, Tarantula jest w stanie wejsc na kazde wzniesienie, aby zapewnic wsparcie przeciwlotnicze swoimi rakietami sredniego zasiegu.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[spideraa]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 900,
  maxSlope               = 72,
  maxVelocity            = 1.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT3]],
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName             = [[spiderriot.s3o]],
  script				 = [[spiderriot.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShort]],
  trackWidth             = 55,
  turnRate               = 1700,

  weapons                = {

    {
      def                = [[PARTICLEBEAM]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },
  
  weaponDefs             = {

    PARTICLEBEAM = {
      name                    = [[Auto Particle Beam]],
      beamDecay               = 0.85,
      beamTime                = 0.01,
      beamttl                 = 45,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 60,
        subs    = 3,
      },

      explosionGenerator      = [[custom:flash1red]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 7.5,
      minIntensity            = 1,
      pitchtolerance          = 8192,
      range                   = 300,
      reloadtime              = 0.33,
      rgbColor                = [[1 0 0]],
      soundStart              = [[weapon/laser/mini_laser]],
      soundStartVolume        = 6,
      thickness               = 5,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },
	
  },

  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Tarantula]],
      blocking         = true,
      damage           = 1200,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      metal            = 112,
      object           = [[tarantula_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 160,
    },

    HEAP  = {
      description      = [[Debris - Tarantula]],
      blocking         = false,
      damage           = 1200,
      energy           = 0,
      footprintX       = 3,
      footprintZ       = 3,
      metal            = 56,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
    },

  },

}

return lowerkeys({ spiderriot = unitDef })
