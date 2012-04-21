unitDef = {
  unitname            = [[hoverriot]],
  name                = [[Mace]],
  description         = [[Riot Hover]],
  acceleration        = 0.03,
  brakeRate           = 0.043,
  buildCostEnergy     = 400,
  buildCostMetal      = 400,
  builder             = false,
  buildPic            = [[hoverriot.png]],
  buildTime           = 400,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[60 29 64]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]], 
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Hover dispersador]],
    description_fr = [[Hover ?meutier]],
	description_de = [[Riotgleiter]],
    helptext       = [[The Mace is a mobile laser tower. Its high firepower is useful for killing light enemy units. It is perfectly accurate and is good against gunships and fast units. However, its thin armor makes it vulnerable when targetted directly, especially by skirmishers.]],
    helptext_bp    = [[Mace ? uma torre de laser m?vel. Seu alto poder de fogo e precis?o s?o ?teis para matar unidades pequenas e r?pidas e aeronaves de voo baixo.]],
    helptext_fr    = [[Le Mace est une tour laser mobile. Sa forte puissance de feu et sa pr?cision parfaite sont appreciable pour se debarrasser de petites unit?s.]],
	helptext_de    = [[Der Mace ist ein mobiler Laserturm. Seine hohe Feuerkraft ist nützlich, um leichte, feindliche Einheiten zu töten. Er schießt höchst präzise und erweist sich gegen Hubschrauber und schnelle Einheiten als nützlich. Trotzdem macht ihn seine einfache Verteidigung anfällig für direkte Angriffe, vor allem durch Skirmisher.]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverriot]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  mass                = 215,
  maxDamage           = 1200,
  maxSlope            = 36,
  maxVelocity         = 2.2,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[hoverriot.s3o]],
  onoffable           = true,
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 407,
  smoothAnim          = true,
  turninplace         = 0,
  turnRate            = 616,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[LASER1]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    LASER1 = {
      name                    = [[High Intensity Laserbeam]],
      areaOfEffect            = 8,
      beamlaser               = 1,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 35,
        subs    = 1.75,
      },

      explosionGenerator      = [[custom:flash1green]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4.33,
      lineOfSight             = true,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 355,
      reloadtime              = 0.1,
      renderType              = 0,
      rgbColor                = [[0 1 0]],
      soundStart              = [[weapon/laser/laser_burn10]],
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 4.33,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Mace]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 1200,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 160,
      object           = [[hoverriot_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 160,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Mace]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1200,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 80,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ hoverriot = unitDef })
