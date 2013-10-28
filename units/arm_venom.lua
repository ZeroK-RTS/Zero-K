unitDef = {
  unitname               = [[arm_venom]],
  name                   = [[Venom]],
  description            = [[Riot Lightning Spider]],
  acceleration           = 0.26,
  brakeRate              = 0.26,
  buildCostEnergy        = 200,
  buildCostMetal         = 200,
  buildPic               = [[arm_venom.png]],
  buildTime              = 200,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[40 30 40]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Aranha de PEM dispersadora]],
    description_es = [[Ara?a PEM de alborote]],
    description_fi = [[EMP-mellakkarobotti]],
    description_fr = [[Araignée à effet de zone EMP]],
    description_it = [[Ragno PEM da rissa]],
    description_de = [[Unterstützende EMP Spinne]],
    helptext       = [[The Venom is an all-terrain unit designed to paralyze enemies so other units can easily destroy them. It moves particularly fast for a riot unit as in addition to paralysis it does a small amount of damage. Works well in tandem with the Recluse to keep enemies from closing range with the fragile skirmisher.]],
    helptext_bp    = [[Venon é uma unidade escaladora projetada para paralizar inimigos para que outras unidades possam destruílos facilmente. Seus tiros podem atingir múltiplas unidades e portanto é útil como dispersadora. Funciona bem junto com o Recluse para impedir os inimigos de se aproximarem deste.]],
    helptext_es    = [[El Venom es una unidad all-terrain hecha para paralizar a los nemigos, permitiendo que otras unidades puedan destruirlos fácilmente. Tiene AdE y es útil como unidad de alboroto, para tener a la larga pelotones de enemigos. Funciona bien juntado con los recluse para no dejar que los enemigos se acerquen demasiado al frágil escaramuzador.]],
    helptext_fi    = [[Maastokelpoinen Venom kykenee EMP-aseellaan halvaannuttamaan vihollisen yksik?t niin, ett? ne voidaan tuhota vaaratta. Tehokas toimiessaan yhdess? Recluse:n kanssa. Tuhoutuu nopeasti vihollisen tuliksen alla.]],
    helptext_fr    = [[Le Venom est une araignée tout terrain rapide spécialement conçue pour paralyser l'ennemi afin que d'autres unités puissent les détruire rapidement et sans risques. Sa faible portée est compensée par son effet de zone pouvant affecter plusieurs unités à proximité de sa cible. Est particulièrement efficace en tandem avec le Recluse ou l'Hermit.]],
    helptext_it    = [[Il Venom é un'unita all-terrain fatta per paralizzare i nemici cosi che altre unita le possano distruggere facilmente. Ha un AdE ed é utile come unita da rissa, per tenere lontano sciame di nemici. Funziona bene con i recluse per non peremttere ai nemici di avvicinarsi troppo al fragili scaramuzzatore.]],
	helptext_de    = [[Venom ist eine geländeunabhängige Einheit, welche Gegner paralysieren kann, damit andere Einheiten diese einfach zerstören können. Venom besitzt eine AoE und ist nützlich, um gengerische Schwärme in Schach zu halten.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[spiderriot]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 750,
  maxSlope               = 72,
  maxVelocity            = 2.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[venom.s3o]],
  script                 = [[arm_venom.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:YELLOW_LIGHTNING_MUZZLE]],
      [[custom:YELLOW_LIGHTNING_GROUNDFLASH]],
    },

  },

  sightDistance          = 440,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShort]],
  trackWidth             = 54,
  turnRate               = 1600,

  weapons                = {

    {
      def                = [[spider]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },

  },

  weaponDefs             = {

    spider = {
      name                    = [[Electro-Stunner]],
      areaOfEffect            = 160,
      beamWeapon              = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
	  
      customParams            = {
        extra_damage = [[18]],
        extra_damage_falloff_max = [[600]], -- make the extra damage proportional to (actual damage dealt)/extra_damage_falloff_max
      },

      damage                  = {
        default        = 600,
      },

      duration                = 8,
      explosionGenerator      = [[custom:LIGHTNINGPLOSION160AoE]],
      fireStarter             = 0,
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      paralyzer               = true,
      paralyzeTime            = 3,
      range                   = 240,
      reloadtime              = 1.75,
      rgbColor                = [[1 1 0.7]],
      soundStart              = [[weapon/lightning_fire]],
      soundTrigger            = true,
      targetMoveError         = 0,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 450,
    },

  },

  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Venom]],
      blocking         = false,
      damage           = 750,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 80,
      object           = [[venom_wreck.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,

    },
    HEAP  = {
      description      = [[Debris - Venom]],
      blocking         = false,
      damage           = 750,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 40,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 40,
    },

  },

}

return lowerkeys({ arm_venom = unitDef })
