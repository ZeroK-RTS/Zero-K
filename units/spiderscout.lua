unitDef = {
  unitname            = [[spiderscout]],
  name                = [[Flea]],
  description         = [[Ultralight Scout Spider (Burrows)]],
  acceleration        = 0.7,
  brakeRate           = 2.1,
  buildCostMetal      = 20,
  buildPic            = [[spiderscout.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND TOOFAST]],
  cloakCost           = 0,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[20 20 20]],
  collisionVolumeType    = [[ellipsoid]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[28 28 28]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    modelradius    = [[10]],
    idle_cloak = 1,
    selection_scale = 1, -- Maybe change later
  },

  explodeAs           = [[TINY_BUILDINGEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[spiderscout]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 40,
  maxSlope            = 72,
  maxVelocity         = 4.8,
  maxWaterDepth       = 15,
  minCloakDistance    = 200,
  movementClass       = [[TKBOT2]],
  moveState           = 0,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[arm_flea.s3o]],
  pushResistant       = 0,
  script              = [[spiderscout.lua]],
  selfDestructAs      = [[TINY_BUILDINGEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:digdig]],
    },

  },

  sightDistance       = 560,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrackPointy]],
  trackWidth          = 18,
  turnRate            = 2100,

  weapons             = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs          = {

    LASER = {
      name                    = [[Micro Laser]],
      areaOfEffect            = 8,
      beamTime                = 0.1,
      burstrate               = 0.2,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
		light_color = [[0.8 0.8 0]],
		light_radius = 50,
      },

      damage                  = {
        default = 9.8,
        planes  = 9.8,
        subs    = 0.5,
      },

      explosionGenerator      = [[custom:beamweapon_hit_yellow_tiny]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.22,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 150,
      reloadtime              = 0.25,
      rgbColor                = [[1 1 0]],
      soundStart              = [[weapon/laser/small_laser_fire]],
      soundTrigger            = true,
      thickness               = 2.14476105895272,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 600,
    },

  },

  featureDefs                   = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 1,
      footprintZ       = 1,
      object           = [[flea_d.dae]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 1,
      footprintZ       = 1,
      object           = [[debris1x1b.s3o]],
    },

  },

}

return lowerkeys({ spiderscout = unitDef })
