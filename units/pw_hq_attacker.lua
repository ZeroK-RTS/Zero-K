return { pw_hq_attacker = {
  unitname                      = [[pw_hq_attacker]],
  name                          = [[Attacker Command]],
  description                   = [[PlanetWars Field HQ (changes influence gain)]],
  activateWhenBuilt             = true,
  buildCostMetal                = 1000,
  builder                       = false,
  buildPic                      = [[pw_hq.png]],
  canSelfDestruct               = false,
  category                      = [[FLOAT UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    dontcount = [[1]],
    soundselect = "building_select1",
    planetwars_structure = [[1]],
  },

  energyUse                     = 0,
  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 8,
  footprintZ                    = 8,
  levelGround                   = false,
  iconType                      = [[pw_assault]],
  maxDamage                     = 10000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  noAutoFire                    = false,
  objectName                    = [[pw_hq.s3o]],
  reclaimable                   = false,
  script                        = [[pw_hq.lua]],
  selfDestructAs                = [[ATOMIC_BLAST]],
  selfDestructCountdown         = 60,
  sightDistance                 = 330,
  waterline                     = 10,
  useBuildingGroundDecal        = false,
  workerTime                    = 0,
  --yardMap                       = [[oooooooooooooooooooo]],

  weapons                = {

    {
      def                = "BOGUS_FAKE_TARGETER",
      badTargetCategory  = "FIXEDWING",
      onlyTargetCategory = "FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER",
    },

  },
  
  weaponDefs             = {
    BOGUS_FAKE_TARGETER = {
      name                    = [[Bogus Fake Targeter]],
      avoidGround             = false, -- avoid nothing, else attempts to move out to clear line of fine
      avoidFriendly           = false,
      avoidFeature            = false,
      avoidNeutral            = false,

      damage                  = {
        default = 11.34,
        planes  = 11.34,
      },

      explosionGenerator      = [[custom:FLASHPLOSION]],
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 1,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 500,
    },
  },
  
  featureDefs                   = {
    DEAD  = {
      blocking         = true,
      resurrectable    = 0,
      featureDead      = [[HEAP]],
      footprintX       = 8,
      footprintZ       = 8,
      object           = [[pw_hq_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4b.s3o]],
    },
  },

} }
