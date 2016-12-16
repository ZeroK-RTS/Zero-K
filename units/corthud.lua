unitDef = {
  unitname            = [[corthud]],
  name                = [[Thug]],
  description         = [[Shielded Assault Bot]],
  acceleration        = 0.25,
  activateWhenBuilt   = true,
  brakeRate           = 0.22,
  buildCostEnergy     = 180,
  buildCostMetal      = 180,
  buildPic            = [[CORTHUD.png]],
  buildTime           = 180,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Robot d'Assaut]],
	description_de = [[Sturmroboter mit Schild]],
    helptext       = [[Weak on its own, the Thug makes an excellent screen for Outlaws and Rogues. The linking shield gives Thugs strength in numbers, but can be defeated by AoE weapons or focus fire.]],
    helptext_fr    = [[Le Thug est extraordinairement r?sistant pour sa taille. Si ses canons ? plasma n'ont pas la pr?cision requise pour abattre les cibles rapides, il reste n?anmoins un bouclier parfait pour des unit?s moins solides telles que les Rogues.]],
	helptext_de    = [[Der Thug ist zwar für sich alleine ziemlich schwach, doch bietet er für Rogues und Outlaws eine gute Abschirmung. Der sich verbindende Schild erzeugt mehr Stärke, sobald sich mehrere Thugs zusammenschließen, kann aber durch AoE Waffen oder fokusiertes Feuer geschlagen werden.]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[walkerassault]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 960,
  maxSlope            = 36,
  maxVelocity         = 1.925,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  noChaseCategory     = [[TERRAFORM FIXEDWING SUB]],
  objectName          = [[thud.s3o]],
  onoffable           = false,
  script			  = [[corthud.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:THUDMUZZLE]],
      [[custom:THUDSHELLS]],
      [[custom:THUDDUST]],
    },

  },

  sightDistance       = 420,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  turnRate            = 2000,
  upright             = true,

  weapons             = {

    {
      def                = [[THUD_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def = [[SHIELD]],
    },

  },

  weaponDefs          = {

    SHIELD      = {
      name                    = [[Energy Shield]],

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[1 0.1 0.1]],
      shieldGoodColor         = [[0.1 0.1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 1250,
      shieldPowerRegen        = 16,
      shieldPowerRegenEnergy  = 0,
      shieldRadius            = 80,
      shieldRepulser          = false,
      shieldStartingPower     = 850,
      smartShield             = true,
      texture1                = [[shield3mist]],
      visibleShield           = true,
      visibleShieldHitFrames  = 4,
      visibleShieldRepulse    = true,
      weaponType              = [[Shield]],
    },

    THUD_WEAPON = {
      name                    = [[Light Plasma Cannon]],
      areaOfEffect            = 36,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
		light_camera_height = 1400,
		light_color = [[0.80 0.54 0.23]],
		light_radius = 200,
      },
	  
      damage                  = {
        default = 170,
        planes  = 170,
        subs    = 8,
      },

      explosionGenerator      = [[custom:MARY_SUE]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      range                   = 280,
      reloadtime              = 4,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire5]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 200,
    },

  },

  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[thug_d.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ corthud = unitDef })
