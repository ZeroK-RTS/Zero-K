unitDef = {
  unitname                      = [[zenith]],
  name                          = [[Zenith]],
  description                   = [[Meteor Controller]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  buildCostMetal                = 32000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 11,
  buildingGroundDecalSizeY      = 11,
  buildingGroundDecalType       = [[zenith_aoplane.dds]],
  buildPic                      = [[zenith.png]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[90 194 90]],
  collisionVolumeType           = [[cylY]],
  corpse                        = [[DEAD]],
  
  customParams                  = {
    keeptooltip = [[any string I want]],
    --neededlink  = 150,
    --pylonrange  = 150,
	modelradius    = [[45]],
  },  
  
  energyUse                     = 0,
  explodeAs                     = [[ATOMIC_BLAST]],
  fireState                     = 0,
  footprintX                    = 8,
  footprintZ                    = 8,
  iconType                      = [[mahlazer]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 12000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noChaseCategory               = [[FIXEDWING GUNSHIP SUB STUPIDTARGET]],
  objectName                    = [[zenith.s3o]],
  onoffable                     = true,
  script                        = [[zenith.lua]],
  selfDestructAs                = [[ATOMIC_BLAST]],
  sightDistance                 = 660,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo]],

  weapons                       = {

    {
      def                = [[METEOR]],
      badTargetCateogory = [[MOBILE]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

    {
      def                = [[GRAVITY_NEG]],
	  onlyTargetCategory = [[NONE]],
    },

  },


  weaponDefs                    = {

    GRAVITY_NEG = {
      name                    = [[Attractive Gravity (fake)]],
      alwaysVisible           = 1,
      avoidFriendly           = false,
	  canAttackGround		  = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        	  = {
		light_radius = 0,
	  },

      damage                  = {
        default = 0.001,
        planes  = 0.001,
        subs    = 5E-05,
      },

      duration                = 2,
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 20000,
      reloadtime              = 0.2,
      rgbColor                = [[0 0 1]],
      rgbColor2               = [[1 0.5 1]],
      size                    = 32,
      soundStart              = [[weapon/gravity_fire]],
	  soundStartVolume        = 0.15,
      thickness               = 32,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 6000,
    },
    METEOR      = {
      name                    = [[Meteor]],
	  accuracy                = 700,
      alwaysVisible           = 1,
      areaOfEffect            = 240,
      avoidFriendly           = false,
      avoidFeature            = false,
      avoidGround             = false,
      cegTag                  = [[METEOR_TAG]],
      collideFriendly         = true,
      craterBoost             = 3,
      craterMult              = 6, 

	  customParams        	  = {
		light_color = [[2.4 1.5 0.6]],
		light_radius = 600,
      },
	  
      damage                  = {
        default = 1000,
        planes  = 1000,
        subs    = 50,
      },

      edgeEffectiveness       = 0.8,
      explosionGenerator      = [[custom:av_tess]],
      fireStarter             = 70,
      flightTime              = 30,
      impulseBoost            = 250,
      impulseFactor           = 0.5,
      interceptedByShieldType = 2,
      model                   = [[asteroid.s3o]],
      range                   = 9000,
      reloadtime              = 0.7,
      smokeTrail              = true,
      soundHit                = [[weapon/cannon/supergun_bass_boost]],
      startVelocity           = 1500,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turret                  = true,
	  turnrate                = 2000,
      weaponAcceleration      = 2000,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 1600,
      wobble                  = 5500,
    },
	
	METEOR_AIM      = {
      name                    = [[Meteor]],
	  accuracy                = 700,
      alwaysVisible           = 1,
      areaOfEffect            = 240,
      avoidFriendly           = false,
      avoidFeature            = false,
      avoidGround             = false,
      cegTag                  = [[meteor_aim]],
      collideFriendly         = true,
      craterBoost             = 3,
      craterMult              = 6,

	  customParams        	  = {
		light_radius = 0,
	  },

      damage                  = {
        default = 1000,
        planes  = 1000,
        subs    = 50,
      },

      edgeEffectiveness       = 0.8,
      explosionGenerator      = [[custom:av_tess]],
      fireStarter             = 70,
      flightTime              = 300,
      impulseBoost            = 250,
      impulseFactor           = 0.5,
      interceptedByShieldType = 2,
      model                   = [[asteroid.s3o]],
      range                   = 9000,
      reloadtime              = 0.7,
      smokeTrail              = true,
      soundHit                = [[weapon/cannon/supergun_bass_boost]],
      startVelocity           = 1500,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

	  tracks                  = true,
      turret                  = true,
      turnRate                = 25000,
      weaponAcceleration      = 600,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 1200,
      wobble                  = 0,
    },
	
	METEOR_FLOAT      = {
      name                    = [[Meteor]],
	  accuracy                = 700,
      alwaysVisible           = 1,
      areaOfEffect            = 240,
      avoidFriendly           = false,
      avoidFeature            = false,
      avoidGround             = false,
      cegTag                  = [[meteor_hover]],
      collideFriendly         = true,
      craterBoost             = 3,
      craterMult              = 6,

	  customParams        	  = {
		light_radius = 0,
		do_not_save = 1, -- Controlled meteors are regenerated on load.
	  },

      damage                  = {
        default = 1000,
        planes  = 1000,
        subs    = 50,
      },

      edgeEffectiveness       = 0.8,
      explosionGenerator      = [[custom:av_tess]],
      fireStarter             = 70,
      flightTime              = 300,
      impulseBoost            = 250,
      impulseFactor           = 0.5,
      interceptedByShieldType = 2,
      model                   = [[asteroid.s3o]],
      range                   = 9000,
      reloadtime              = 0.7,
      smokeTrail              = true,
      soundHit                = [[weapon/cannon/supergun_bass_boost]],
      startVelocity           = 1500,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

	  tracks                  = true,
      trajectoryHeight        = 0,
      turret                  = true,
      turnRate                = 6000,
      weaponAcceleration      = 200,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 200,
      wobble                  = 30000,
    },
	
	METEOR_UNCONTROLLED      = {
      name                    = [[Meteor]],
	  accuracy                = 700,
      alwaysVisible           = 1,
      areaOfEffect            = 240,
      avoidFriendly           = false,
      avoidFeature            = false,
      avoidGround             = false,
      cegTag                  = [[meteor_fall]],
      collideFriendly         = true,
      craterBoost             = 3,
      craterMult              = 6,

	  customParams        	  = {
		light_color = [[2.4 1.5 0.6]],
		light_radius = 600,
		do_not_save = 1, -- Controlled meteors are regenerated on load.
      },

      damage                  = {
        default = 1000,
        planes  = 1000,
        subs    = 50,
      },

      edgeEffectiveness       = 0.8,
      explosionGenerator      = [[custom:av_tess]],
      fireStarter             = 70,
      flightTime              = 30,
      impulseBoost            = 250,
      impulseFactor           = 0.5,
      interceptedByShieldType = 2,
      model                   = [[asteroid.s3o]],
      range                   = 9000,
      reloadtime              = 0.7,
      smokeTrail              = true,
      soundHit                = [[weapon/cannon/supergun_bass_boost]],
      startVelocity           = 1500,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1600,
    },
  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 8,
      footprintZ       = 8,
      object           = [[zenith_dead.s3o]],
      collisionVolumeOffsets = [[0 0 0]],
      collisionVolumeScales  = [[90 194 90]],
      collisionVolumeType    = [[cylY]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ zenith = unitDef })
