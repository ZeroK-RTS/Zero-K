unitDef = {
  unitname                      = [[cordl]],
  name                          = [[Jellyfish]],
  description                   = [[Depthcharge Launcher]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildAngle                    = 16384,
  buildCostEnergy               = 250,
  buildCostMetal                = 250,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[cordl_aoplane.dds]],
  buildPic                      = [[CORDL.png]],
  buildTime                     = 250,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],
  collisionVolumeTest           = 1,
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Lance-Grenades Sous-Marines]],
    helptext_fr    = [[Le Jellyfish est ?quip? d'un sonar et d'un lanceur de grenade sous marine. C'est la d?fense coti?re la plus efficace contre toute attaque marine ou sous marine. S'attaquant directement ? la partie immerg?e de la coque des ennemis, elle les fait couler en quelques tirs. ]],
  },

  defaultmissiontype            = [[GUARD_NOMOVE]],
  explodeAs                     = [[SMALL_UNITEX]],
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[defense]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = true,
  mass                          = 125,
  maxDamage                     = 1075,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[logjelly.s3o]],
  seismicSignature              = 4,
  selfDestructAs                = [[SMALL_UNITEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:wolvmuzzle1]],
    },

  },

  side                          = [[CORE]],
  sightDistance                 = 638,
  smoothAnim                    = true,
  sonarDistance                 = 580,
  TEDClass                      = [[WATER]],
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooo]],

  weapons                       = {

    {
      def                = [[DEPTHCHARGE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK FLOAT SHIP GUNSHIP]],
    },

  },


  weaponDefs                    = {

    DEPTHCHARGE = {
      name                    = [[DepthCharge]],
      accuracy                = 200,
      areaOfEffect            = 58,
      avoidFriendly           = false,
      bouncerebound           = 0.5,
      bounceslip              = 0.5,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 110,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      groundbounce            = 1,
      guidance                = true,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      model                   = [[depthcharge]],
      noSelfDamage            = true,
      numbounce               = 4,
      propeller               = [[1]],
      range                   = 580,
      reloadtime              = 1,
      renderType              = 1,
      selfprop                = true,
      soundHit                = [[OTAunit/XPLODEP2]],
      soundStart              = [[OTAunit/TORPEDO1]],
      startVelocity           = 150,
      tracks                  = true,
      turnRate                = 22600,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 22,
      weaponTimer             = 6.5,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 350,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Jellyfish]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1075,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[50]],
      hitdensity       = [[100]],
      metal            = 100,
      object           = [[logjelly_corpse.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Jellyfish]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1075,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 100,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Jellyfish]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1075,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 50,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 50,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ cordl = unitDef })
