unitDef = {
  unitname            = [[chicken]],
  name                = [[Chicken]],
  description         = [[Swarmer]],
  acceleration        = 0.36,
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken.png]],
  buildTime           = 25,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[SWIM]],

  customParams        = {
    description_fr = [[Soldat de colonie]],
	description_de = [[Schw�rmer]],
    helptext       = [[The footsoldier of the Thunderbirds is an aggressive zergling-type unit. What it lacks in individual strength, it compensates for with its sheer numbers, overwhelming enemies with floods and floods of little chickens. A good riot unit is recommended for stopping them.]],
    helptext_fr    = [[Le soldat de base terrestre des poulets est une petite cr�ature rapide et agressive apparent�e aux Zergs. Seul peu utile, sa force se r�v�le lors d'assaut en masse compacte, submergeant l'adversaire sous un fl�t continu d'unit�s pouvant r�duire en cendres une base enti�re. Pour les contrer rien de mieux qu'une arme anti �meute. Plusieurs �tant pr�f�rable.]],
	helptext_de    = [[Diser Fu�soldat ist eine aggressive Einheit. Zwar besitzt es keine au�ergew�hnlichen, individuellen Qualit�ten oder St�rken, doch kompensiert es diesen Mangel mit der ungeheuren Anzahl, mit der diese Einheiten erscheinen. Eine gute Rioteinheit wird empfohle, um diese Chicken zu stoppen.]],
  },

  explodeAs           = [[NOWEAPON]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[chicken]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
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
  sightDistance       = 256,
  sonarDistance       = 200,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 18,
  turnRate            = 806,
  upright             = false,
  waterline           = 16,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Claws]],
      avoidFeature            = false,
      avoidFriendly           = false,
      collideFeature          = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 80,
        planes  = 80,
        subs    = 80,
      },

      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      range                   = 80,
      reloadtime              = 1.2,
      size                    = 0,
      soundHit                = [[chickens/chickenbig2]],
      soundStart              = [[chickens/chicken]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },

}

return lowerkeys({ chicken = unitDef })
