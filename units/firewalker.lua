unitDef = {
  unitname               = [[firewalker]],
  name                   = [[Firewalker]],
  description            = [[Fire Support Walker (Artillery/Skirmish)]],
  acceleration           = 0.12,
  brakeRate              = 0.24,
  buildCostEnergy        = 1200,
  buildCostMetal         = 1200,
  builder                = false,
  buildPic               = [[firewalker.png]],
  buildTime              = 1200,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Roboter mit Feuerunterst?zung (Artillerie/Skrimish)]],
    description_pl = [[Robot wsparcia artyleryjskiego]],
    helptext       = [[The Firewalker's medium range mortars immolate a small area, denying use of that terrain for brief periods of time. The bot itself is somewhat clumsy and slow to maneuver.]],
	helptext_de    = [[Der Firewalker verschießt seine Mörser auf mittlerer Distanz und erzeugt in den betroffenen Arealen eine Unbrauchbarkeit des Geländes f? kurze Zeiträume. Die Einheit selber ist etwas schwerfällig und langsam im Manövrieren.]],
	helptext_pl    = [[Firewalker uzywa swoich dzial sredniego zasiegu do podpalania wyznaczonych obszarow, co zadaje obrazenia jednostkom, ktore tam pozostana.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[fatbotarty]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 347,
  maxDamage              = 1250,
  maxSlope               = 36,
  maxVelocity            = 2.1,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[firewalker.s3o]],
  script				 = [[firewalker.lua]],
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
      def                = [[NAPALM_SPRAYER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    NAPALM_MORTAR = {
      name                    = [[Napalm Mortar]],
      accuracy                = 400,
      areaOfEffect            = 256,
	  avoidFeature            = false,
      craterBoost             = 1,
      craterMult              = 2,
      cegTag                  = [[flamer]],

	  customParams        	  = {
	    setunitsonfire = "1",
		burntime = 60,

		area_damage = 1,
		area_damage_radius = 128,
		area_damage_dps = 20,
		area_damage_duration = 20,

		--lups_heat_fx = [[firewalker]],
	  },
	  
      damage                  = {
        default = 80,
        planes  = 80,
        subs    = 4,
      },

      explosionGenerator      = [[custom:napalm_firewalker]],
      firestarter             = 180,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.1,
      projectiles             = 2,
      range                   = 900,
      reloadtime              = 12,
      rgbColor                = [[1 0.5 0.2]],
      size                    = 8,
      soundHit                = [[weapon/cannon/wolverine_hit]],
      soundStart              = [[weapon/cannon/wolverine_fire]],
      sprayangle              = 1024,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 320,
    },
	
	NAPALM_SPRAYER = {
      name                    = [[Napalm Mortar]],
      accuracy                = 400,
      areaOfEffect            = 128,
	  avoidFeature            = false,
      craterBoost             = 1,
      craterMult              = 2,
      cegTag                  = [[flamer]],

	  customParams        	  = {
	    setunitsonfire = "1",
		burntime = 60,

		area_damage = 1,
		area_damage_radius = 64,
		area_damage_dps = 20,
		area_damage_duration = 16,

		--lups_heat_fx = [[firewalker]],
	  },
	  
      damage                  = {
        default = 80,
        planes  = 80,
        subs    = 4,
      },

      explosionGenerator      = [[custom:napalm_firewalker_small]],
      firestarter             = 180,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.1,
      projectiles             = 10,
      range                   = 900,
      reloadtime              = 12,
      rgbColor                = [[1 0.5 0.2]],
      size                    = 5,
      soundHit                = [[weapon/cannon/wolverine_hit]],
      soundStart              = [[weapon/cannon/wolverine_fire]],
      sprayangle              = 2500,
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
      damage           = 1250,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 480,
      object           = [[firewalker_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 480,
    },

    HEAP  = {
      description      = [[Debris - Firewalker]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1250,
      energy           = 0,
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 240,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 240,
    },

  },

}

return lowerkeys({ firewalker = unitDef })
