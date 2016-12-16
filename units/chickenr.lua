unitDef = {
  unitname            = [[chickenr]],
  name                = [[Lobber]],
  description         = [[Artillery]],
  acceleration        = 0.36,
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickenr.png]],
  buildTime           = 200,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],

  customParams        = {
    description_fr = [[Artillerie l?g?re]],
	description_de = [[Artillerie]],
    helptext       = [[A form of organic artillery, the Lobber hurls balls of venom at a high trajectory over long distances. It proves a problem for those who rely excessively on static defenses, but is practically helpless when attacked directly.]],
    helptext_fr    = [[Un genre d'artillerie organique, le Lobber projette des boules envenim?es corrosives selon une trajectoire en cloche sur de longues distances, ce qui pose un probl?me de taille aux ennemis se concentrant sur une d?fense statique. Mais il est sans d?fenses face aux attaques raproch?es.]],
	helptext_de    = [[Eine Form organischer Artillerie. Der Lobber schleudert Giftb�lle in einer hohen Flugkurve �ber lange Distanzen. Er stellt eine Problem f�r diejenigen dar, die sich auf station�re Verteidigungsanlagen verlassen. Relativ hilflos ist er, sobald er direkt angegriffen wird.]],
  },

  explodeAs           = [[NOWEAPON]],
  footprintX          = 2,
  footprintZ          = 2,
  highTrajectory      = 1,
  iconType            = [[chickenr]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 500,
  maxSlope            = 36,
  maxVelocity         = 1.8,
  maxWaterDepth       = 5000,
  minCloakDistance    = 75,
  movementClass       = [[BHOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB MOBILE STUPIDTARGET MINE]],
  objectName          = [[chickenr.s3o]],
  power               = 400,
  seismicSignature    = 4,
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance       = 1000,
  sonarDistance       = 450,
  trackOffset         = 6,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 30,
  turnRate            = 806,
  upright             = false,
  waterline			  = 16,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      badTargetCategory  = [[SWIM SHIP HOVER MOBILE]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Blob]],
      areaOfEffect            = 32,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 240,
        planes  = 240,
        subs    = 8,
      },

      explosionGenerator      = [[custom:lobber_goo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      mygravity               = 0.1,
      noSelfDamage            = true,
      range                   = 950,
      reloadtime              = 6,
      rgbColor                = [[0.2 0.6 0.0]],
      size                    = 8,
      sizeDecay               = 0,
      soundHit                = [[chickens/acid_hit]],
      soundStart              = [[chickens/acid_fire]],
      sprayAngle              = 256,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 300,
    },

  },

}

return lowerkeys({ chickenr = unitDef })
