unitDef = {
  unitname                      = [[armartic]],
  name                          = [[Faraday]],
  description                   = [[EMP Weapon]],
  buildCostEnergy               = 170,
  buildCostMetal                = 170,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[armartic_aoplane.dds]],
  buildPic                      = [[armartic.png]],
  buildTime                     = 170,
  canAttack                     = true,
  canstop                       = true,
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[32 75 32]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Tourelle EMP]],
	description_de = [[EMP Waffe]],
    helptext       = [[The Faraday is a powerful EMP tower. It has high damage and area of effect. Greatly amplifies the effect of other towers, but virtually useless on its own. When closed, it has additional health. Be careful of its splash damage though, as it can paralyze your own units if they are too close to the enemy.]],
    helptext_fr    = [[le Faraday est une redoutable tour r canon EMP. Sa zone d'effet et sa puissance de feu lui permettent de venir r bout de nombreux ennemis massés, laissant d'autre tirs les achever. Une fois repliée, elle gagne en blindage. Attention cependant r ne pas paralyser ses propres unités avec la zone d'impact EMP.]],
    helptext_de = [[Faraday ist ein schlagkräftiger EMP Turm. Er hat einen großen Radius, sowie hohen Schaden. Er vervollständigt die Effekte anderer Türme, doch alleine ist er ziemlich nutzlos. Falls geschlossen, besitzt er mehr Lebenspunkte. Beachte dennoch seinen Flächenschaden, welcher auch nahegelegene eigene Einheiten paralysieren kann.]],
  },

  damageModifier                = 0.25,
  designation                   = [[AM-TIC]],
  digger                        = [[1]],
  explodeAs                     = [[MEDIUM_BUILDINGEX]],
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[defensespecial]],
  levelGround                   = false,
  mass                          = 159,
  maxDamage                     = 1000,
  maxSlope                      = 36,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[ARMARTIC]],
  seismicSignature              = 4,
  selfDestructAs                = [[MEDIUM_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:YELLOW_LIGHTNING_MUZZLE]],
      [[custom:YELLOW_LIGHTNING_GROUNDFLASH]],
    },

  },

  shootme                       = [[1]],
  side                          = [[ARM]],
  sightDistance                 = 506,
  TEDClass                      = [[FORT]],
  threed                        = [[1]],
  useBuildingGroundDecal        = true,
  version                       = [[3.1]],
  yardMap                       = [[ooooooooo]],

  weapons                       = {

    {
      def                = [[arm_det_weapon]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
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
      cylinderTargetting      = 0,

      damage                  = {
        default        = 1000,
        commanders     = 100,
        empresistant75 = 250,
        empresistant99 = 10,
      },

      duration                = 8,
      dynDamageExp            = 0,
      edgeEffectiveness       = 0.8,
      explosionGenerator      = [[custom:YELLOW_LIGHTNINGPLOSION]],
      fireStarter             = 0,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      paralyzer               = true,
      paralyzeTime            = 2.5,
      range                   = 460,
      reloadtime              = 2.4,
      renderType              = 7,
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
      category         = [[arm_corpses]],
      damage           = 1000,
      featureDead      = [[DEAD2]],
      featurereclamate = [[smudge01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[12]],
      hitdensity       = [[23]],
      metal            = 68,
      object           = [[wreck2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 68,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[all]],
    },


    DEAD2 = {
      description      = [[Debris - Faraday]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1000,
      featureDead      = [[HEAP]],
      featurereclamate = [[smudge01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[4]],
      metal            = 68,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 68,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[all]],
    },


    HEAP  = {
      description      = [[Debris - Faraday]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1000,
      featurereclamate = [[smudge01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[4]],
      metal            = 34,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 34,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[all]],
    },

  },

}

return lowerkeys({ armartic = unitDef })
