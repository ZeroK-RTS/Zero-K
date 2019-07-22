unitDef = {
  unitname                      = [[staticnuke]],
  name                          = [[Trinity]],
  description                   = [[Strategic Nuclear Launcher, Drains 18 m/s, 3 minute stockpile]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = 8000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 10,
  buildingGroundDecalSizeY      = 10,
  buildingGroundDecalType       = [[staticnuke_aoplane.dds]],
  buildPic                      = [[staticnuke.png]],
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
	stockpiletime  = [[180]],
	stockpilecost  = [[3240]],
	priority_misc  = 1, -- Medium
  },

  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 6,
  footprintZ                    = 8,
  iconType                      = [[nuke]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 5000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[Silencer.s3o]],
  script                        = [[staticnuke.lua]],
  selfDestructAs                = [[ATOMIC_BLAST]],
  sightDistance                 = 660,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardmap                       = [[oooooooooooooooooooooooooooooooooooooooooooooooo]],

  weapons                       = {

    {
      def                = [[CRBLMSSL]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs                    = {

    CRBLMSSL = {
      name                    = [[Strategic Nuclear Missile]],
      areaOfEffect            = 1920,
      cegTag                  = [[NUCKLEARMINI]],
      collideFriendly         = false,
      collideFeature          = false,
      commandfire             = true,
      craterBoost             = 6,
      craterMult              = 6,

	  customParams        	  = {
		restrict_in_widgets = 1,

		light_color = [[2.92 2.64 1.76]],
		light_radius = 3000,
	  },

      damage                  = {
        default = 11501.1,
      },

      edgeEffectiveness       = 0.3,
      explosionGenerator      = [[custom:LONDON_FLAT]],      -- note, spawning of the explosion is handled by exp_nuke_effect_chooser.lua 
      fireStarter             = 0,
      flightTime              = 180,
      impulseBoost            = 0.5,
      impulseFactor           = 0.2,
      interceptedByShieldType = 65,
      model                   = [[crblmsslr.s3o]],
      noSelfDamage            = false,
      range                   = 72000,
      reloadtime              = 10,
      smokeTrail              = false,
      soundHit                = [[explosion/ex_ultra8]],
      startVelocity           = 800,
      stockpile               = true,
      stockpileTime           = 10^5,
      targetable              = 1,
      texture1                = [[null]], --flare
      tolerance               = 4000,
      weaponAcceleration      = 0,
      weaponTimer             = 10,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 800,
    },

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 6,
      footprintZ       = 8,
      object           = [[silencer_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 8,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ staticnuke = unitDef })
