unitDef = {
  unitname                      = [[corbhmth]],
  name                          = [[Behemoth]],
  description                   = [[Plasma Artillery Battery - Requires 50 Power]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildCostEnergy               = 2500,
  buildCostMetal                = 2500,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 8,
  buildingGroundDecalSizeY      = 8,
  buildingGroundDecalType       = [[corbhmth_aoplane.dds]],
  buildPic                      = [[CORBHMTH.png]],
  buildTime                     = 2500,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Plasmabatterie - Benötigt ein angeschlossenes Stromnetz von 50 Energie, um feuern zu können.]],
    helptext       = [[The Behemoth offers long-range artillery/counter-artillery capability, making it excellent for area denial. It is not designed as a defense turret, and will go down if attacked directly.]],
	helptext_de    = [[Der Behemoth besitzt eine weitreichende (Erwiderungs-)Artilleriefähigkeit, um Zugang zu größeren Arealen zu verhindern. Er wurde nicht als Verteidigungsturm entwickelt und wird bei direktem Angriff in die Knie gezwungen.]],
    keeptooltip = [[any string I want]],
    neededlink  = 50,
    pylonrange  = 50,
  },

  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 5,
  footprintZ                    = 5,
  highTrajectory                = 2,
  iconType                      = [[staticarty]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 3750,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[corbhmth.s3o]],
  onoffable                     = false,
  script                        = [[corbhmth.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  
  sfxtypes               = {

    explosiongenerators = {
	  [[custom:LARGE_MUZZLE_FLASH_FX]],
    },

  },
  sightDistance                 = 660,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooooo ooooo ooooo ooooo ooooo]],

  weapons                       = {

    {
      def                = [[PLASMA]],
	  badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

  },


  weaponDefs                    = {

    PLASMA = {
      name                    = [[Long-Range Plasma Battery]],
      areaOfEffect            = 192,
      avoidFeature            = false,
	  avoidGround             = false,
	  burst					  = 3,
	  burstRate				  = 0.16,
      craterBoost             = 1,
      craterMult              = 2,

      customParams            = {
		light_color = [[1.4 0.8 0.3]],
      },

      damage                  = {
        default = 601,
        planes  = 601,
        subs    = 30,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:330rlexplode]],
      fireStarter             = 120,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
	  mygravity				  = 0.1,
      range                   = 1850,
      reloadtime              = 10,
      soundHit                = [[explosion/ex_large4]],
      soundStart              = [[explosion/ex_large5]],
      sprayangle              = 1024,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 400,
    },

  },


  featureDefs                   = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[corbhmth_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ corbhmth = unitDef })
