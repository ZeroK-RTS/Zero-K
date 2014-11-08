unitDef = {
  unitname                      = [[corjamt]],
  name                          = [[Aegis]],
  description                   = [[Area Shield Device]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildAngle                    = 9821,
  buildCostEnergy               = 480,
  buildCostMetal                = 480,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[corjamt_aoplane.dds]],
  buildPic                      = [[CORJAMT.png]],
  buildTime                     = 480,
  canAttack                     = false,
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[30 39 30]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[box]],
  corpse                        = [[DEAD]],
  energyUse                     = 1.5,
  explodeAs                     = [[BIG_UNITEX]],
  floater                       = true,
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[defenseshield]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  mass                          = 219,
  maxDamage                     = 900,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[m-8.s3o]],
  onoffable                     = false,
  script                        = [[corjamt.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[BIG_UNITEX]],
  side                          = [[CORE]],
  sightDistance                 = 200,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooo]],

  customParams        = {
    description_de = [[Leichte Abschirmeinrichtung]],
    description_pl = [[Tarcza obszarowa]],
    helptext       = [[The Aegis protects a modest area with its bubble shield that stops incoming projectiles (but not AoE effects). The shield has a significant energy upkeep and does not block very powerful weapons.]],
    helptext_de    = [[Aegis schützt deine Einheiten in mit seinem Schild vor Angriffen, die durch den Schild absorbiert werden können, aber nur solange die nötige Energieversorgung gewährleistet ist und der Beschuss nicht zu stark wird.]],
    helptext_pl    = [[Aegis tworzy obszarowa tarcze, ktora detonuje pociski na jej obwodzie. Utrzymanie i regeneracja tarczy kosztuja znaczne ilosci energii, a niektore pociski sa zbyt mocne, by je zatrzymac.]],

    morphto = [[core_spectre]],
    morphtime = [[30]],
  },  
  
  weapons                       = {

    {
      def         = [[COR_SHIELD_SMALL]],
      maxAngleDif = 1,
    },

  },


  weaponDefs                    = {

    COR_SHIELD_SMALL = {
      name                    = [[Energy Shield]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[1 0.1 0.1]],
      shieldGoodColor         = [[0.1 0.1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 3600,
      shieldPowerRegen        = 50,
      shieldPowerRegenEnergy  = 9,
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


  featureDefs                   = {

    DEAD = {
      description      = [[Wreckage - Aegis]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 900,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[3]],
      hitdensity       = [[100]],
      metal            = 192,
      object           = [[shield_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 192,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[all]],
    },


    HEAP = {
      description      = [[Debris - Aegis]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 900,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 96,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 96,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corjamt = unitDef })
