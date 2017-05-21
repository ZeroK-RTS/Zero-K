unitDef = {
  unitname               = [[cloakassault]],
  name                   = [[Zeus]],
  description            = [[Lightning Assault Bot]],
  acceleration           = 0.2,
  brakeRate              = 0.6,
  buildCostMetal         = 350,
  buildPic               = [[cloakassault.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 7]],
  collisionVolumeScales  = [[35 50 35]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Sturmroboter]],
    description_fr = [[Marcheur d'Assaut]],
    helptext       = [[Slowly and steadily, groups of Zeuses can shrug off heavy fire as they make their way towards enemy fortifications, until they can field their short-range lightning cannon, which damages and stuns entrenched foes. Counter with anything that can reliably kite it, making sure that you don't get paralyzed (in which case you are as good as dead.)]],
    helptext_de    = [[Langsam und zuverlässig, Gruppen von Zeus' können sogar starken Beschuss ignorieren und so schnell an die feindliche Festung herankommen, bis sie dort ihre Blitzschlagkanonen mit kurzer Reichweite zum Einsatz bringen können, welche feindliche Einheiten schädigt und betäubt. Kontere den Zeus mit Einheiten, die umherflitzen, damit sie nicht paralysiert werden (denn dann sind sie so gut wie tot).]],
    helptext_fr    = [[Lentement mais surement, un groupe de Zeus peut encaisser les tirs enemis lourd jusqu'a ce qu'ils atteignent les fortifications et puissent utiliser leur canon éclair courte portée qui peut paralyser et endommager les enemis retranchés.]],
	modelradius    = [[12]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[kbotassault]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  losEmitHeight          = 35,
  maxDamage              = 2400,
  maxSlope               = 36,
  maxVelocity            = 1.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB]],
  objectName             = [[spherezeus.s3o]],
  script		         = [[cloakassault.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:zeusmuzzle]],
      [[custom:zeusgroundflash]],
    },

  },

  sightDistance          = 325,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 26,
  turnRate               = 1400,
  upright                = true,

  weapons                = {

    {
      def                = [[LIGHTNING]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    LIGHTNING = {
      name                    = [[Lightning Gun]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        extra_damage = 600,
		
		light_camera_height = 1600,
		light_color = [[0.85 0.85 1.2]],
		light_radius = 200,
      },

      cylinderTargeting      = 0,

      damage                  = {
        default        = 240,
      },

      duration                = 10,
      explosionGenerator      = [[custom:LIGHTNINGPLOSION]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      paralyzeTime            = 1,
      range                   = 280,
      reloadtime              = 2.2,
      rgbColor                = [[0.5 0.5 1]],
      soundStart              = [[weapon/more_lightning_fast]],
      soundTrigger            = true,
      sprayAngle              = 900,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      waterweapon             = false,
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
      object           = [[spherezeus_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ cloakassault = unitDef })
