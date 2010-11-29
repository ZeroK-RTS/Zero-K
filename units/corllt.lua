unitDef = {
  unitname                      = [[corllt]],
  name                          = [[Lotus]],
  description                   = [[Light Laser Tower]],
  acceleration                  = 0,
  activateWhenBuilt             = false,
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildAngle                    = 32768,
  buildCostEnergy               = 90,
  buildCostMetal                = 90,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[corllt_aoplane.dds]],
  buildPic                      = [[CORLLT.png]],
  buildTime                     = 90,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 -32 0]],
  collisionVolumeScales         = [[32 90 32]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Light Laser Tower ou Tourelle Laser Légcre]],
    helptext       = [[The Lotus is a basic turret. A versatile, solid anti-ground weapon, it does well versus scouts as well as being able to take on one or two raiders. Falls relatively easily to skirmishers, artillery or assault units unless supported.]],
    helptext_fr    = [[La Tourelle Laser Légcre aussi appellée LLT est une tourelle basique, peu solide mais utile pour se protéger des éclaireurs ou des pilleurs. Des tirailleurs ou de l'artillerie en viendrons rapidement r bout. ]],
  },

  defaultmissiontype            = [[GUARD_NOMOVE]],
  explodeAs                     = [[SMALL_BUILDINGEX]],
  footprintX                    = 2,
  footprintZ                    = 2,
  healtime                      = [[4]],
  iconType                      = [[defenseraider]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  mass                          = 128,
  maxDamage                     = 785,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  modelCenterOffset             = [[0 32 0]],
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[lotustest2.s3o]],
  seismicSignature              = 4,
  selfDestructAs                = [[SMALL_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  side                          = [[CORE]],
  sightDistance                 = 473,
  smoothAnim                    = true,
  TEDClass                      = [[FORT]],
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooo]],

  weapons                       = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

    LASER = {
      name                    = [[Laserbeam]],
      areaOfEffect            = 8,
      beamlaser               = 1,
      beamTime                = 0.1,
      coreThickness           = 0.4,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 10,
        planes  = 10,
        subs    = 0.45,
      },

      explosionGenerator      = [[custom:FLASH1blue]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 2,
      lineOfSight             = true,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 460,
      reloadtime              = 0.1,
      renderType              = 0,
      rgbColor                = [[0 1 1]],
      soundStart              = [[weapon/laser/laser_burn8]],
      soundTrigger            = true,
      sweepfire               = false,
      targetMoveError         = 0.1,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 2,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Lotus]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 785,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 36,
      object           = [[lotus_d.s3o]],
      reclaimable      = true,
      reclaimTime      = 36,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Lotus]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 785,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 36,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 36,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Lotus]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 785,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 18,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 18,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corllt = unitDef })
