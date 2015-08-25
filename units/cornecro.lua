unitDef = {
  unitname            = [[cornecro]],
  name                = [[Convict]],
  description         = [[Construction/Shield Support bot, Builds at 5 m/s]],
  acceleration        = 0.5,
  activateWhenBuilt   = true,
  brakeRate           = 0.3,
  buildCostEnergy     = 140,
  buildCostMetal      = 140,
  buildDistance       = 90,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[CORNECRO.png]],
  buildTime           = 140,
  canAssist           = true,
  canBuild            = true,
  canMove             = true,
  canPatrol           = true,
  canreclamate        = [[1]],
  category            = [[LAND UNARMED]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Robô de construç?o, constrói a 5 m/s]],
    description_es = [[Robot de Construccion, Construye a 5 m/s]],
    description_fr = [[Robot de Construction, Construit ? 5 m/s]],
    description_it = [[Robot da Costruzzione, Costruisce a 5 m/s]],
	description_de = [[Konstruktionsroboter mit Schild, Baut mit 5 M/s]],
	description_pl = [[Bot konstrukcyjny z tarcza, moc 5 m/s]],
    helptext       = [[The Convict is a fairly standard construction bot with a twist: a light shield to defend itself and support allied shieldbots.]],
    helptext_de    = [[Der Convict ist ein ziemlich normaler Konstruktionsroboter mit einem Vorteil: er hat ein Schild um sich zu schutzen.]],
    helptext_pl    = [[Convict to bot konstrukcyjny wyposazony w ochronna tarcze.]],
  },

  energyMake          = 0.15,
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[walkerbuilder]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 650,
  maxSlope            = 36,
  maxVelocity         = 2,
  maxWaterDepth       = 22,
  metalMake           = 0.15,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  objectName          = [[conbot.s3o]],
  onoffable           = false,
  script			  = [[cornecro.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  showNanoSpray       = false,
  sightDistance       = 375,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  terraformSpeed      = 300,
  turnRate            = 2200,
  upright             = true,
  workerTime          = 5,

  weapons             = {

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
      shieldPower             = 900,
      shieldPowerRegen        = 9,
      shieldPowerRegenEnergy  = 0,
      shieldRadius            = 80,
      shieldRepulser          = false,
      shieldStartingPower     = 600,
      smartShield             = true,
      texture1                = [[shield3mist]],
      visibleShield           = true,
      visibleShieldHitFrames  = 4,
      visibleShieldRepulse    = true,
      weaponType              = [[Shield]],
    },

  },

  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Convict]],
      blocking         = true,
      damage           = 650,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 56,
      object           = [[conbot_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 56,
    },

    HEAP  = {
      description      = [[Debris - Convict]],
      blocking         = false,
      damage           = 650,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 28,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 28,
    },

  },

}

return lowerkeys({ cornecro = unitDef })
