return { statictele = {
  unitname                      = [[statictele]],
  name                          = [[Teleporter]],
  description                   = [[Blank]],
  activateWhenBuilt             = true,
  autoHeal                      = 5,
  buildCostMetal                = 1000,
  builder                       = false,
  canAttack                     = true,
  canSelfDestruct               = false,
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[120 100 120]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    soundselect = "cloaker_select",
    statsname = "pw_warpgate",
    can_target_allies  = 1,
    stockpiletime  = [[1]],
    stockpilecost  = [[1]],
    priority_misc  = 1, -- Medium
  },

  energyUse                     = 0,
  explodeAs                     = [[GRAV_BLAST]],
  footprintX                    = 8,
  footprintZ                    = 8,
  levelGround                   = false,
  iconType                      = [[mahlazer]],
  maxDamage                     = 5000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  noAutoFire                    = false,
  objectName                    = [[pw_warpgate.dae]],
  reclaimable                   = false,
  script                        = [[statictele.lua]],
  selfDestructAs                = [[GRAV_BLAST]],
  selfDestructCountdown         = 20,
  sightDistance                 = 273,
  useBuildingGroundDecal        = false,
  workerTime                    = 0,

  weapons                = {

    {
      def                = [[BOGUS_CLOAK_TARGET]],
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },
    
  },

  weaponDefs             = {

    BOGUS_CLOAK_TARGET        = {
      name                    = [[Bogus Teleport Target]],
      areaOfEffect            = 800,
      avoidFriendly           = false,
      collideFriendly         = false,
      commandfire             = true,

      customParams        = {
        attack_aoe_circle_mode = "cloaker"
      },
      
      damage                  = {
        default = 0,
      },

      edgeEffectiveness       = 1,
      range                   = 72000,
      reloadtime              = 4/30,
      stockpile               = true,
      stockpileTime           = 10^5,
      turnrate                = 1000000000,
      turret                  = true,
      weaponAcceleration      = 20000,
      weaponTimer             = 0.5,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 20000,
    },

  },

  featureDefs                   = {
    DEAD  = {
      blocking         = true,
      resurrectable    = 0,
      featureDead      = [[HEAP]],
      object           = [[pw_warpgate_dead.dae]],
    },

    HEAP  = {
      blocking         = false,
      --footprintX       = 8,
      --footprintZ       = 8,
      object           = [[debris8x8a.s3o]],
    },
  },

} }
