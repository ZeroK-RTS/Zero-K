unitDef = {
  unitname                      = [[corrl]],
  name                          = [[Defender]],
  description                   = [[Light Missile Tower (AA/Skirmish)]],
  acceleration                  = 0,
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildCostEnergy               = 80,
  buildCostMetal                = 80,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[corrl_aoplane.dds]],
  buildPic                      = [[CORRL.png]],
  buildTime                     = 80,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[FLOAT TURRET]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[24 70 24]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    usetacai       = [[1]],
    description_fr = [[Tourelle Lance-Missile Légcre]],
	description_de = [[Leichter Raketenturm (Flugabwehr/Skirmish)]],
    helptext       = [[The Defender is a light multi-purpose missile tower. It is good for sniping units from a distance, providing some degree of anti-air protection, and skirmishing enemy LLTs from outside their range. However, it breaks when you sneeze on it.]],
    helptext_fr    = [[Le Defender est une tourelle légcre mais r plus longue portée que la LLT, il peut de plus attaquer les unité aeriennes avec précision grâce r ses roquettes r tete chercheuse. C'est la meilleure parade contre les bombes rampantes. Son blindage et son temps de rechargement la rendent rapidement obsolcte.]],
	helptext_de    = [[Der Defender ist ein leichter, multifunktionaler Raketenturm. Er eignet sich gut, um Einheiten aus der Distanz zu töten und bietet ein wenig Flugabwehr. Außerdem zerlegt er feindliche LLT aufgrund seiner größeren Reichweite. Dennoch ist er extrem schwach gepanzert und zerbricht durch jedes Niesen.]],
    aimposoffset   = [[0 20 0]],
  },

  defaultmissiontype            = [[GUARD_NOMOVE]],
  explodeAs                     = [[BIG_UNITEX]],
  floater                       = true,
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[defenseskirm]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  mass                          = 94,
  maxDamage                     = 300,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[lmt2.s3o]],
  seismicSignature              = 4,
  selfDestructAs                = [[BIG_UNITEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:PULVMUZZLE]],
      [[custom:PULVBACK]],
    },

  },

  side                          = [[CORE]],
  sightDistance                 = 660,
  smoothAnim                    = true,
  TEDClass                      = [[METAL]],
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oo oo]],

  weapons                       = {

    {
      def                = [[ARMRL_MISSILE]],
      --badTargetCategory  = [[HOVER SWIM LAND SINK FLOAT SHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

    ARMRL_MISSILE = {
      name                    = [[Homing Missiles]],
      areaOfEffect            = 8,
	  avoidFeature            = true,
      cegTag                  = [[missiletrailyellow]],
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 5,

      damage                  = {
        default = 105,
        subs    = 7.5,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      flightTime              = 4,
      guidance                = true,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[hobbes.s3o]],
      noSelfDamage            = true,
      range                   = 610,
      reloadtime              = 1.2,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[explosion/ex_small13]],
      soundStart              = [[weapon/missile/missile_fire11]],
      startsmoke              = [[1]],
      startVelocity           = 500,
      texture2                = [[lightsmoketrail]],
      tolerance               = 10000,
      tracks                  = true,
      turnRate                = 60000,
      turret                  = true,
      weaponAcceleration      = 300,
      weaponTimer             = 5,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 750,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Defender]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 300,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 32,
      object           = [[Pulverizer_d.s3o]],
      reclaimable      = true,
      reclaimTime      = 32,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Defender]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 300,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 32,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 32,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Defender]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 300,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 16,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 16,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corrl = unitDef })
