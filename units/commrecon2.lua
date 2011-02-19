unitDef = {
  unitname          = [[commrecon2]],
  name              = [[Recon Commander]],
  description       = [[High Mobility Commander, Builds at 12 m/s]],
  acceleration      = 0.25,
  activateWhenBuilt = true,
  amphibious        = [[1]],
  autoHeal          = 5,
  brakeRate         = 0.45,
  buildCostEnergy   = 1800,
  buildCostMetal    = 1800,
  buildDistance     = 120,
  builder           = true,

  buildoptions      = {
  },

  buildPic          = [[commrecon.png]],
  buildTime         = 1800,
  canAttack         = true,
  canGuard          = true,
  canMove           = true,
  canPatrol         = true,
  canstop           = [[1]],
  category          = [[LAND FIREPROOF]],
  cloakCost         = 6,
  cloakCostMoving   = 24,
  commander         = true,
  corpse            = [[DEAD]],

  customParams      = {
    canjump   = [[1]],
    fireproof = [[1]],
    helptext  = [[The Recon Commander revolves around mobility and guile; this lightly armored platform can mount many special weapons and modules. Its base weapon is a slowing beam, while its special is a disruptor bomb with a wide AoE. It also features jumpjets.]],
    jumpclass = [[commrecon1]],
    level     = [[2]],
    statsname = [[commrecon]],
  },

  energyMake        = 2.7,
  energyStorage     = 0,
  energyUse         = 0,
  explodeAs         = [[ESTOR_BUILDINGEX]],
  footprintX        = 2,
  footprintZ        = 2,
  hideDamage        = true,
  iconType          = [[armcommander]],
  idleAutoHeal      = 5,
  idleTime          = 1800,
  immunetoparalyzer = [[1]],
  mass              = 848,
  maxDamage         = 2750,
  maxSlope          = 36,
  maxVelocity       = 1.45,
  maxWaterDepth     = 5000,
  metalMake         = 2.7,
  metalStorage      = 0,
  minCloakDistance  = 100,
  movementClass     = [[AKBOT2]],
  noChaseCategory   = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  norestrict        = [[1]],
  objectName        = [[commrecon.s3o]],
  radarDistance     = 1250,
  script            = [[commrecon.lua]],
  seismicSignature  = 16,
  selfDestructAs    = [[ESTOR_BUILDINGEX]],

  sfxtypes          = {

    explosiongenerators = {
      [[custom:NONE]],
      [[custom:NONE]],
      [[custom:RAIDMUZZLE]],
      [[custom:NONE]],
      [[custom:VINDIBACK]],
      [[custom:FLASH64]],
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
      def                = [[SLOWBEAM]],
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
      range                   = 300,
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


    SLOWBEAM  = {
      name                    = [[Slowing Beam]],
      areaOfEffect            = 8,
      beamDecay               = 0.9,
      beamTime                = 0.1,
      beamttl                 = 50,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        timeslow_preset = [[commrecon_slowbeam]],
      },


      damage                  = {
        default = 120,
      },

      explosionGenerator      = [[custom:flash2purple]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 6,
      lineOfSight             = true,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 1.5,
      renderType              = 0,
      rgbColor                = [[0.4 0 0.5]],
      soundStart              = [[weapon/laser/pulse_laser2]],
      soundStartVolume        = 0.9,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 8,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },

  },


  featureDefs       = {

    DEAD = {
      description      = [[Wreckage - Recon Commander]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 2250,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 720,
      object           = [[commrecon_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 720,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP = {
      description      = [[Debris - Recon Commander]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2250,
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

return lowerkeys({ commrecon2 = unitDef })
