unitDef = {
  unitname            = [[chicken_roc]],
  name                = [[Roc]],
  description         = [[Heavy Attack Flyer]],
  acceleration        = 1.2,
  airHoverFactor      = 0,
  amphibious          = true,
  brakeRate           = 1,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken_roc.png]],
  buildTime           = 1250,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canLand             = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collide             = false,
  cruiseAlt           = 150,

  customParams        = {
    helptext       = [[Large, angry and capable of fighting both air and land opposition, the Roc is a formidable flying chicken.]],
  },

  explodeAs           = [[NOWEAPON]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverattack         = true,
  iconType            = [[heavygunship]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maneuverleashlength = [[64000]],
  mass                = 600,
  maxDamage           = 2500,
  maxSlope			  = 36,
  maxVelocity         = 3,
  minCloakDistance    = 250,
  moverate1           = [[32]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP STUPIDTARGET MINE]],
  objectName          = [[chicken_roc.s3o]],
  power               = 1250,
  script              = [[chicken_roc.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[NOWEAPON]],
  separation          = [[0.2]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side                = [[THUNDERBIRDS]],
  sightDistance       = 750,
  smoothAnim          = true,
  turnRate            = 1350,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[GOO]],
      badTargetCategory  = [[GUNSHIP]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[AEROSPORES]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },


    {
      def                = [[AEROSPORES]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

  
    GOO          = {
      name                    = [[Blob]],
      areaOfEffect            = 96,
      burst                   = 6,
      burstrate               = 0.01,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 200,
        planes  = 200,
        subs    = 1,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:green_goo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      proximityPriority       = -4,
      range                   = 500,
      reloadtime              = 8,
      renderType              = 4,
      rgbColor                = [[0.2 0.6 0]],
      size                    = 8,
      sizeDecay               = 0,
      soundHit                = [[chickens/acid_hit]],
      soundStart              = [[chickens/acid_fire]],
      sprayAngle              = 1200,
      startsmoke              = [[0]],
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.2,
      weaponType              = [[Cannon]],
      weaponVelocity          = 350,
    },

    AEROSPORES = {
      name                    = [[Anti-Air Spores]],
      areaOfEffect            = 24,
      avoidFriendly           = false,
      burst                   = 4,
      burstrate               = 0.2,
	  canAttackGround		  = false,	  
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 80,
        planes  = 80,
        subs    = 8,
      },

      dance                   = 60,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      fixedlauncher           = 1,
      flightTime              = 5,
      groundbounce            = 1,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      metalpershot            = 0,
      model                   = [[chickeneggblue.s3o]],
      range                   = 500,
      reloadtime              = 5,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      startsmoke              = [[1]],
      startVelocity           = 100,
      texture1                = [[]],
      texture2                = [[sporetrailblue]],
      tolerance               = 10000,
      tracks                  = true,
      turnRate                = 24000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 500,
      wobble                  = 32000,
    },
  },

}

return lowerkeys({ chicken_roc = unitDef })
