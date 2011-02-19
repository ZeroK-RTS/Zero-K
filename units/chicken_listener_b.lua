unitDef = {
  unitname          = [[chicken_listener_b]],
  name              = [[Listener (burrowed)]],
  description       = [[Burrowing Mobile Seismic Detector]],
  acceleration      = 0.16,
  activateWhenBuilt = false,
  brakeRate         = 0.205,
  buildCostEnergy   = 0,
  buildCostMetal    = 0,
  builder           = false,
  buildPic          = [[chicken_listener.png]],
  buildTime         = 300,
  canGuard          = true,
  canMove           = true,
  canPatrol         = true,
  canstop           = [[1]],
  category          = [[LAND UNARMED]],

  customParams      = {
    helptext = [[YOU'RE NOT SUPPOSE TO BE IN HERE]],
  },

  explodeAs         = [[SMALL_UNITEX]],
  floater           = false,
  footprintX        = 1,
  footprintZ        = 1,
  iconType          = [[chicken]],
  idleAutoHeal      = 20,
  idleTime          = 300,
  mass              = 99999,
  maxDamage         = 700,
  maxSlope          = 72,
  maxVelocity       = 0.3,
  maxWaterDepth     = 15,
  minCloakDistance  = 75,
  movementClass     = [[TKBOT1]],
  noAutoFire        = false,
  noChaseCategory   = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  objectName        = [[chicken_listener_b.s3o]],
  onoffable         = true,
  power             = 300,
  seismicDistance   = 2350,
  seismicSignature  = 4,
  selfDestructAs    = [[SMALL_UNITEX]],

  sfxtypes          = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side              = [[THUNDERBIRDS]],
  sightDistance     = 0,
  smoothAnim        = true,
  stealth           = true,
  TEDClass          = [[KBOT]],
  turnRate          = 806,
  upright           = false,
  waterline         = 8,
  workerTime        = 0,
}

return lowerkeys({ chicken_listener_b = unitDef })
