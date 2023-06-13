return { starlight_satellite = {
  unitname               = [[starlight_satellite]],
  name                   = [[Glint]],
  description            = [[Starlight relay satellite]],
  acceleration           = 0.456,
  brakeRate              = 2.736,
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
  maxDamage              = 1500,
  maxVelocity            = 0.001,
  movementClass          = [[KBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[starlight_satellite.dae]],
  script                 = [[starlight_satellite.lua]],
  selfDestructAs         = [[GUNSHIPEX]],
  
  customParams           = {
    dontcount = [[1]],
    has_parent_unit = 1,

    outline_x = 100,
    outline_y = 100,
    outline_yoff = 0,
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
      def                = [[LAZER]],
      onlyTargetCategory = [[NONE]],
    },
    {
      def                = [[CUTTER]],
      onlyTargetCategory = [[NONE]],
    },
  },


  weaponDefs                    = {
    LAZER    = {
      name                    = [[Craterpuncher]],
      alwaysVisible           = 0,
      areaOfEffect            = 140,
      avoidFeature            = false,
      avoidNeutral            = false,
      avoidGround             = false,
      beamTime                = 1/30,
      coreThickness           = 0.5,
      craterBoost             = 6,
      craterMult              = 14,

      customParams              = {
        light_color = [[5 0.3 6]],
        light_radius = 2000,
        light_beam_start = 0.8,

        gatherradius = [[10]],
        smoothradius = [[64]],
        smoothmult   = [[0.5]],
        smoothheightoffset = [[40]],

        lups_noshockwave = [[1]],
        stats_damage = 18000,
      },

      damage                  = {
        default = 800,
      },

      explosionGenerator      = [[custom:craterpuncher]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 12,
      minIntensity            = 1,
      range                   = 10500,
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

      customParams              = {
        light_color = [[3 0.2 4]],
        light_radius = 1200,
        light_beam_start = 0.8,
      },
      
      damage                  = {
        default = 150,
      },

      explosionGenerator      = [[custom:FLASHLAZER]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 12,
      minIntensity            = 1,
      range                   = 10500,
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

} }
