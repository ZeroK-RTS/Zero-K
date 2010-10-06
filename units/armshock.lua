unitDef = {
  unitname            = [[armshock]],
  name                = [[Vanguard]],
  description         = [[All-Terrain Thermonuclear Artillery]],
  acceleration        = 0.023,
  bmcode              = [[1]],
  brakeRate           = 0.1,
  buildCostEnergy     = 4000,
  buildCostMetal      = 4000,
  builder             = false,
  buildPic            = [[ARMSHOCK.png]],
  buildTime           = 4000,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Artillerie Thermonucl?aire Tout-Terrain]],
    helptext       = [[It may look like a turtle, but don't laugh - the Vanguard is one extremely nasty piece of kit. It fires long-range thermonuclear shells at either high or low trajectory, with the expected result on anything that gets hit. Its all-terrain ability allows it to scale mountains for a better shot. Be warned - it is very expensive and fragile, so keep it well protected, making use of its range to stay out of the line of fire.]],
    helptext_fr    = [[Si son look de tortue peut faire sourrire, les d?g?ts de son canon peuvent faire pleurer. Le Vanguard peut gr?ce ? son syst?me quadrup?de, escalader nimporte quelle surface d'o? il tirera ? l'aide de son canon plasma lourd ultra longue port?e. Ses tirs plasmas sont concentr?s en ?nergie volatile nucl?aire, produisant des minis explosions nucl?aires ? l'impact. C'est la terreur des fortifications ennemies, mais son blindage est le moins bon des Mechs.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNIT]],
  footprintX          = 3,
  footprintZ          = 3,
  highTrajectory      = 2,
  iconType            = [[t3arty]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  immunetoparalyzer   = [[1]],
  maneuverleashlength = [[640]],
  mass                = 2150,
  maxDamage           = 4500,
  maxSlope            = 72,
  maxVelocity         = 1,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TKBOT3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName          = [[ARMSHOCK]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNIT]],
  side                = [[ARM]],
  sightDistance       = 660,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[TANK]],
  turnRate            = 231,

  weapons             = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    PLASMA = {
      name                    = [[Thermonuclear Shells]],
      accuracy                = 256,
      areaOfEffect            = 160,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 2500,
        planes  = 2500,
        subs    = 125,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:NUKE_150_green]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      minbarrelangle          = [[-35]],
      noSelfDamage            = true,
      range                   = 1425,
      reloadtime              = 15,
      renderType              = 4,
      rgbColor                = [[1 0 0.25]],
      soundHit                = [[OTAunit/XPLOMED2]],
      soundStart              = [[OTAunit/CANNHVY5]],
      startsmoke              = [[1]],
      targetMoveError         = 0.5,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 495,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Vanguard]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 4500,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 1600,
      object           = [[ARMSHOCK_DEAD]],
      reclaimable      = true,
      reclaimTime      = 1720,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Vanguard]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 4500,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 1600,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 1600,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Vanguard]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 4500,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 800,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 800,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armshock = unitDef })
