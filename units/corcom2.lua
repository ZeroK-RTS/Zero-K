unitDef = {
  unitname            = [[corcom2]],
  name                = [[Battle Commander - Level 2]],
  description         = [[Heavy Combat Commander, Builds at 12 m/s]],
  acceleration        = 0.18,
  activateWhenBuilt   = true,
  amphibious          = [[1]],
  autoHeal            = 5,
  bmcode              = [[1]],
  brakeRate           = 0.375,
  buildCostEnergy     = 1600,
  buildCostMetal      = 1600,
  buildDistance       = 120,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[corcom.png]],
  buildTime           = 1800,
  canAttack           = true,
  canCloak            = false,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canreclamate        = [[1]],
  canstop             = [[1]],
  category            = [[LAND FIREPROOF]],
  commander           = true,
  corpse              = [[DEAD]],

  customParams        = {
    fireproof = [[1]],
	description_de = [[Schwerer Kampfkommandant, Baut mit 12 M/s]],
	helptext       = [[The Battle Commander emphasizes firepower and armor, at the expense of speed and support equipment. Its base weapon is a riot cannon.]],
	helptext_de    = [[Der Battle Commander verbindet Feuerkraft mit starker Panzerung, auf Kosten der Geschwindigkeit und seiner Unterstützungsausrüstung. Seine Standardwaffe ist eine randalierende Kanone, während seine Spezialwaffen Streubomben in einer Linie abfeuern.]],
	level = [[2]],
	statsname = [[corcom2]],
  },

  defaultmissiontype  = [[Standby]],
  energyMake          = 3.2,
  energyStorage       = 0,
  energyUse           = 0,
  explodeAs           = [[ESTOR_BUILDINGEX]],
  footprintX          = 2,
  footprintZ          = 2,
  hideDamage          = true,
  iconType            = [[corcommander]],
  idleAutoHeal        = 5,
  idleTime            = 1600,
  immunetoparalyzer   = [[1]],
  maneuverleashlength = [[640]],
  mass                = 881,
  maxDamage           = 3600,
  maxSlope            = 36,
  maxVelocity         = 1.3,
  maxWaterDepth       = 5000,
  metalMake           = 3.2,
  metalStorage        = 0,
  minCloakDistance    = 100,
  movementClass       = [[AKBOT2]],
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  norestrict          = [[1]],
  objectName          = [[corcom.s3o]],
  script              = [[corcom.lua]],
  seismicSignature    = 16,
  selfDestructAs      = [[ESTOR_BUILDINGEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
	  [[custom:LEVLRMUZZLE]],
      [[custom:RAIDMUZZLE]],
    },

  },

  showNanoSpray       = false,
  showPlayerName      = true,
  side                = [[CORE]],
  sightDistance       = 500,
  smoothAnim          = true,
  sonarDistance       = 300,
  steeringmode        = [[2]],
  TEDClass            = [[COMMANDER]],
  terraformSpeed      = 600,
  turnRate            = 1148,
  upright             = true,
  workerTime          = 12,

  weapons             = {

    [1] = {
      def                = [[FAKELASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    [5] = {
      def                = [[SHOCK_CANNON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    FAKELASER    = {
      name                    = [[Fake Laser]],
      areaOfEffect            = 12,
      beamlaser               = 1,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0,
        subs    = 0,
      },

      duration                = 0.11,
      edgeEffectiveness       = 0.99,
      explosionGenerator      = [[custom:flash1green]],
      fireStarter             = 70,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 5.53,
      lineOfSight             = true,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 290,
      reloadtime              = 0.11,
      renderType              = 0,
      rgbColor                = [[0 1 0]],
      soundStart              = [[weapon/laser/pulse_laser3]],
      soundTrigger            = true,
      targetMoveError         = 0.05,
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


    SHOCK_CANNON = {
      name                    = [[Riot Cannon]],
      areaOfEffect            = 144,
      avoidFeature            = true,
      avoidFriendly           = true,
      burnblow                = true,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 250,
        planes  = 250,
        subs    = 12.5,
      },

      edgeEffectiveness       = 0.75,
      explosionGenerator      = [[custom:FLASH64]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 290,
      reloadtime              = 2,
      renderType              = 4,
      soundHit                = [[weapon/cannon/generic_cannon]],
      soundStart              = [[weapon/cannon/outlaw_gun]],
      soundStartVolume        = 3,
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 750,
    },

  },


  featureDefs         = {

    DEAD      = {
      description      = [[Wreckage - Battle Commander - Level 2]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 2800,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 640,
      object           = [[corcom_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 640,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP      = {
      description      = [[Debris - Battle Commander - Level 2]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2800,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 320,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 320,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corcom2 = unitDef })
