unitDef = {
  unitname               = [[core_spectre]],
  name                   = [[Aspis]],
  description            = [[Linkable Shield Walker]],
  acceleration           = 0.25,
  activateWhenBuilt      = true,
  brakeRate              = 0.25,
  buildCostEnergy        = 550,
  buildCostMetal         = 550,
  buildPic               = [[core_spectre.png]],
  buildTime              = 550,
  canAttack              = false,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND UNARMED]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[34 39 29]],
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô gerador de escudo]],
    description_de = [[Koppelbarer Schildroboter]],
    description_fr = [[Marcheur Bouclier]],
    description_pl = [[Bot z tarcza obszarowa]],
    helptext       = [[The Aspis protects surrounding units with its area shield by destroying enemy projectiles and will automatically connect to other shield-equipped units to share charge. The area shield will not stop units and only intercepts projectiles on its perimeter, so enemies can get under the shield and shoot at the units inside. Recharging and maintaining area shields costs energy.]],
    helptext_fr    = [[Le Aspis est un g?n?rateur ? bouclier d?flecteur portatif capable de prot?ger vos troupes. Le bouclier n'utilisera votre ?nergie que si il est pris pour cible par des tirs ennemis, la zone du bouclier est r?duite et le Aspis n'est pas solide. Malgr? ses d?faut il reste indispensable pour prot?ger vos unit?s les plus fragiles, comme l'artillerie.]],
    helptext_de    = [[Der Aspis bietet den umliegenden, alliierten Einheiten durch seinen energetischen Schild Schutz vor Angriffen. Doch sobald Feinde in den Schild kommen oder sich die Energie dem Ende neigt, verfällt dieser Schutz und deine Einheiten stehen dem Gegner vielleicht schutzlos gegenüber. Mehrere Aspis verbinden sich untereinander zu einem großen Schild, was den Vorteil hat, dass Angriffe besser absorbiert werden können.]],
    helptext_pl    = [[Aspis chroni pobliskie jednostki tarcza obszarowa, ktora niszczy wrocie pociski. Aspis automatycznie podlaczy sie do innych jednostek uzbrojonych w tarcze, aby dzielic ladunek. Tarcza obszarowa nie powstrzymuje jednostek, zatem przeciwnik moze strzelac do chronionych jednostek, gdy wejdzie pod nia. Utrzymanie i regeneracja tarczy obszarowej kosztuje energie.]],
    modelradius    = [[17]],
    
    morphto = [[corjamt]],
    morphtime = 30,
  },

  energyUse              = 1.5,
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkershield]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 700,
  maxSlope               = 36,
  maxVelocity            = 2.05,
  maxWaterDepth          = 5000,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  moveState              = 0,
  objectName             = [[m-8.s3o]],
  onoffable              = false,
  pushResistant          = 0,
  script                 = [[core_spectre.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  sightDistance          = 300,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 30,
  turnRate               = 2100,
  upright                = false,

  weapons                = {

    {
      def = [[COR_SHIELD_SMALL]],
    },

  },

  weaponDefs             = {

    COR_SHIELD_SMALL = {
      name                    = [[Energy Shield]],

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[1 0.1 0.1]],
      shieldGoodColor         = [[0.1 0.1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 3600,
      shieldPowerRegen        = 50,
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
      damage           = 700,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 1,
      footprintZ       = 1,
      metal            = 220,
      object           = [[shield_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 220,
    },

    HEAP = {
      description      = [[Debris - Aspis]],
      blocking         = false,
      damage           = 700,
      energy           = 0,
      footprintX       = 1,
      footprintZ       = 1,
      metal            = 110,
      object           = [[debris1x1a.s3o]],
      reclaimable      = true,
      reclaimTime      = 110,
    },

  },

}

return lowerkeys({ core_spectre = unitDef })
