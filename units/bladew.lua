unitDef = {
  unitname            = [[bladew]],
  name                = [[Gnat]],
  description         = [[Light Paralyzer Drone]],
  acceleration        = 0.264,
  altfromsealevel     = [[56]],
  amphibious          = true,
  bankscale           = [[1.64]],
  bmcode              = [[1]],
  brakeRate           = 3.5,
  buildCostEnergy     = 70,
  buildCostMetal      = 70,
  builder             = false,
  buildPic            = [[BLADEW.png]],
  buildTime           = 70,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collide             = true,
  cruiseAlt           = 78,

  customParams        = {
    description_fr = [[Drône Paralysant Léger]],
    helptext       = [[The Gnat can be used to paralyze enemy units. It makes an excellent defensive unit, and when combined with banshees or other units can halt the enemy to give you time to kill him. Offensively it can paralyze even heavily fortified areas, but dies relatively easily to defenders.]],
    helptext_fr    = [[Le Gnat peut etre utilisé pour paralyser les unités légcres. Utilisé en groupe il peut meme s'attaquer r des cibles plus grosses, mais sa fragilité rends cette tactique plus difficile.]],
  },

  defaultmissiontype  = [[VTOL_standby]],
  explodeAs           = [[TINY_BUILDINGEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverAttack         = true,
  iconType            = [[gunship]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  immunetoparalyzer   = [[1]],
  maneuverleashlength = [[1240]],
  mass                = 73,
  maxDamage           = 90,
  maxVelocity         = 10,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[marshmellow.s3o]],
  scale               = [[1]],
  seismicSignature    = 0,
  selfDestructAs      = [[TINY_BUILDINGEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:VINDIBACK]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 380,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[VTOL]],
  turnRate            = 1144,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[PARALYZER]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    PARALYZER = {
      name                    = [[Light Electro-Stunner]],
      areaOfEffect            = 8,
      beamWeapon              = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default        = 400,
        commanders     = 40,
        empresistant75 = 100,
        empresistant99 = 4,
      },

      duration                = 0.01,
      energypershot           = [[0]],
      explosionGenerator      = [[custom:YELLOW_LIGHTNING_BOMB]],
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      minbarrelangle          = [[0]],
      noSelfDamage            = true,
      paralyzer               = true,
      paralyzeTime            = 7,
      range                   = 220,
      reloadtime              = 1.2,
      renderType              = 7,
      rgbColor                = [[1 1 0.25]],
      soundStart              = [[weapon/small_lightning]],
      soundTrigger            = false,
      targetMoveError         = 0.3,
      texture1                = [[lightning]],
      thickness               = 1.2,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 800,
    },

  },

}

return lowerkeys({ bladew = unitDef })
