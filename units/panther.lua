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
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Tanque agressor]],
    description_fr = [[Tank Pilleur]],
	description_de = [[Blitzschlag Raider Panzer]],
	description_pl = [[Lekki czolg szturmowy]],
    helptext       = [[The Panther is a high-tech raider. Its weapon, a lightning gun, deals mostly paralyze damage. This way, the Panther can disable turrets, waltz through the defensive line, and proceed to level the economic heart of the opponent's base. When killed, it sets off an EMP explosion that can stun surrounding raiders.]],
    helptext_bp    = [[Panther é um agressor de alta tecnologia. sua arma de raios cause principalmente dano PEM, permitindo ao Panther paralizar as defesas inimigas e ent?o passar direto por elas para destruir a infra-estrutura inimiga.]],
    helptext_fr    = [[Le Panther est un pilleur high-tech. Son canon principal sert ? paralyser l'ennemi, lui permettant de traverser les d?fenses afin de s'attaquer au coeur ?conomique d'une base]],
	helptext_de    = [[Der Panther ist ein hoch entwickelter Raider, dessen Waffe, eine Blitzkanone, hauptsächlich paralysierenden Schaden austeilt. Auf diesem Wege kann der Panther Türme ausschalten und sich so durch die feindlichen Verteidigungslinien walzen, bis zur Egalisierung der feindlichen, ökonimischen Grundversorgung.]],
	helptext_pl    = [[Panther jest szybki i zadaje mieszane obrazenia EMP, co pozwala mu paralizowac i omijac wrogie jednostki, aby niszczyc wroga ekonomie.]],
	modelradius    = [[10]],
  },

  explodeAs              = [[PANTHER_DEATH]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[tankraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 198,
  maxDamage              = 980,
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

  side                   = [[ARM]],
  sightDistance          = 450,
  smoothAnim             = true,
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
        extra_damage = [[220]],
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
      range                   = 250,
      reloadtime              = 3,
      rgbColor                = [[0.5 0.5 1]],
      soundStart              = [[weapon/more_lightning_fast]],
      soundTrigger            = true,
      startsmoke              = [[1]],
      targetMoveError         = 0.1,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 400,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Panther]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 980,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 120,
      object           = [[corseal_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP  = {
      description      = [[Debris - Panther]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 980,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 60,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ panther = unitDef })
