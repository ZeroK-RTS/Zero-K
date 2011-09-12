unitDef = {
  unitname               = [[firewalker]],
  name                   = [[Firewalker]],
  description            = [[Fire Support Walker (Artillery/Skirmish)]],
  acceleration           = 0.12,
  brakeRate              = 0.24,
  buildCostEnergy        = 1250,
  buildCostMetal         = 1250,
  builder                = false,
  buildPic               = [[firewalker.png]],
  buildTime              = 1250,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[48 47 48]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Roboter mit Feuerunterstützung (Artillerie/Skrimish)]],
    helptext       = [[The Firewalker's medium range mortars immolate a small area, denying use of that terrain for brief periods of time. The bot itself is somewhat clumsy and slow to maneuver.]],
	helptext_de    = [[Der Firewalk verschießt seine Mörser auf mittlerer Distanz und erzeugt in den betroffenen Arealen eine Unbrauchbarkeit des Geländes für kurze Zeiträume. Die Einheit selber ist etwas schwerfällig und langsam im Manövrieren.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[walkerarty]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maneuverleashlength    = [[640]],
  mass                   = 347,
  maxDamage              = 1250,
  maxSlope               = 36,
  maxVelocity            = 1.9,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[firewalker.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:shellshockflash]],
      [[custom:SHELLSHOCKSHELLS]],
      [[custom:SHELLSHOCKGOUND]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 660,
  smoothAnim             = true,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.6,
  trackType              = [[ComTrack]],
  trackWidth             = 33,
  turnRate               = 600,
  upright                = true,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[NAPALM_MORTAR]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    NAPALM_MORTAR = {
      name                    = [[Napalm Mortar]],
      accuracy                = 400,
      areaOfEffect            = 256,
      craterBoost             = 1,
      craterMult              = 2,

	  customParams        	  = {
	    setunitsonfire = "1",
		burntime = 180,
	  },
	  
      damage                  = {
        default = 80,
        planes  = 80,
        subs    = 4,
      },

      explosionGenerator      = [[custom:firewalker_impact]],
      firestarter             = 180,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.1,
      noSelfDamage            = true,
      projectiles             = 2,
      range                   = 900,
      reloadtime              = 18,
      renderType              = 4,
      rgbColor                = [[1 0.5 0.2]],
      size                    = 8,
      soundHit                = [[weapon/cannon/wolverine_hit]],
      soundStart              = [[weapon/cannon/wolverine_fire]],
      sprayangle              = 2048,
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 320,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Firewalker]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 630,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 500,
      object           = [[firewalker_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 500,
      world            = [[All Worlds]],
    },

    HEAP  = {
      description      = [[Debris - Firewalker]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 650,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 250,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 250,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ firewalker = unitDef })
