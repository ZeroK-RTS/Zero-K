unitDef = {
  unitname            = [[chickenbroodqueen]],
  name                = [[Chicken Brood Queen]],
  description         = [[Tends the Nest]],
  acceleration        = 0.2,
  autoHeal            = 10,
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  buildDistance       = 240,
  builder             = true,

  buildoptions        = {
    [[chicken_drone]],
    [[chicken]],
    [[chicken_leaper]],
    [[chickena]],
    [[chickens]],
    [[chickenc]],
    [[chickenr]],
    [[chickenblobber]],
    [[chicken_spidermonkey]],
    [[chicken_sporeshooter]],
    [[chicken_listener]],
    [[chickenwurm]],
    [[chicken_dodo]],
    [[chicken_digger]],
    [[chicken_shield]],
    [[chicken_tiamat]],
    [[chicken_pigeon]],
    [[chickenf]],
    [[chicken_blimpy]],
    [[chicken_dragon]],
  },

  buildPic            = [[chickenbroodqueen.png]],
  buildTime           = 1000,
  canAttack           = true,
  CanBeAssisted       = 0,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = true,
  cantBeTransported   = true,
  category            = [[LAND]],

  customParams        = {
    description_fr = [[Reine pondeuse]],
	description_de = [[Pflegt und hegt das Nest]],
    helptext       = [[The egg-laying brood queen is not quite as fearsome in combat as the other queen, but can in the long run present an even bigger threat. It produces all the different chicken breeds of the Thunderbirds.]],
    helptext_fr    = [[Cette reine pondeuse n'est pas aussi effrayante en combat que l'autre reine mais peut ? long terme se montrer une menace bien plus grande. En ?ffet elle peut engendrer rapidement par elle-m?me toutes les unit?s poulet.]],
	helptext_de    = [[Die eierlegende, br�Eende K�nigin ist im Gefecht nicht ganz so furchterregend wie die anderen K�niginnen, aber auf weite Sicht kann sie sogar eine gr��ere Gefahr darstellen. Sie erzeugt all die verschiedenen Chickenrassen der Thunderbirds.]],
  },

  energyStorage       = 0,
  explodeAs           = [[SMALL_UNITEX]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[chickenc]],
  idleAutoHeal        = 0,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 3000,
  maxSlope            = 72,
  maxVelocity         = 2,
  maxWaterDepth       = 22,
  metalMake           = 0.4,
  metalStorage        = 0,
  minCloakDistance    = 75,
  movementClass       = [[TKBOT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[chickenbroodqueen.s3o]],
  power               = 2500,
  reclaimable         = false,
  seismicSignature    = 4,
  selfDestructAs      = [[SMALL_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  showNanoSpray       = false,
  showPlayerName      = true,
  sightDistance       = 1024,
  sonarDistance       = 450,
  trackOffset         = 8,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 40,
  turninplace         = 0,
  turnRate            = 573,
  upright             = false,
  workerTime          = 8,

  weapons             = {

    {
      def                = [[MELEE]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    MELEE  = {
      name                    = [[ChickenClaws]],
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 0,

      damage                  = {
        default = 40,
        planes  = 40,
        subs    = 40,
      },

      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 1,
      interceptedByShieldType = 0,
      noSelfDamage            = true,
      range                   = 120,
      reloadtime              = 0.4,
      size                    = 0,
      soundStart              = [[chickens/bigchickenbreath]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },


    SPORES = {
      name                    = [[Spores]],
      areaOfEffect            = 24,
      avoidFriendly           = false,
      burst                   = 4,
      burstrate               = 0.1,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        light_radius = 0,
      },
      
      damage                  = {
        default = 30,
        subs    = 1.5,
      },

      dance                   = 60,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      flightTime              = 4,
      groundbounce            = 1,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      metalpershot            = 0,
      model                   = [[chickeneggpink.s3o]],
      noSelfDamage            = true,
      range                   = 240,
      reloadtime              = 3,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med14]],
      startVelocity           = 200,
      texture1                = [[]],
      texture2                = [[sporetrail]],
      tolerance               = 10000,
      tracks                  = true,
      trajectoryHeight        = 2,
      turnRate                = 48000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 200,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 1000,
      wobble                  = 64000,
    },

  },

}

return lowerkeys({ chickenbroodqueen = unitDef })
