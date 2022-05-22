return { raveparty = {
  unitname                      = [[raveparty]],
  name                          = [[Disco Rave Party]],
  description                   = [[Destructive Rainbow Projector]],
  buildCostMetal                = 40000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[staticheavyarty_aoplane.dds]],
  buildPic                      = [[raveparty.png]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[70 194 70]],
  collisionVolumeType           = [[cylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    modelradius    = [[35]],
    bait_level_default = 0,
    draw_blueprint_facing = 1,
    want_proximity_targetting = 1,
    speed_bar = 1,

    keeptooltip    = [[any string I want]],
    neededlink     = 400,
    pylonrange     = 150,
  },

  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 7,
  footprintZ                    = 7,
  highTrajectory                = 2,
  iconType                      = [[mahlazer]],
  levelGround                   = false,
  losEmitHeight                 = 100,
  maxDamage                     = 16000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[raveparty.s3o]],
  --onoffable                        = true,
  script                        = [[raveparty.lua]],
  selfDestructAs                = [[ATOMIC_BLAST]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:staticheavyarty_SHOCKWAVE]],
      [[custom:staticheavyarty_SMOKE]],
      [[custom:staticheavyarty_FLARE]],
    },

  },
  sightDistance                 = 660,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooooooo ooooooo ooooooo ooooooo ooooooo ooooooo ooooooo]],

  weapons                       = {

    {
      def                = [[RED_KILLER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },
    {
      def                = [[ORANGE_ROASTER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },
    {
      def                = [[YELLOW_SLAMMER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },
    {
      def                = [[GREEN_STAMPER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },
    {
      def                = [[BLUE_SHOCKER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },
    {
      def                = [[VIOLET_SLUGGER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },
  },


  weaponDefs                    = {

    RED_KILLER = {
      name                    = [[Red Killer]],
      accuracy                = 750,
      avoidFeature            = false,
      avoidGround             = false,
      areaOfEffect            = 192,
      craterBoost             = 4,
      craterMult              = 3,

      customParams = {
        script_reload = [[6]],
        reaim_time = 1,
      },
      damage                  = {
        default = 3002.1,
      },

      edgeeffectiveness       = 0.5,
      explosionGenerator      = [[custom:NUKE_150]],
      impulseBoost            = 0.5,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      myGravity               = 0.18,
      range                   = 7500,
      rgbColor                = [[1 0.1 0.1]],
      reloadtime              = 5,
      size                    = 15,
      sizeDecay               = 0.03,
      soundHit                = [[explosion/mini_nuke]],
      soundStart              = [[weapon/cannon/big_begrtha_gun_fire]],
      stages                  = 30,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },
    
    ORANGE_ROASTER = {
      name                    = [[Orange Roaster]],
      accuracy                = 750,
      areaOfEffect            = 640,
      craterAreaOfEffect      = 80,
      avoidFeature            = false,
      avoidGround             = false,
      craterBoost             = 0.25,
      craterMult              = 0.5,
      
      customParams              = {
        setunitsonfire = "1",
        burntime = 240,
        burnchance = 1,

        script_reload = [[6]],
        reaim_time = 1,

        area_damage = 1,
        area_damage_radius = 320,
        area_damage_dps = 40,
        area_damage_duration = 15,
      },

      damage                  = {
        default = 300.9,
        planes  = 300,
      },

      edgeeffectiveness       = 0.25,
      explosionGenerator      = [[custom:napalm_drp]],
      impulseBoost            = 0.2,
      impulseFactor           = 0.1,
      interceptedByShieldType = 1,
      myGravity               = 0.18,
      range                   = 7500,
      rgbColor                = [[0.9 0.3 0]],
      reloadtime              = 5,
      size                      = 15,
      sizeDecay                  = 0.03,
      soundHit                = [[weapon/missile/nalpalm_missile_hit]],
      soundStart              = [[weapon/cannon/big_begrtha_gun_fire]],
      stages                  = 30,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },
    
    YELLOW_SLAMMER = {
      name                    = [[Yellow Slammer]],
      accuracy                = 750,
      areaOfEffect            = 384,
      craterAreaOfEffect      = 96,
      avoidFeature            = false,
      avoidGround             = false,
      craterBoost             = 0.5,
      craterMult              = 1,

      customParams = {
        script_reload = [[6]],
        reaim_time = 1,
      },

      damage                  = {
        default = 801.1,
        planes  = 800,
      },

      edgeeffectiveness       = 0.5,
      explosionGenerator      = [[custom:330rlexplode]],
      explosionSpeed          = 500,
      impulseBoost            = 400,
      impulseFactor           = 5,
      interceptedByShieldType = 1,
      myGravity               = 0.18,
      range                   = 7500,
      rgbColor                = [[0.7 0.7 0]],
      reloadtime              = 5,
      size                      = 15,
      sizeDecay                  = 0.03,
      soundHit                = [[weapon/cannon/earthshaker]],
      soundStart              = [[weapon/cannon/big_begrtha_gun_fire]],
      stages                  = 30,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },

    GREEN_STAMPER = {
      name                    = [[Green Stamper]],
      accuracy                = 750,
      areaOfEffect            = 384,
      avoidFeature            = false,
      avoidGround             = false,
      craterBoost             = 32,
      craterMult              = 1,

      customParams            = {
        gatherradius = [[400]],
        smoothradius = [[240]],
        smoothmult   = [[0.8]],
        smoothexponent = [[0.45]],
        movestructures = [[1]],

        script_reload = [[6]],
        reaim_time = 1,
      },
      
      damage                  = {
        default = 401.1,
        planes  = 400,
      },

      explosionGenerator      = [[custom:blobber_goo]],
      impulseBoost            = 0.7,
      impulseFactor           = 0.5,
      interceptedByShieldType = 1,
      myGravity               = 0.18,
      range                   = 7500,
      rgbColor                = [[0.1 1 0.1]],
      reloadtime              = 5,
      size                      = 15,
      sizeDecay                  = 0.03,
      soundHit                = [[explosion/ex_large4]],
      soundStart              = [[weapon/cannon/big_begrtha_gun_fire]],
      stages                  = 30,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },

    BLUE_SHOCKER = {
      name                    = [[Blue Shocker]],
      accuracy                = 750,
      areaOfEffect            = 320,
      avoidFeature            = false,
      avoidGround             = false,
      craterBoost             = 0.25,
      craterMult              = 0.5,

      customParams = {
        script_reload = [[6]],
        reaim_time = 1,
      },

      damage                  = {
        --[[ huge value to burst Funnelweb shields, since most of DRP's
             power is in effects normally crappy vs them but we don't want
             DRP to arbitrarily suck vs Funnel if the other supers don't ]]
        default        = 30000,
      },

      edgeEffectiveness       = 0.75,
      explosionGenerator      = [[custom:POWERPLANT_EXPLOSION]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      myGravity               = 0.18,
      paralyzer               = true,
      paralyzeTime            = 25,
      range                   = 7500,
      rgbColor                = [[0.1 0.1 1]],
      reloadtime              = 5,
      size                      = 15,
      sizeDecay                  = 0.03,
      soundHit                = [[weapon/more_lightning]],
      soundStart              = [[weapon/cannon/big_begrtha_gun_fire]],
      stages                  = 30,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },

    VIOLET_SLUGGER = {
      name                    = [[Violet Slugger]],
      accuracy                = 750,
      areaOfEffect            = 720,
      craterAreaOfEffect      = 90,
      avoidFeature            = false,
      avoidGround             = false,
      craterBoost             = 0.25,
      craterMult              = 0.5,

      customparams = {
        timeslow_damagefactor = 10,
        nofriendlyfire = "needs hax",
        script_reload = [[6]],
        reaim_time = 1,
        timeslow_overslow_frames = 2*30, --2 seconds before slow decays
      },
      
      damage                  = {
        default = 450.1,
      },

      edgeeffectiveness       = 0.8,
      explosionGenerator      = [[custom:riotballplus2_purple]],
      explosionScar           = false,
      explosionSpeed          = 6.5,
      impulseBoost            = 0.2,
      impulseFactor           = 0.1,
      interceptedByShieldType = 1,
      myGravity               = 0.18,
      range                   = 7500,
      rgbColor                = [[0.7 0 0.7]],
      reloadtime              = 5,
      size                    = 15,
      sizeDecay               = 0.03,
      soundHit                = [[weapon/aoe_aura2]],
      soundStart              = [[weapon/cannon/big_begrtha_gun_fire]],
      stages                  = 30,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },
    
  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[raveparty_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
