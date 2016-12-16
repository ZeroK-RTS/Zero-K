unitDef = {
  unitname            = [[chickenblobber]],
  name                = [[Blobber]],
  description         = [[Heavy Artillery]],
  acceleration        = 0.36,
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickenblobber.png]],
  buildTime           = 900,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],

  customParams        = {
    description_fr = [[Artillery Lourde poulet]],
	description_de = [[Schwere Artillerie]],
    helptext       = [[The Lobber's big brother, the Blobber hurls a wide-scatter rain of acid goo. It can pummel even the toughest shield network very quickly, but remains relatively prone to direct attack.]],
    helptext_fr    = [[Grand fr?re du Lobber, le Blobber projette ? longue distance une v?ritable pluie d'acide sur une zone importante. Il peut ainsi rapidement annihiler m?me les d?fenses prot?g?es par un important r?seau de boucliers mais il reste tr?s vuln?rable aux attaques raproch?es.]],
	helptext_de    = [[Der gro�e Bruder vom Lobber, der Blobber, schleudert eine weite Streuung an �tzender Schmiere. Er kann sogar die st�krsten Schildnetze sehr schnell einschlagen, doch gegen direkte Attacken wirkt er sehr anf�llig.]],
  },

  explodeAs           = [[NOWEAPON]],
  footprintX          = 4,
  footprintZ          = 4,
  highTrajectory      = 1,
  iconType            = [[walkerlrarty]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 2400,
  maxSlope            = 36,
  maxVelocity         = 1.8,
  maxWaterDepth       = 5000,
  minCloakDistance    = 75,
  movementClass       = [[BHOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB MOBILE STUPIDTARGET MINE]],
  objectName          = [[chickenblobber.s3o]],
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
  sightDistance       = 1200,
  sonarDistance       = 450,
  trackOffset         = 6,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 30,
  turnRate            = 806,
  upright             = false,
  waterline           = 24,
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
      name                    = [[Scatterblob]],
      areaOfEffect            = 96,
      burst                   = 11,
      burstrate               = 0.01,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 180,
        planes  = 180,
        subs    = 9,
      },

      explosionGenerator      = [[custom:blobber_goo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      mygravity               = 0.1,
      range                   = 1350,
      reloadtime              = 8,
      rgbColor                = [[0.2 0.6 0.0]],
      size                    = 8,
      sizeDecay               = 0,
      soundHit                = [[chickens/acid_hit]],
      soundStart              = [[chickens/acid_fire]],
      sprayAngle              = 1792,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 350,
    },

  },

}

return lowerkeys({ chickenblobber = unitDef })
