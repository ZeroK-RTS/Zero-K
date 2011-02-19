unitDef = {
  unitname          = [[commsupport]],
  name              = [[Support Commander]],
  description       = [[Econ/Support Commander, Builds at 12 m/s]],
  acceleration      = 0.25,
  activateWhenBuilt = true,
  amphibious        = [[1]],
  autoHeal          = 5,
  brakeRate         = 0.45,
  buildCostEnergy   = 1800,
  buildCostMetal    = 1800,
  buildDistance     = 250,
  builder           = true,

  buildoptions      = {
  },

  buildPic          = [[commsupport.png]],
  buildTime         = 1800,
  canAttack         = true,
  canGuard          = true,
  canMove           = true,
  canPatrol         = true,
  canstop           = [[1]],
  category          = [[LAND FIREPROOF]],
  cloakCost         = 10,
  cloakCostMoving   = 50,
  commander         = true,
  corpse            = [[DEAD]],

  customParams      = {
    cloakstealth = [[1]],
    fireproof    = [[1]],
    helptext     = [[The esoteric Support Commander uses a more unorthodox weapon set, which is by default a gauss rifle that can fire concussion shots when sufficiently upgraded. Though lacking armor or speed, this chassis is still favored due to its intrinsic income bonus.]],
    level        = [[1]],
    statsname    = [[commsupport]],
  },

  energyMake        = 4,
  energyStorage     = 100,
  energyUse         = 0,
  explodeAs         = [[ESTOR_BUILDINGEX]],
  footprintX        = 2,
  footprintZ        = 2,
  hideDamage        = true,
  iconType          = [[armcommander]],
  idleAutoHeal      = 5,
  idleTime          = 1800,
  immunetoparalyzer = [[1]],
  mass              = 839,
  maxDamage         = 2000,
  maxSlope          = 36,
  maxVelocity       = 1.2,
  maxWaterDepth     = 5000,
  metalMake         = 4,
  metalStorage      = 100,
  minCloakDistance  = 100,
  movementClass     = [[AKBOT2]],
  noChaseCategory   = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  norestrict        = [[1]],
  objectName        = [[commsupport.s3o]],
  script            = [[commsupport.lua]],
  seismicSignature  = 16,
  selfDestructAs    = [[ESTOR_BUILDINGEX]],

  sfxtypes          = {

    explosiongenerators = {
      [[custom:flashmuzzle1]],
    },

  },

  showNanoSpray     = false,
  showPlayerName    = true,
  side              = [[ARM]],
  sightDistance     = 500,
  smoothAnim        = true,
  sonarDistance     = 300,
  TEDClass          = [[COMMANDER]],
  terraformSpeed    = 600,
  turnRate          = 1350,
  upright           = true,
  workerTime        = 12,

  weapons           = {

    [1] = {
      def                = [[FAKELASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    [4] = {
      def                = [[GAUSS]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs        = {

    FAKELASER = {
      name                    = [[Fake Laser]],
      areaOfEffect            = 12,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0,
      },

      duration                = 0.11,
      explosionGenerator      = [[custom:flash1green]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      laserFlareSize          = 5.53,
      lineOfSight             = true,
      minIntensity            = 1,
      range                   = 450,
      reloadtime              = 0.11,
      renderType              = 0,
      rgbColor                = [[0 1 0]],
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 5.53,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 900,
    },


    GAUSS     = {
      name                    = [[Gauss Rifle]],
      alphaDecay              = 0.12,
      areaOfEffect            = 16,
      bouncerebound           = 0.15,
      bounceslip              = 1,
      cegTag                  = [[gauss_tag_l]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 90,
        planes  = 90,
        subs    = 4.5,
      },

      explosionGenerator      = [[custom:gauss_hit_l]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      lineOfSight             = true,
      noExplode               = true,
      noSelfDamage            = true,
      numbounce               = 40,
      range                   = 450,
      reloadtime              = 3,
      renderType              = 4,
      rgbColor                = [[0.5 1 1]],
      separation              = 0.5,
      size                    = 0.8,
      sizeDecay               = -0.1,
      soundHit                = [[weapon/gauss_hit]],
      soundHitVolume          = 3,
      soundStart              = [[weapon/gauss_fire]],
      soundStartVolume        = 2.5,
      stages                  = 32,
      startsmoke              = [[1]],
      turret                  = true,
      waterbounce             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1000,
    },

  },


  featureDefs       = {

    DEAD = {
      description      = [[Wreckage - Support Commander]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 2000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 720,
      object           = [[commsupport_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 720,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP = {
      description      = [[Debris - Support Commander]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 360,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 360,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ commsupport = unitDef })
