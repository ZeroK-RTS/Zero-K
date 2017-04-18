unitDef = {
  unitname                      = [[pw_hq_attacker]],
  name                          = [[Attacker Command]],
  description                   = [[PlanetWars Field HQ (changes influence gain)]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildCostMetal                = 1000,
  builder                       = false,
  buildPic                      = [[pw_hq.png]],
  canSelfDestruct               = false,
  category                      = [[FLOAT UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[PlanetWars Hauptquartier (verandert Einflussgewinn)]],
    helptext       = [[This building is integral to strategic control of the planet. If the Attackers win with a destroyed Command Center they only gain 50% of the influence they would have otherwise gained.]],
    helptext_de    = [[Dieses Gebäude ist für die strategische Kontrolle des Planeten unerlässlich. Wenn das Gewinnerteam seine Kommandozentrale verloren hat, erhält es nur die Hälfte der Einflusspunkte.]],
    dontcount = [[1]],
    soundselect = "building_select1",
  },

  energyUse                     = 0,
  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 8,
  footprintZ                    = 8,
  levelGround                   = false,
  iconType                      = [[pw_assault]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 10000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[pw_hq.s3o]],
  reclaimable                   = false,
  script                        = [[pw_hq.lua]],
  selfDestructAs                = [[ATOMIC_BLAST]],
  selfDestructCountdown         = 60,
  sightDistance                 = 330,
  waterline                     = 10,
  turnRate                      = 0,
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
        subs    = 0.567,
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

}

return lowerkeys({ pw_hq_attacker = unitDef })
