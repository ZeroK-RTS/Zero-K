return { chicken_rafflesia = {
  unitname                      = [[chicken_rafflesia]],
  name                          = [[Rafflesia]],
  description                   = [[Chicken Shield (Static)]],
  activateWhenBuilt             = true,
  buildCostEnergy               = 0,
  buildCostMetal                = 0,
  builder                       = false,
  buildPic                      = [[chicken_rafflesia.png]],
  buildTime                     = 480,
  category                      = [[SINK]],

  customParams                  = {
    shield_emit_offset = -4,
  },

  explodeAs                     = [[NOWEAPON]],
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defenseshield]],
  idleAutoHeal                  = 20,
  idleTime                      = 300,
  levelGround                   = false,
  maxDamage                     = 500,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  maxWaterDepth                 = 20,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[chicken_rafflesia.s3o]],
  onoffable                     = true,
  power                         = 480,
  reclaimable                   = false,
  selfDestructAs                = [[NOWEAPON]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance                 = 512,
  sonarDistance                 = 512,
  upright                       = false,
  useBuildingGroundDecal        = false,
  workerTime                    = 0,
  yardMap                       = [[ooooooooo]],

  weapons                       = {

    {
      def = [[SHIELD]],
    },

  },


  weaponDefs                    = {
  
    SHIELD      = {
      name                    = [[Shield]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      shieldAlpha             = 0.15,
      shieldBadColor          = [[1.0 1 0.1 1]],
      shieldGoodColor         = [[0.1 1.0 0.1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 2500,
      shieldPowerRegen        = 180,
      shieldPowerRegenEnergy  = 0,
      shieldRadius            = 300,
      shieldRepulser          = false,
      smartShield             = true,
      visibleShield           = false,
      visibleShieldRepulse    = false,
      --texture1                = [[wakelarge]],
      --visibleShield           = true,
      --visibleShieldHitFrames  = 30,
      --visibleShieldRepulse    = false,
      weaponType              = [[Shield]],
    },

  },

} }
