unitDef = {
  unitname            = [[chickenwurm]],
  name                = [[Wurm]],
  description         = [[Burrowing Flamer (Assault/Riot)]],
  acceleration        = 0.36,
  bmcode              = [[1]],
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickenwurm.png]],
  buildTime           = 350,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],

  customParams        = {
    description_fr = [[Assaut souterrain]],
    helptext       = [[Burn baby Burn!]],
    helptext_fr    = [[Ces poulets tenant partiellement de la taupe ont une particularit? : ils savent mettre le feu o? qu'ils aillent.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[CORPYRO_NAPALM]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[chickena]],
  idleAutoHeal        = 10,
  idleTime            = 600,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 231,
  maxDamage           = 1900,
  maxSlope            = 90,
  maxVelocity         = 1.8,
  maxWaterDepth       = 5000,
  minCloakDistance    = 75,
  movementClass       = [[ATKBOT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING GUNSHIP SATELLITE SUB]],
  objectName          = [[chickenwurm.s3o]],
  power               = 350,
  script              = [[chickenwurm.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[CORPYRO_NAPALM]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side                = [[THUNDERBIRDS]],
  sightDistance       = 384,
  smoothAnim          = true,
  stealth             = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  turnRate            = 806,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[NAPALM]],
      badTargetCategory  = [[GUNSHIP]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT GUNSHIP SHIP HOVER]],
    },

  },


  weaponDefs          = {

    NAPALM = {
      name                    = [[Napalm Blob]],
      areaOfEffect            = 64,
      burst                   = 6,
      burstrate               = 0.01,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 50,
        planes  = 50,
        subs    = 7,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NAPALM_Expl]],
      fireStarter             = 400,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 260,
      reloadtime              = 4,
      renderType              = 4,
      rgbColor                = [[0.8 0.3 0]],
      size                    = 3,
      sizeDecay               = 0,
      soundHit                = [[chickens/acid_hit]],
      soundStart              = [[chickens/acid_fire]],
      sprayAngle              = 1024,
      startsmoke              = [[0]],
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.2,
      weaponType              = [[Cannon]],
      weaponVelocity          = 200,
    },

  },

}

return lowerkeys({ chickenwurm = unitDef })
