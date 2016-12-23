unitDef = {
  unitname            = [[cornecro]],
  name                = [[Convict]],
  description         = [[Shielded Construction Bot, Builds at 5 m/s]],
  acceleration        = 0.5,
  activateWhenBuilt   = true,
  brakeRate           = 0.3,
  buildCostEnergy     = 140,
  buildCostMetal      = 140,
  buildDistance       = 128,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[CORNECRO.png]],
  buildTime           = 140,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND UNARMED]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Robot de Construction, Construit ? 5 m/s]],
	description_de = [[Konstruktionsroboter mit Schild, Baut mit 5 M/s]],
    helptext       = [[The Convict is a fairly standard construction bot with a twist: a light shield to defend itself and support allied shieldbots.]],
    helptext_de    = [[Der Convict ist ein ziemlich normaler Konstruktionsroboter mit einem Vorteil: er hat ein Schild um sich zu schutzen.]],
  },

  energyMake          = 0.15,
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[builder]],
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
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[conbot_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

}

return lowerkeys({ cornecro = unitDef })
