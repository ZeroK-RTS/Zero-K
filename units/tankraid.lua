return { tankraid = {
  unitname            = [[tankraid]],
  name                = [[Kodachi]],
  description         = [[Raider Tank]],
  acceleration        = 0.625,
  brakeRate           = 1.375,
  buildCostMetal      = 170,
  builder             = false,
  buildPic            = [[tankraid.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[42 42 42]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    fireproof      = [[1]],
    specialreloadtime = [[850]],
    aimposoffset      = [[0 5 0]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[tankscout]],
  idleAutoHeal        = 10,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 650,
  maxSlope            = 18,
  maxVelocity         = 3.9,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[logkoda.s3o]],
  script              = [[tankraid.lua]],
  selfDestructAs      = [[BIG_UNITEX]],
  sightDistance       = 680,
  trackOffset         = 6,
  trackStrength       = 5,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 30,
  turninplace         = 0,
  turnRate            = 880,
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
      accuracy                = 1300,
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

        area_damage = 1,
        area_damage_radius = 56,
        area_damage_dps = 45,
        area_damage_duration = 1.5,
        
        light_color = [[1.6 0.8 0.32]],
        light_radius = 320,
      },
      
      damage                  = {
        default = 51,
        planes  = 51,
        subs    = 2.6,
      },

      explosionGenerator      = [[custom:napalm_koda_small]],
      fireStarter             = 65,
      flameGfxTime            = 0.1,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      leadLimit               = 90,
      model                   = [[wep_b_fabby.s3o]],
      myGravity               = 0.1,
      noSelfDamage            = true,
      range                   = 230,
      reloadtime              = 0.4 + 2/30,
      soundHit                = [[FireHit]],
      soundHitVolume          = 3,
      soundStart              = [[FireLaunch]],
      soundStartVolume        = 3,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 220,
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
