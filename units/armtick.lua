unitDef = {
  unitname               = [[armtick]],
  name                   = [[Tick]],
  description            = [[All Terrain EMP Bomb (Burrows)]],
  acceleration           = 0.25,
  brakeRate              = 0.6,
  buildCostEnergy        = 120,
  buildCostMetal         = 120,
  buildPic               = [[armtick.png]],
  buildTime              = 120,
  canAttack              = true,
  canMove                = true,
  canStop                = true,
  category               = [[LAND TOOFAST]],
  cloakCost              = 0,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[16 16 16]],
  collisionVolumeType	 = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Geländegängige EMP Kriechbombe]],
    description_fr = [[Bombe rampante EMP tout terrain]],
    helptext       = [[The Tick relies on its speed and small size to dodge inaccurate weapons, especially those of assaults and many skirmishers. It can paralyze heavy units or packs of lighter raiders which cannot kill it before it is already in range. Warriors or Glaives can then eliminate the helpless enemies without risk. Counter with defenses or single cheap units to set off a premature detonation. This unit cloaks when otherwise idle.]],
    helptext_de    = [[Geschickt eingesetzt kann Tick sich mehrfach rentieren. Nutze Tick, um gegnerische Verteidigung, schwere Einheiten und gut geschützte Einheiten mit langsamen Waffen zu paralysieren. Andere deiner Einheiten haben so die Möglichkeit die feindlichen Truppen einfach, ohne Risiko zu eleminieren. Konter diese Einheit mit Raketentürmen oder einzelnen, billigen Einheiten. Diese Einheit tarnt sich sobald sie sich nicht mehr bewegt.]],
    helptext_fr    = [[Le Tick, invisible lorqu'il est statique, est rapide et petit ce qui lui permet d'éviter les tirs des armes imprécises. Il peut paralyser des unités lourdes ou des groupes d'unités de raid qui ne peuvent le tuer avant d'être dans l'aire d'effet EMP. Des Warriors ou des Glaives peuvent ensuite éliminer les enemis figés sans risque. Contrez-le avec des défenses ou des unités bon marché pour provoquer une détonation prématurée.]],
    helptext_it    = [[Usato bene, il Tick puo valere dozzine di volte il suo costo. Usalo per paralizzare difese, unitá pesanti, e masse di unitá con armi lente. Altre tue unitá posson eliminare i nemici indifesi senza rischi. Contrastali con torri lancia-razzo o singole unitá economiche per provocare una detonazione prematura.]],

    modelradius    = [[7]],
    instantselfd   = [[1]],
    idle_cloak = 1,
  },

  explodeAs              = [[ARMTICK_DEATH]],
  fireState              = 0,
  footprintX             = 1,
  footprintZ             = 1,
  iconType               = [[spiderbomb]],
  kamikaze               = true,
  kamikazeDistance       = 80,
  kamikazeUseLOS         = true,
  maxDamage              = 50,
  maxSlope               = 72,
  maxVelocity            = 4.2,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT1]],
  noChaseCategory        = [[FIXEDWING LAND SINK TURRET SHIP SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[ARMTICK]],
  pushResistant          = 0,
  script                 = [[armtick.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[ARMTICK_DEATH]],
  selfDestructCountdown  = 0,

  sfxtypes               = {

    explosiongenerators = {
      [[custom:digdig]],
    },

  },

  sightDistance          = 240,
  turnRate               = 3000,
  
  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 1,
      footprintZ       = 1,
      object           = [[wreck2x2b.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 1,
      footprintZ       = 1,
      object           = [[debris1x1a.s3o]],
    },

  },
}

--------------------------------------------------------------------------------

local weaponDefs = {
  ARMTICK_DEATH = {
    areaOfEffect       = 352,
    craterBoost        = 0,
    craterMult         = 0,
    edgeEffectiveness  = 0,
    explosionGenerator = "custom:ARMTICK_EXPLOSION",
    impulseBoost       = 0,
    impulseFactor      = 0,
    name               = "EMP Explosion",
    paralyzer          = true,
    paralyzeTime       = 16,
    soundHit           = "weapon/more_lightning",
    damage = {
      default          = 2000,
    },
  },
}
unitDef.weaponDefs = weaponDefs

--------------------------------------------------------------------------------
return lowerkeys({ armtick = unitDef })
