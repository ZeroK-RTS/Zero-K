unitDef = {
  unitname              = [[armspy]],
  name                  = [[Infiltrator]],
  description           = [[Cloaked Scout/Anti-Heavy]],
  acceleration          = 0.3,
  activateWhenBuilt     = true,
  brakeRate             = 0.9,
  buildCostMetal        = 280,
  buildPic              = [[armspy.png]],
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  category              = [[LAND]],
  cloakCost             = 4,
  cloakCostMoving       = 12,
  corpse                = [[DEAD]],

  customParams          = {
    description_de = [[Spion, Anti-Heavy]],
    description_fr = [[Espion, contre les unit�s lourdes]],
    helptext       = [[The Infiltrator is useful in two ways. Firstly it is an excellent scout, and very difficult to detect. It can penetrate deep into enemy lines. It also has the capacity to shoot a paralyzing bolt that will freeze any one target, good against heavy enemies and enemy infrastructure.]],
    helptext_de    = [[Der Infiltrator ist f�r zwei Dinge n�tzlich. Erstens ist er ein exzellenter Aufkl�rer und sehr schwer zu entdecken. Er kann sich tief hinter die feindlichen Linien begeben. Au�erdem besitzt er die Eigentschaft einen paralysierenden Bolzen abzuschie�en, der jedes Ziel einfriert, was gegen schwere Einheiten und feindliche Infrastruktur sehr n�tzlich ist.]],
    helptext_fr    = [[L'infiltrator est une unit� l�g�re invisible. Il peut typiquement �tre utilis� comme un �claireur permettant d'espionner la base enemie sans se faire rep�rer. Il peut aussi lib�rer une d�charge EMP de tr�s haute puissance pour paralyser une cible unique, utile contre les unit�s lourdes et l'infrastructure. En cas d'�chec le temps de recharge tr�s long signifie la perte certaine de cette unit�.]],
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
  script                = [[armspy.lua]],
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

return lowerkeys({ armspy = unitDef })
