return { tankraid = {
  unitname            = [[tankraid]],
  name                = [[Kodachi]],
  description         = [[Raider Tank]],
  acceleration        = 0.75,
  brakeRate           = 1.65,
  buildCostMetal      = 170,
  builder             = false,
  buildPic            = [[tankraid.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND TOOFAST]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[34 26 34]],
  collisionVolumeType    = [[ellipsoid]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[42 42 42]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    fireproof      = [[1]],
    --specialreloadtime = [[850]],
    modelradius       = [[20]],
    aimposoffset      = [[0 5 0]],
    selection_scale   = 0.85,
    aim_lookahead     = 140,
    percieved_range   = 270, -- How much range enemy units think Kodachi has

    outline_x = 80,
    outline_y = 80,
    outline_yoff = 12.5,
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[tankscout]],
  idleAutoHeal        = 5,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 680,
  maxSlope            = 18,
  maxVelocity         = 3.6,
  maxWaterDepth       = 22,
  movementClass       = [[TANK3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[logkoda.s3o]],
  script              = [[tankraid.lua]],
  selfDestructAs      = [[BIG_UNITEX]],
  sightDistance       = 600,
  trackOffset         = 6,
  trackStrength       = 5,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 30,
  turninplace         = 0,
  turnRate            = 1152,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[NAPALM_BOMBLET]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER GUNSHIP]],
    },
    
    --{
    --  def                = [[BOGUS_FAKE_NAPALM_BOMBLET]],
    --  badTargetCategory  = [[GUNSHIP]],
    --  onlyTargetCategory = [[]],
    --},

  },


  weaponDefs          = {

    NAPALM_BOMBLET = {
      name                    = [[Flame Bomb]],
      accuracy                = 1200,
      areaOfEffect            = 96,
      avoidFeature            = true,
      avoidFriendly           = true,
      burnblow                = true,
      cegTag                  = [[flamer_koda]],
      craterBoost             = 0,
      craterMult              = 0,

      customParams              = {
        setunitsonfire = "1",
        burnchance     = "1",
        burntime       = 30,
        force_ignore_ground = [[1]],

        area_damage = 1,
        area_damage_radius = 54,
        area_damage_dps = 43,
        area_damage_plateau_radius = 20,
        area_damage_duration = 1.6,
        
        light_color = [[1.6 0.8 0.32]],
        light_radius = 320,
      },
      
      damage                  = {
        default = 40,
        planes  = 40,
      },

      explosionGenerator      = [[custom:napalm_koda_small]],
      fireStarter             = 65,
      flameGfxTime            = 0.1,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      leadLimit               = 90,
      model                   = [[wep_b_fabby.s3o]],
      myGravity               = 0.2,
      noSelfDamage            = true,
      range                   = 210,
      reloadtime              = 0.5,
      soundHit                = [[FireHit]],
      soundHitVolume          = 5,
      soundStart              = [[FireLaunch]],
      soundStartVolume        = 5,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 520,
    },

  },


  featureDefs         = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[logkoda_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
