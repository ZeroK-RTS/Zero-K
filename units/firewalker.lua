unitDef = {
  unitname               = [[firewalker]],
  name                   = [[Firewalker]],
  description            = [[Saturation Artillery Walker]],
  acceleration           = 0.12,
  brakeRate              = 0.24,
  buildCostEnergy        = 900,
  buildCostMetal         = 900,
  builder                = false,
  buildPic               = [[firewalker.png]],
  buildTime              = 900,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Artillerieroboter für Sättigungsfeuer]],
    helptext       = [[The Firewalker's medium range mortars immolate a small area, denying use of that terrain for brief periods of time. The bot itself is somewhat clumsy and slow to maneuver.]],
	helptext_de    = [[Der Firewalker setzt mit seinem Mörser auf mittlerer Distanz Gebiete in Brand und macht sie somit für kurze Zeit unbrauchbar. Die Einheit selber ist schwerfällig und langsam zu manövrieren.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[fatbotarty]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
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
  sightDistance          = 660,
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
      cegTag                  = [[custom:gravityless_flamer]],

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
		light_camera_height = 2500,
		light_color = [[0.25 0.13 0.05]],
		light_radios = 460,
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
      soundStartVolume        = 3.8,
      sprayangle              = 2500,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 320,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[firewalker_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ firewalker = unitDef })
