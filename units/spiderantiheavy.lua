unitDef = {
  unitname              = [[spiderantiheavy]],
  name                  = [[Infiltrator]],
  description           = [[Cloaked Scout/Anti-Heavy]],
  acceleration          = 0.3,
  activateWhenBuilt     = true,
  brakeRate             = 0.9,
  buildCostMetal        = 280,
  buildPic              = [[spiderantiheavy.png]],
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  category              = [[LAND]],
  cloakCost             = 4,
  cloakCostMoving       = 12,
  corpse                = [[DEAD]],

  customParams          = {
    description_de = [[Spion, Anti-Heavy]],
    description_fr = [[Espion, contre les unités lourdes]],
    helptext       = [[The Infiltrator is useful in two ways. Firstly it is an excellent scout, and very difficult to detect. It can penetrate deep into enemy lines. It also has the capacity to shoot a paralyzing bolt that will freeze any one target, good against heavy enemies and enemy infrastructure.]],
    helptext_de    = [[Der Infiltrator ist für zwei Dinge nützlich. Erstens ist er ein exzellenter Aufklärer und sehr schwer zu entdecken. Er kann sich tief hinter die feindlichen Linien begeben. Außerdem besitzt er die Eigentschaft einen paralysierenden Bolzen abzuschießen, der jedes Ziel einfriert, was gegen schwere Einheiten und feindliche Infrastruktur sehr nützlich ist.]],
    helptext_fr    = [[L'infiltrator est une unité légère invisible. Il peut typiquement être utilisé comme un éclaireur permettant d'espionner la base enemie sans se faire repérer. Il peut aussi libérer une décharge EMP de très haute puissance pour paralyser une cible unique, utile contre les unités lourdes et l'infrastructure. En cas d'échec le temps de recharge très long signifie la perte certaine de cette unité.]],
  },

  explodeAs             = [[BIG_UNITEX]],
  fireState             = 0,
  footprintX            = 2,
  footprintZ            = 2,
  iconType              = [[walkerscout]],
  idleAutoHeal          = 5,
  idleTime              = 1800,
  leaveTracks           = true,
  initCloaked           = true,
  maxDamage             = 270,
  maxSlope              = 36,
  maxVelocity           = 2.55,
  maxWaterDepth         = 22,
  minCloakDistance      = 60,
  movementClass         = [[TKBOT3]],
  moveState             = 0,
  noChaseCategory       = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName            = [[infiltrator.s3o]],
  script                = [[spiderantiheavy.lua]],
  selfDestructAs        = [[BIG_UNITEX]],
  sightDistance         = 550,
  trackOffset           = 0,
  trackStrength         = 8,
  trackStretch          = 1,
  trackType             = [[ChickenTrackPointyShort]],
  trackWidth            = 45,
  turnRate              = 1800,

  weapons               = {

    {
      def                = [[spy]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },

  },

  weaponDefs            = {

    spy = {
      name                    = [[Electro-Stunner]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
		light_color = [[1.85 1.85 0.45]],
		light_radius = 300,
      },

      damage                  = {
        default        = 8000.1,
      },

      duration                = 8,
      explosionGenerator      = [[custom:YELLOW_LIGHTNINGPLOSION]],
      fireStarter             = 0,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      paralyzer               = true,
      paralyzeTime            = 30,
      range                   = 100,
      reloadtime              = 35,
      rgbColor                = [[1 1 0.25]],
      soundStart              = [[weapon/LightningBolt]],
      soundTrigger            = true,
      targetborder            = 1,
      texture1                = [[lightning]],
      thickness               = 10,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 450,
    },

  },

  featureDefs           = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[Infiltrator_wreck.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

}

return lowerkeys({ spiderantiheavy = unitDef })
