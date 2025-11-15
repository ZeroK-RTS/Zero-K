return { staticshield = {
  name                          = [[Aegis]],
  description                   = [[Area Shield]],
  activateWhenBuilt             = true,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[staticshield_aoplane.dds]],
  buildPic                      = [[staticshield.png]],
  canMove                       = true, -- for queuing orders during morph to mobile
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],
  explodeAs                     = [[BIG_UNITEX]],
  floater                       = true,
  footprintX                    = 2,
  footprintZ                    = 2,
  health                        = 900,
  iconType                      = [[defenseshield]],
  levelGround                   = false,
  maxSlope                      = 36,
  metalCost                     = 525,
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
    aimposoffset   = [[0 5 0]],
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

      shieldForce                   = 2,
      shieldMaxSpeed                = 900,
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
      shieldRepulser          = true,
      repulser = true,
      smartShield             = true,
      visibleShield           = true,
      visibleShieldRepulse    = true,
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
