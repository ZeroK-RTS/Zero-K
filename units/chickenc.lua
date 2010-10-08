unitDef = {
  unitname            = [[chickenc]],
  name                = [[Basilisk]],
  description         = [[All-Terrain Riot]],
  acceleration        = 0.36,
  bmcode              = [[1]],
  brakeRate           = 0.2,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickenc.png]],
  buildTime           = 520,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],

  customParams        = {
    description_fr = [[All-Terrain Riot]],
    helptext       = [[The Basilisk climbs walls like a spider to surprise the enemy with its highly acidic spit. Only a vigilant watch keeps these critters from sauntering over hills to wreck your base from unexpected directions. Gunships are the best solution to Basilisk incursions.]],
    helptext_fr    = [[]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[NOWEAPON]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[chickenc]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 264,
  maxDamage           = 1800,
  maxSlope            = 72,
  maxVelocity         = 2.2,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[ATKBOT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[chickenc.s3o]],
  power               = 520,
  seismicSignature    = 4,
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side                = [[THUNDERBIRDS]],
  sightDistance       = 512,
  smoothAnim          = true,
  sonarDistance       = 450,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  trackOffset         = 0.5,
  trackStrength       = 9,
  trackStretch        = 1,
  trackType           = [[ChickenTrackPointy]],
  trackWidth          = 70,
  turninplace		  = 0,
  turnRate            = 768,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT GUNSHIP SHIP HOVER]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Blob]],
      areaOfEffect            = 128,
      burst                   = 4,
      burstrate               = 0.01,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 140,
        planes  = 140,
        subs    = 7,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:green_goo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 400,
      reloadtime              = 3,
      renderType              = 4,
      rgbColor                = [[0.2 0.6 0]],
      size                    = 8,
      sizeDecay               = 0,
      soundHit                = [[golgotha/acid2]],
      soundStart              = [[golgotha/acid]],
      sprayAngle              = 1024,
      startsmoke              = [[0]],
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.2,
      weaponType              = [[Cannon]],
      weaponVelocity          = 400,
    },

  },

}

return lowerkeys({ chickenc = unitDef })
