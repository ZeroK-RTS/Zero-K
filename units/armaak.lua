unitDef = {
  unitname            = [[armaak]],
  name                = [[Archangel]],
  description         = [[Heavy Anti-Air Jumper]],
  acceleration        = 0.18,
  brakeRate           = 0.2,
  buildCostEnergy     = 550,
  buildCostMetal      = 550,
  buildPic            = [[ARMAAK.png]],
  buildTime           = 550,
  canMove             = true,
  category            = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[30 48 30]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylY]],
  corpse              = [[DEAD]],

  customParams        = {
    canjump            = 1,
    jump_range         = 400,
    jump_speed         = 6,
    jump_reload        = 10,
    jump_from_midair   = 0,

    description_bp = [[Robô anti-ar pesado]],
    description_de = [[Flugabwehr Springer]],
    description_fi = [[Korkeatehoinen ilmatorjuntarobotti]],
    description_fr = [[Marcheur Anti-Air Lourd]],
    description_pl = [[Ciezki robot przeciwlotniczy (skacze)]],
    helptext       = [[The Archangel packs twin AA lasers and an autocannon for slaying enemy aircraft rapidly. It can also jump to quickly access high ground or to escape.]],
	helptext_de    = [[Der Archangel besitzt ein Doppel-Anti-Air-Laser und eine automatische Kanone, um gegnerische Lufteinheiten zu zerstören. Der Archangel kann auch einen Sprung machen.]],
    helptext_bp    = [[]],
    helptext_fi    = [[Archangel:in kaksoislaserit sek? automaattitykki tuhoavat vihollisen ilma-alukset tehokkaasti ja nopeasti.]],
    helptext_fr    = [[L'Archangel est munis d'un laser double anti air et d'un autocannon similaire au packo pour pouvoir an?antire les avions enemis.]],
    helptext_pl    = [[Archangel posiada silne dzialko i lasery przeciwlotnicze, ktore zadaja lotnictwu ogromne straty. Posiada takze mozliwosc skoku.]],
	modelradius    = [[15]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[jumpjetaa]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  mass                = 236,
  maxDamage           = 1500,
  maxSlope            = 36,
  maxVelocity         = 2.017,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  moveState           = 0,
  noChaseCategory     = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName          = [[hunchback.s3o]],
  script			  = [[armaak.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  side                = [[ARM]],
  sightDistance       = 660,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 28,
  turnRate            = 1400,
  upright             = true,

  weapons             = {

    {
      def                = [[LASER]],
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[GUNSHIP FIXEDWING]],
    },

    {
      def                = [[EMG]],
      --badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    EMG           = {
      name                    = [[Anti-Air Autocannon]],
      accuracy                = 512,
      alphaDecay              = 0.7,
      areaOfEffect            = 8,
      canattackground         = false,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

	  customParams        	  = {
		isaa = [[1]],
	  },

      damage                  = {
        default = 0.8,
        planes  = 8,
        subs    = 0.5,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:ARCHPLOSION]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.8,
      interceptedByShieldType = 1,
      minbarrelangle          = -24,
      pitchtolerance          = 8192,
      predictBoost            = 1,
      proximityPriority       = 4,
      range                   = 1040,
      reloadtime              = 0.1,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      soundStart              = [[weapon/cannon/brawler_emg]],
      stages                  = 10,
      startsmoke              = [[0]],
      sweepfire               = false,
      tolerance               = 8192,
      turret                  = true,
      weaponTimer             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1500,
    },


    LASER         = {
      name                    = [[Anti-Air Laser Battery]],
      areaOfEffect            = 12,
      beamDecay               = 0.736,
      beamlaser               = 1,
      beamTime                = 0.01,
      beamttl                 = 15,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

	  customParams        	  = {
		isaa = [[1]],
	  },

      damage                  = {
        default = 1.67,
        planes  = 16.7,
        subs    = 0.94,
      },

      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.25,
      minIntensity            = 1,
      noSelfDamage            = true,
      pitchtolerance          = 8192,
      range                   = 820,
      reloadtime              = 0.1,
      rgbColor                = [[0 1 1]],
      soundStart              = [[weapon/laser/rapid_laser]],
      soundStartVolume        = 4,
      thickness               = 2.165,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2200,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Archangel]],
      blocking         = true,
      damage           = 1500,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      height           = [[15]],
      hitdensity       = [[100]],
      metal            = 220,
      object           = [[hunchback_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 220,
    },


    HEAP  = {
      description      = [[Debris - Archangel]],
      blocking         = false,
      damage           = 1500,
      energy           = 0,
      footprintX       = 4,
      footprintZ       = 4,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 110,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 110,
    },

  },

}

return lowerkeys({ armaak = unitDef })
