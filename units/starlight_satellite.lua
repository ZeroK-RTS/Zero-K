starlight_satellite = {
  unitname               = [[starlight_satellite]],
  name                   = [[Glint]],
  description            = [[Starlight relay satellite]],
  acceleration           = 0.152,
  brakeRate              = 0.456,
  buildCostMetal         = 300,
  builder                = false,
  buildPic               = [[satellite.png]],
  canFly                 = false,
  canMove                = true,
  canSubmerge            = false,
  category               = [[SINK UNARMED]],
  collide                = false,
  corpse                 = [[DEAD]],
  cruiseAlt              = 140,
  explodeAs              = [[GUNSHIPEX]],
  floater                = true,
  footprintX             = 0,
  footprintZ             = 0,
  hoverAttack            = true,
  iconType               = [[satellite]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 1500,
  maxVelocity            = 0.001,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[starlight_satellite.dae]],
  script                 = [[starlight_satellite.lua]],
  selfDestructAs         = [[GUNSHIPEX]],
  
  customParams           = {
    dontcount = [[1]],
  },

  sfxtypes               = {

    explosiongenerators = {
      [[custom:IMMA_LAUNCHIN_MAH_LAZER]],
      [[custom:xamelimpact]],
    },

  },

  sightDistance          = 0,
  turnRate               = 1,

  weapons                       = {

    {
      def                = [[TARGETER]],
      onlyTargetCategory = [[NONE]],
    },  
  
    {
      def                = [[LAZER]],
      onlyTargetCategory = [[NONE]],
    },
	
	{
      def                = [[RELAYLAZER]],
      onlyTargetCategory = [[NONE]],
    },
	
	{
      def                = [[CUTTER]],
      onlyTargetCategory = [[NONE]],
    },
	
	{
      def                = [[RELAYCUTTER]],
      onlyTargetCategory = [[NONE]],
    },
  },


  weaponDefs                    = {

    TARGETER = {
      name                    = [[Aimer (Fake)]],
      alwaysVisible           = 18,
      areaOfEffect            = 56,
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidNeutral            = false,
      avoidGround             = false,
      beamTime                = 1/30,
      coreThickness           = 0.5,

	  customParams        	  = {
		light_radius = 0,
	  },

      damage                  = {
        default = -0.00001,
      },

      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 12,
      minIntensity            = 1,
      range                   = 9000,
      reloadtime              = 20,
      rgbColor                = [[0.25 0 1]],
      soundStart              = [[weapon/laser/heavy_laser4]],
      soundTrigger            = true,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 0,
      tolerance               = 65536,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[BeamLaser]],
    },
  
	LAZER    = {
      name                    = [[Craterpuncher]],
      alwaysVisible           = 0,
      areaOfEffect            = 140,
      avoidFeature            = false,
      avoidNeutral            = false,
      avoidGround             = false,
      beamTime                = 1/30,
      coreThickness           = 0.5,
      craterBoost             = 4,
      craterMult              = 8,

	  customParams        	  = {
		stats_damage = 3000,

		light_color = [[5 0.3 6]],
		light_radius = 2000,
		light_beam_start = 0.8,
	  },

      damage                  = {
        default = 180,
      },

      explosionGenerator      = [[custom:FLASHLAZER]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 12,
      minIntensity            = 1,
      range                   = 9000,
      reloadtime              = 20,
      rgbColor                = [[0.25 0 1]],
	  scrollSpeed             = 8,
      soundStartVolume        = 1,
      soundTrigger            = true,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 100,
      tolerance               = 65536,
	  tileLength              = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[BeamLaser]],
    },
	
	RELAYLAZER    = {
      name                    = [[Relay Craterpuncher (fake)]],
      alwaysVisible           = 18,
      areaOfEffect            = 56,
      avoidFeature            = false,
      avoidNeutral            = false,
      avoidGround             = false,
      beamTime                = 1/30,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        	  = {
		light_radius = 0,
	  },

      damage                  = {
        default = 180,
      },

      explosionGenerator      = [[custom:FLASHLAZER]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 12,
      minIntensity            = 1,
      range                   = 9000,
      reloadtime              = 20,
      rgbColor                = [[0.25 0 1]],
	  scrollSpeed             = 8,
      soundTrigger            = true,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 100,
      tolerance               = 65536,
	  tileLength              = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[BeamLaser]],
    },
	
	CUTTER    = {
      name                    = [[Groovecutter]],
      alwaysVisible           = 0,
      areaOfEffect            = 140,
      avoidFeature            = false,
      avoidNeutral            = false,
      avoidGround             = false,
      beamTime                = 1/30,
      coreThickness           = 0.5,
      craterBoost             = 4,
      craterMult              = 8,

	  customParams        	  = {
		light_color = [[3 0.2 4]],
		light_radius = 1200,
		light_beam_start = 0.8,
	  },
	  
      damage                  = {
        default = 180,
      },

      explosionGenerator      = [[custom:FLASHLAZER]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 12,
      minIntensity            = 1,
      range                   = 9000,
      reloadtime              = 20,
      rgbColor                = [[0.25 0 1]],
	  scrollSpeed             = 8,
      soundStartVolume        = 1,
      soundTrigger            = true,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 50,
      tolerance               = 65536,
	  tileLength              = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[BeamLaser]],
    },
	
	RELAYCUTTER    = {
      name                    = [[Relay Cutter (fake)]],
      alwaysVisible           = 18,
      areaOfEffect            = 56,
      avoidFeature            = false,
      avoidNeutral            = false,
      avoidGround             = false,
      beamTime                = 1/30,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 2,
      craterMult              = 4,

	  customParams        	  = {
		light_radius = 0,
	  },

      damage                  = {
        default = 180,
      },

      explosionGenerator      = [[custom:FLASHLAZER]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 12,
      minIntensity            = 1,
      range                   = 9000,
      reloadtime              = 20,
      rgbColor                = [[0.25 0 1]],
	  scrollSpeed             = 8,
      soundTrigger            = true,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 50,
      tolerance               = 65536,
	  tileLength              = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[BeamLaser]],
    },
  },

  featureDefs            = {
    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[satellite_d.dae]],
	customParams = {
		unit = "mahlazer",
	},
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris2x2c.s3o]],
	customParams = {
		unit = "mahlazer",
	},
    },

  },

}

return lowerkeys({ starlight_satellite = starlight_satellite})
