unitDef = {
  unitname                      = [[armbrtha]],
  name                          = [[Big Bertha]],
  description                   = [[Strategic Plasma Cannon]],
  buildCostEnergy               = 5000,
  buildCostMetal                = 5000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[armbrtha_aoplane.dds]],
  buildPic                      = [[ARMBRTHA.png]],
  buildTime                     = 5000,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[70 194 70]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[cylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Strategische Plasma Kanone]],
    description_fr = [[Canon ? Plasma Strat?gique]],
    description_pl = [[Strategiczne Dzialo Plazmowe]],
    helptext       = [[The Bertha is a massive cannon that fires high-energy plasmoids across the map. Used appropriately, it can effectively suppress enemy operations from the safety of your base. Do not expect it to win battles alone for you, however.]],
    helptext_de    = [[Die Bertha ist eine massive Kanone, welche hochenergetische Plasmoide über die Karte verschiesst. Angemessener Gebrauch der Waffe kann gengerische Operationen von der eigenen, sicheren Basis aus schnell unterdrücken. Trotzdem erwarte nicht, dass du nur dich diese Waffe die Schlachten gewinnen wirst.]],
    helptext_fr    = [[Le Big Bertha est un canon ? plasma lourd, tr?s lourd. Un seul impact de son tir peut r?duire ? n?ant plusieurs unit?s ou structures. Sa port?e de tir op?rationnelle est immense et n'?gale que son co?t de construction et d'usage. En effet chaque tir consomme 300 unit?s d'?nergie. Notez que le Big Bertha effectue des tirs tendus. Autrement dit, pensez ? le placer en hauteur, ou le moindre relief servira de refuge ? l'ennemi.]],
    helptext_pl    = [[Gruba Berta to masywne dzialo o ogromnym zasiegu. W dobrych rekach jest w stanie niweczyc wazne przedsiewziecia przeciwnika z bezpiecznego miejsca we wlasnej bazie. Nie jest jednak w stanie zastapic mobilnych jednostek i nie zapewni ci sama zwyciestwa.]],

    modelradius    = [[35]],
  },

  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 4,
  footprintZ                    = 4,
  iconType                      = [[lrpc]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  maxDamage                     = 4800,
  maxSlope                      = 18,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noChaseCategory               = [[FIXEDWING LAND SHIP SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[armbrtha.s3o]],
  script                        = [[armbrtha.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[ATOMIC_BLAST]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:ARMBRTHA_SHOCKWAVE]],
      [[custom:ARMBRTHA_SMOKE]],
      [[custom:ARMBRTHA_FLARE]],
    },

  },

  sightDistance                 = 660,
  useBuildingGroundDecal        = true,
  yardMap                       = [[oooo oooo oooo oooo]],

  weapons                       = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[GUNSHIP LAND SHIP HOVER SWIM]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

  },

  weaponDefs                    = {

    PLASMA = {
      name                    = [[Very Heavy Plasma Cannon]],
      accuracy                = 500,
      areaOfEffect            = 192,
      avoidFeature            = false,
      avoidGround             = false,
      cegTag                  = [[vulcanfx]],
      craterBoost             = 0.25,
      craterMult              = 0.5,

      customParams            = {
        gatherradius = [[128]],
        smoothradius = [[96]],
        smoothmult   = [[0.4]],
      },
	  
      damage                  = {
        default = 2003.1,
        subs    = 100,
      },

      explosionGenerator      = [[custom:lrpc_expl]],
      impulseBoost            = 0.5,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 6200,
      reloadtime              = 7,
      soundHit                = [[weapon/cannon/lrpc_hit]],
      soundStart              = [[weapon/cannon/big_begrtha_gun_fire]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },

  },

  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Big Bertha]],
      blocking         = true,
      damage           = 4800,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      metal            = 2000,
      object           = [[armbrtha_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 2000,
    },


    HEAP  = {
      description      = [[Debris - Big Bertha]],
      blocking         = false,
      damage           = 4800,
      energy           = 0,
      footprintX       = 4,
      footprintZ       = 4,
      metal            = 1000,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 1000,
    },

  },

}

return lowerkeys({ armbrtha = unitDef })
