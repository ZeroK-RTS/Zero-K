unitDef = {
  unitname               = [[panther]],
  name                   = [[Panther]],
  description            = [[Lightning Assault/Raider Tank]],
  acceleration           = 0.125,
  brakeRate              = 0.1375,
  buildCostEnergy        = 300,
  buildCostMetal         = 300,
  builder                = false,
  buildPic               = [[panther.png]],
  buildTime              = 300,
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
    helptext       = [[The Panther is a high-tech raider. Its weapon, a lightning gun, deals mostly paralyze damage. This way, the Panther can disable turrets, waltz through the defensive line, and proceed to level the economic heart of the opponent's base. When killed, it sets off an EMP explosion that can stun surrounding raiders.]],
    helptext_fr    = [[Le Panther est un pilleur high-tech. Son canon principal sert ? paralyser l'ennemi, lui permettant de traverser les d?fenses afin de s'attaquer au coeur ?conomique d'une base]],
	helptext_de    = [[Der Panther ist ein hoch entwickelter Raider, dessen Waffe, eine Blitzkanone, hauptsächlich paralysierenden Schaden austeilt. Auf diesem Wege kann der Panther Türme ausschalten und sich so durch die feindlichen Verteidigungslinien walzen, bis zur Egalisierung der feindlichen, ökonimischen Grundversorgung.]],
	modelradius    = [[10]],
	stats_show_death_explosion = 1,
  },

  explodeAs              = [[PANTHER_DEATH]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[tankraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 1100,
  maxSlope               = 18,
  maxVelocity            = 3.4,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TANK3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[corseal.s3o]],
  script                 = [[panther.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[PANTHER_DEATH]],

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
      def                = [[ARMLATNK_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    ARMLATNK_WEAPON = {
      name                    = [[Lightning Gun]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        extra_damage = [[190]],
		
		light_camera_height = 1600,
		light_color = [[0.85 0.85 1.2]],
		light_radius = 180,
      },

      cylinderTargeting      = 0,

      damage                  = {
        default        = 500,
        empresistant75 = 125,
        empresistant99 = 5,
      },

      duration                = 10,
      explosionGenerator      = [[custom:LIGHTNINGPLOSION]],
      fireStarter             = 150,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      paralyzer               = true,
      paralyzeTime            = 1,
      range                   = 260,
      reloadtime              = 3,
      rgbColor                = [[0.5 0.5 1]],
      soundStart              = [[weapon/more_lightning_fast]],
      soundTrigger            = true,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 400,
    },

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

return lowerkeys({ panther = unitDef })
