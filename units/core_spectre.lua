unitDef = {
  unitname               = [[core_spectre]],
  name                   = [[Aspis]],
  description            = [[Linkable Shield Walker]],
  acceleration           = 0.25,
  activateWhenBuilt      = true,
  brakeRate              = 0.25,
  buildCostEnergy        = 550,
  buildCostMetal         = 550,
  builder                = false,
  buildPic               = [[core_spectre.png]],
  buildTime              = 550,
  canAttack              = false,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND UNARMED]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[34 39 29]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô gerador de escudo]],
	description_de = [[Koppelbarer Schildroboter]],
    description_fr = [[Marcheur Bouclier]],
    helptext_bp    = [[]],
    helptext_fr    = [[Le Aspis est un g?n?rateur ? bouclier d?flecteur portatif capable de prot?ger vos troupes. Le bouclier n'utilisera votre ?nergie que si il est pris pour cible par des tirs ennemis, la zone du bouclier est r?duite et le Aspis n'est pas solide. Malgr? ses d?faut il reste indispensable pour prot?ger vos unit?s les plus fragiles, comme l'artillerie.]],
	helptext_de    = [[Der Aspis bietet den umliegenden, alliierten Einheiten durch seinen energetischen Schild Schutz vor Angriffen. Doch sobald Feinde in den Schild kommen oder sich die Energie dem Ende neigt, verfällt dieser Schutz und deine Einheiten stehen dem Gegner vielleicht schutzlos gegenüber. Mehrere Aspis verbinden sich untereinander zu einem großen Schild, was den Vorteil hat, dass Angriffe besser absorbiert werden können.]],
  },

  energyUse              = 1.5,
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkershield]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 212,
  maxDamage              = 700,
  maxSlope               = 36,
  maxVelocity            = 2.05,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[m-8.s3o]],
  onoffable              = true,
  pushResistant          = 1,
  script                 = [[core_spectre.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  side                   = [[Core]],
  sightDistance          = 300,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 30,
  turnRate               = 2100,
  upright                = false,
  workerTime             = 0,

  weapons                = {

    {
      def = [[COR_SHIELD_SMALL]],
    },

  },


  weaponDefs             = {

    COR_SHIELD_SMALL = {
      name                    = [[Energy Shield]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      isShield                = true,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[1 0.1 0.1]],
      shieldGoodColor         = [[0.1 0.1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 3600,
      shieldPowerRegen        = 60,
      shieldPowerRegenEnergy  = 12,
      shieldRadius            = 350,
      shieldRepulser          = false,
      smartShield             = true,
      texture1                = [[shield3mist]],
      visibleShield           = true,
      visibleShieldHitFrames  = 4,
      visibleShieldRepulse    = true,
      weaponType              = [[Shield]],
    },

  },


  featureDefs            = {

    DEAD = {
      description      = [[Wreckage - Aspis]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 700,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 1,
      footprintZ       = 1,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 220,
      object           = [[shield_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 220,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP = {
      description      = [[Debris - Aspis]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 700,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 1,
      footprintZ       = 1,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 110,
      object           = [[debris1x1a.s3o]],
      reclaimable      = true,
      reclaimTime      = 110,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ core_spectre = unitDef })
