unitDef = {
  unitname            = [[cordecom]],
  name                = [[Decoy Commander]],
  description         = [[Decoy Commander, Builds at 12 m/s]],
  acceleration        = 0.18,
  activateWhenBuilt   = true,
  autoHeal            = 5,
  bmcode              = [[1]],
  brakeRate           = 0.375,
  buildCostEnergy     = 750,
  buildCostMetal      = 750,
  buildDistance       = 120,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[cordecom.png]],
  buildTime           = 750,
  canAttack           = true,
  canDGun             = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canreclamate        = [[1]],
  canstop             = [[1]],
  category            = [[LAND]],
  decoyFor            = [[corcom]],
  defaultmissiontype  = [[Standby]],
  energyMake          = 0.15,
  energyUse           = 0,
  explodeAs           = [[DECOY_COMMANDER_BLAST]],
  footprintX          = 2,
  footprintZ          = 2,
  hideDamage          = true,
  iconType            = [[corcommander]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  immunetoparalyzer   = [[1]],
  maneuverleashlength = [[640]],
  mass                = 2500,
  maxDamage           = 3000,
  maxSlope            = 36,
  maxVelocity         = 1.45,
  maxWaterDepth       = 5000,
  metalMake           = 0.15,
  minCloakDistance    = 75,
  movementClass       = [[AKBOT2]],
  norestrict          = [[1]],
  objectName          = [[corcom.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[DECOY_COMMANDER_BLAST]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  showNanoSpray       = false,
  showPlayerName      = false,
  side                = [[CORE]],
  sightDistance       = 450,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[COMMANDER]],
  terraformSpeed      = 600,
  turnRate            = 1133,
  upright             = true,
  workerTime          = 12,

  weapons             = {

    [1] = {
      def                = [[FAKELASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    [3] = {
      def = [[DECOY_DISINTEGRATOR]],
    },


    [4] = {
      def                = [[CORCOMLASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    CORCOMLASER         = {
      name                    = [[J7Laser]],
      areaOfEffect            = 12,
      beamWeapon              = true,
      canattackground         = true,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 37,
        subs    = [[5]],
      },

      duration                = 0.02,
      edgeEffectiveness       = 0.99,
      explosionGenerator      = [[custom:COMLASERFLASH]],
      fireStarter             = 70,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      lodDistance             = 10000,
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 0.2,
      renderType              = 0,
      rgbColor                = [[1 0 0]],
      soundHit                = [[laserhit]],
      soundStart              = [[OTAunit/LASRFIR1]],
      soundTrigger            = true,
      targetMoveError         = 0.05,
      thickness               = 5.48292804986533,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 1900,
    },


    DECOY_DISINTEGRATOR = {
      name                    = [[Disintegrator]],
      areaOfEffect            = 32,
      beamWeapon              = true,
      commandfire             = true,
      craterBoost             = 1,
      craterMult              = 0,

      damage                  = {
        default        = 99999,
        commanders     = [[10]],
        ["else"]       = [[10]],
        empresistant75 = [[10]],
        empresistant99 = [[10]],
        flamethrowers  = [[10]],
        mines          = [[10]],
        planes         = [[10]],
        subs           = [[10]],
      },

      energypershot           = 5,
      explosionGenerator      = [[custom:DGUNTRACE]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noExplode               = true,
      noSelfDamage            = true,
      range                   = 250,
      reloadtime              = 1.5,
      renderType              = 3,
      soundHit                = [[OTAunit/XPLOMAS2]],
      soundStart              = [[OTAunit/DISIGUN1]],
      soundTrigger            = true,
      startsmoke              = [[1]],
      tolerance               = 10000,
      turret                  = true,
      weaponTimer             = 4.2,
      weaponType              = [[DGun]],
      weaponVelocity          = 300,
    },


    FAKELASER           = {
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
      range                   = 250,
      reloadtime              = 0.11,
      renderType              = 0,
      rgbColor                = [[0 1 0]],
      soundHit                = [[OTAunit/BURN02]],
      soundStart              = [[OTAunit/BUILD2]],
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

  },

}

return lowerkeys({ cordecom = unitDef })
