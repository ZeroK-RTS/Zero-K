unitDef = {
  unitname                      = [[chicken_rafflesia]],
  name                          = [[Rafflesia]],
  description                   = [[Chicken Shield (Static)]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildCostEnergy               = 0,
  buildCostMetal                = 0,
  builder                       = false,
  buildPic                      = [[chicken_rafflesia.png]],
  buildTime                     = 480,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],

  customParams                  = {
    helptext       = [[The Rafflesia protects nearby chicken units and structures with its shield.]],
  },

  explodeAs                     = [[NOWEAPON]],
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defenseshield]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  mass                          = 120,
  maxDamage                     = 500,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  maxWaterDepth                 = 20,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[chicken_rafflesia.s3o]],
  onoffable                     = true,
  power                         = 480,
  seismicSignature              = 4,
  selfDestructAs                = [[NOWEAPON]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side                          = [[THUNDERBIRDS]],
  sightDistance                 = 512,
  smoothAnim                    = true,
  turnRate                      = 0,
  upright                       = false,
  useBuildingGroundDecal        = true,
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
      shieldBadColor          = [[1.0 1 0.1]],
      shieldGoodColor         = [[0.1 1.0 0.1]],
      shieldInterceptType     = 3,
      shieldPower             = 2500,
      shieldPowerRegen        = 180,
      shieldPowerRegenEnergy  = 0,
      shieldRadius            = 300,
      shieldRepulser          = false,
      smartShield             = true,
      texture1                = [[wakelarge]],
      visibleShield           = true,
      visibleShieldHitFrames  = 30,
      visibleShieldRepulse    = false,
      weaponType              = [[Shield]],
    },

  },

}

return lowerkeys({ chicken_rafflesia = unitDef })
