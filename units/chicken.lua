unitDef = {
  unitname            = [[chicken]],
  name                = [[Chicken]],
  description         = [[Swarmer]],
  acceleration        = 0.36,
  bmcode              = [[1]],
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken.png]],
  buildTime           = 25,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[SWIM]],

  customParams        = {
    description_fr = [[Soldat d'essaim]],
	description_de = [[Schwärmer]],
    helptext       = [[The footsoldier of the Thunderbirds is an aggressive zergling-type unit. What it lacks in individual strength, it compensates for with its sheer numbers, overwhelming enemies with floods and floods of little chickens. A good riot unit is recommended for stopping them.]],
    helptext_fr    = [[Le soldat de base terrestre des poulets est une cr?ature agressive apparent?e aux Zergs. Ce qu'il lui manque en puissance il le compense par son nombre impressionnant lors des attaques qui submerge l'adversaire sous un flot continu de petites unit?s. Pour les contrer rien de mieux qu'une arme anti ?meute.]],
	helptext_de    = [[Diser Fußsoldat ist eine aggressive Einheit. Zwar besitzt es keine außergewöhnlichen, individuellen Qualitäten oder Stärken, doch kompensiert es diesen Mangel mit der ungeheuren Anzahl, mit der diese Einheiten erscheinen. Eine gute Rioteinheit wird empfohle, um diese Chicken zu stoppen.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[NOWEAPON]],
  floater             = false,
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[chicken]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 68,
  maxDamage           = 270,
  maxSlope            = 36,
  maxVelocity         = 2.9,
  minCloakDistance    = 75,
  movementClass       = [[BHOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[chicken.s3o]],
  power               = 100,
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
  sightDistance       = 256,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 18,
  turnRate            = 806,
  upright             = false,
  waterline           = 8,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SUB SINK FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Claws]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 80,
        planes  = 80,
        subs    = 80,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 80,
      reloadtime              = 1.2,
      size                    = 0,
      soundHit                = [[chickens/chickenbig2]],
      soundStart              = [[chickens/chicken]],
      startsmoke              = [[0]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },

}

return lowerkeys({ chicken = unitDef })
