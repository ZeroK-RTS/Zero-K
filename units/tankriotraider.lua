unitDef = {
  unitname               = [[tankriotraider]],
  name                   = [[Panther]],
  description            = [[Riot/Raider Tank]],
  acceleration           = 0.125,
  brakeRate              = 0.1375,
  buildCostEnergy        = 180,
  buildCostMetal         = 180,
  builder                = false,
  buildPic               = [[panther.png]],
  buildTime              = 180,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[28 12 28]],
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Tank Pilleur]],
	description_de = [[Blitzschlag Raider Panzer]],
    helptext       = [[The Panther is a high-tech raider. Its weapon, a lightning gun, deals mostly paralyze damage. This way, the Panther can disable turrets, waltz through the defensive line, and proceed to level the economic heart of the opponent's base.]],
    helptext_fr    = [[Le Panther est un pilleur high-tech. Son canon principal sert ? paralyser l'ennemi, lui permettant de traverser les d?fenses afin de s'attaquer au coeur ?conomique d'une base]],
	helptext_de    = [[Der Panther ist ein hoch entwickelter Raider, dessen Waffe, eine Blitzkanone, hauptsächlich paralysierenden Schaden austeilt. Auf diesem Wege kann der Panther Türme ausschalten und sich so durch die feindlichen Verteidigungslinien walzen, bis zur Egalisierung der feindlichen, ökonimischen Grundversorgung.]],
	modelradius    = [[10]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[tankraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 360,
  maxSlope               = 18,
  maxVelocity            = 4.4,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TANK3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[corseal.s3o]],
  script                 = [[tankriotraider.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:PANTHER_SPARK]],
    },

  },
  sightDistance          = 450,
  trackOffset            = 6,
  trackStrength          = 5,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 30,
  turninplace            = 0,
  turnRate               = 616,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {
    LASER = {
      name                    = [[High-Energy Laserbeam]],
      areaOfEffect            = 0,
      beamTime                = (3/30),
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 120,
        planes  = 120,
        subs    = 6,
      },

      explosionGenerator      = [[custom:flash1bluedark]],
      fireStarter             = 90,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 9,
      minIntensity            = 1,
      noSelfDamage            = true,
      projectiles             = 4,
      range                   = 240,
      reloadtime              = (105/30),
      rgbColor                = [[0 0 1]],
      scrollSpeed             = 10,
      soundStart              = [[weapon/laser/heavy_laser3]],
      soundStartVolume        = 3,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 9,
      tileLength              = 300,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2250,
    },
	
	    -- ARMLATNK_WEAPON = {
      -- name                    = [[Lightning Gun]],
      -- areaOfEffect            = 8,
      -- craterBoost             = 0,
      -- craterMult              = 0,


      -- customParams            = {
        -- extra_damage = [[250]],
      -- },


      -- cylinderTargeting      = 0,


      -- damage                  = {
        -- default        = 800,
        -- empresistant75 = 200,
        -- empresistant99 = 80,
      -- },


      -- duration                = 10,
      -- explosionGenerator      = [[custom:LIGHTNINGPLOSION]],
      -- fireStarter             = 150,
      -- impactOnly              = true,
      -- impulseBoost            = 0,
      -- impulseFactor           = 0,
      -- intensity               = 12,
      -- interceptedByShieldType = 1,
      -- paralyzer               = true,
      -- paralyzeTime            = 1,
      -- range                   = 165,
      -- reloadtime              = 1,
      -- rgbColor                = [[0.5 0.5 1]],
      -- soundStart              = [[weapon/more_lightning_fast]],
      -- soundTrigger            = true,
      -- startsmoke              = [[1]],
      --
      -- texture1                = [[lightning]],
      -- thickness               = 10,
      -- turret                  = true,
      -- weaponType              = [[LightningCannon]],
      -- weaponVelocity          = 400,
    -- },
  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[corseal_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ tankriotraider = unitDef })
