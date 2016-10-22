unitDef = {
  unitname               = [[amphtele]],
  name                   = [[Djinn]],
  description            = [[Amphibious Teleport Bridge]],
  acceleration           = 0.25,
  brakeRate              = 0.25,
  buildCostEnergy        = 750,
  buildCostMetal         = 750,
  buildPic               = [[amphtele.png]],
  buildTime              = 750,
  canAttack              = false,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND UNARMED]],
  --collisionVolumeOffsets = [[0 1 0]],
  --collisionVolumeScales  = [[36 49 35]],
  --collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen = 30,
    amph_submerged_at = 40,

	teleporter = 1,
	teleporter_throughput = 7.5, -- mass per second
	teleporter_beacon_spawn_time = 9,

    description_pl = [[Amfibijny teleporter]],
    helptext       = [[Djinn excels at moving large land based armies across bodies of water. When deployed it teleports units from around its pre-placed static beacon to its present location. The teleportation is one-way, so ensure the destination is safe.]],
    helptext_pl    = [[Djinn sluzy do przenoszenia duzych armii ladowych przez wieksze akweny. Moze on ustawic wezel przesylowy w dowolnym miejscu na mapie; jednostki moga uzywac tego wezla do jednokierunkowej teleportacji w kierunku Djinna pod warunkiem, ze Djinn stoi nieruchomo.]],
  },

  explodeAs              = [[BIG_UNIT]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[amphtransport]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 2500,
  maxSlope               = 36,
  maxVelocity            = 2.5,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT3]],
  objectName             = [[amphteleport.s3o]],
  script                 = [[amphtele.lua]],
  pushResistant          = 0,
  seismicSignature       = 16,
  selfDestructAs         = [[BIG_UNIT]],
  sightDistance          = 300,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 24,
  turnRate               = 700,

  featureDefs            = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[amphteleport_dead.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

}

return lowerkeys({ amphtele = unitDef })
