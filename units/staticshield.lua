return { staticshield = {
  unitname                      = [[staticshield]],
  name                          = [[Aegis]],
  description                   = [[Area Shield]],
  activateWhenBuilt             = true,
  buildCostMetal                = 525,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[staticshield_aoplane.dds]],
  buildPic                      = [[staticshield.png]],
  canMove                       = true, -- for queuing orders during morph to mobile
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[30 39 30]],
  collisionVolumeType           = [[box]],
  corpse                        = [[DEAD]],
  explodeAs                     = [[BIG_UNITEX]],
  floater                       = true,
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[defenseshield]],
  levelGround                   = false,
  maxDamage                     = 900,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  noAutoFire                    = false,
  objectName                    = [[m-8.s3o]],
  onoffable                     = true,
  script                        = [[staticshield.lua]],
  selfDestructAs                = [[BIG_UNITEX]],
  sightDistance                 = 200,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooo]],

  customParams        = {
    removewait     = 1,

    morphto = [[shieldshield]],
    morphtime = [[30]],

    priority_misc = 1, -- Medium
    unarmed       = true,
    addfight       = 1,
    addpatrol      = 1,
  },
  
  weapons                       = {

    {
      def         = [[COR_SHIELD_SMALL]],
      maxAngleDif = 1,
    },

  },


  weaponDefs                    = {

    COR_SHIELD_SMALL = {
      name                    = [[Energy Shield]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[1 0.1 0.1 1]],
      shieldGoodColor         = [[0.1 0.1 1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 3600,
      shieldPowerRegen        = 50,
      shieldPowerRegenEnergy  = 9,
      shieldRadius            = 350,
      shieldRepulser          = false,
      smartShield             = true,
      visibleShield           = false,
      visibleShieldRepulse    = false,
      weaponType              = [[Shield]],
    },

  },


  featureDefs                   = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[shield_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

} }
