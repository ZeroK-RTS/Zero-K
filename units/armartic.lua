unitDef = {
  unitname                      = [[armartic]],
  name                          = [[Faraday]],
  description                   = [[EMP Weapon]],
  buildCostEnergy               = 200,
  buildCostMetal                = 200,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[armartic_aoplane.dds]],
  buildPic                      = [[armartic.png]],
  buildTime                     = 200,
  canAttack                     = true,
  category                      = [[SINK TURRET]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[32 75 32]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[EMP Waffe]],
    description_fr = [[Tourelle EMP]],
    description_pl = [[Wiezyczka EMP]],
    helptext       = [[The Faraday is a powerful EMP tower. It has high damage and area of effect. Greatly amplifies the effect of other towers, but virtually useless on its own. When closed damage received is reduced to a quarter. Be careful of its splash damage though, as it can paralyze your own units if they are too close to the enemy.]],
    helptext_de    = [[Faraday ist ein schlagkräftiger EMP Turm. Er hat einen großen Radius, sowie hohen Schaden. Er vervollständigt die Effekte anderer Türme, doch alleine ist er ziemlich nutzlos. Falls geschlossen, besitzt er mehr Lebenspunkte. Beachte dennoch seinen Flächenschaden, welcher auch nahegelegene eigene Einheiten paralysieren kann.]],
    helptext_fr    = [[le Faraday est une redoutable défense EMP à zone d'effêt paralysant les adversaires sans les endommager. Repliée son blindage réduit à un quart les dommages reçus. Attention cependant à ne pas paralyser ses propres unités dans la zone d'effêt EMP.]],
    helptext_pl    = [[Faraday to silna wiezyczka EMP. Posiada wysokie obrazenia obszarowe EMP, ktore paralizuja wrogie jednostki. Chociaz sama w sobie nie moze zadawać normalnych obrazen, doskonale sprawuje sie w polaczeniu z innymi wiezyczkami.]],

    aimposoffset   = [[0 10 0]],
    modelradius    = [[16]],
  },

  damageModifier                = 0.25,
  explodeAs                     = [[MEDIUM_BUILDINGEX]],
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[defensespecial]],
  levelGround                   = false,
  maxDamage                     = 1000,
  maxSlope                      = 36,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noChaseCategory               = [[FIXEDWING LAND SHIP SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[ARMARTIC]],
  script                        = [[armartic.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[MEDIUM_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:YELLOW_LIGHTNING_MUZZLE]],
      [[custom:YELLOW_LIGHTNING_GROUNDFLASH]],
    },

  },

  sightDistance                 = 506,
  useBuildingGroundDecal        = true,
  yardMap                       = [[oo oo]],

  weapons                       = {

    {
      def                = [[arm_det_weapon]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },

  },

  weaponDefs                    = {

    arm_det_weapon = {
      name                    = [[Electro-Stunner]],
      areaOfEffect            = 160,
      beamWeapon              = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 0,

      damage                  = {
        default = 1000,
      },

      duration                = 8,
      edgeEffectiveness       = 0.8,
      explosionGenerator      = [[custom:YELLOW_LIGHTNINGPLOSION]],
      fireStarter             = 0,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      paralyzer               = true,
      paralyzeTime            = 2, -- was 2.5 but this can only be int
      range                   = 460,
      reloadtime              = 2.8,
      rgbColor                = [[1 1 0.25]],
      soundStart              = [[weapon/lightning_fire]],
      soundTrigger            = true,
      targetMoveError         = 0,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 450,
    },

  },

  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Faraday]],
      blocking         = true,
      damage           = 1000,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 80,
      object           = [[wreck2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
    },

    HEAP  = {
      description      = [[Debris - Faraday]],
      blocking         = false,
      damage           = 1000,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 40,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 40,
    },

  },

}

return lowerkeys({ armartic = unitDef })
