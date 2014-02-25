unitDef = {
  unitname               = [[spiderriot]],
  name                   = [[Redback]],
  description            = [[Riot Spider]],
  acceleration           = 0.22,
  brakeRate              = 0.22,
  buildCostEnergy        = 400,
  buildCostMetal         = 400,
  buildPic               = [[spideraa.png]],
  buildTime              = 400,
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
      def                = [[HE_EMG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },
  
  weaponDefs             = {


    HE_EMG = {
      name                    = [[Heavy Pulse MG]],
      accuracy                = 350,
      alphaDecay              = 0.7,
      areaOfEffect            = 96,
      burnblow                = true,
      burst                   = 3,
      burstrate               = 0.1,
      craterBoost             = 0.15,
      craterMult              = 0.3,

      damage                  = {
        default = 36.7,
        planes  = 36.7,
        subs    = 1.8,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:EMG_HIT_HE]],
      firestarter             = 70,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 270,
      reloadtime              = 0.52,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      soundHit                = [[weapon/cannon/emg_hit]],
      soundStart              = [[weapon/heavy_emg]],
      stages                  = 10,
      targetMoveError         = 0,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 550,
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
      metal            = 160,
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
      metal            = 80,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
    },

  },

}

return lowerkeys({ spiderriot = unitDef })
