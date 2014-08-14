unitDef = {
  unitname            = [[hoverskirm]],
  name                = [[Trisula]],
  description         = [[Light Assault/Battle Hovercraft]],
  acceleration        = 0.03,
  brakeRate           = 0.043,
  buildCostEnergy     = 180,
  buildCostMetal      = 180,
  builder             = false,
  buildPic            = [[hoverskirm.png]],
  buildTime           = 180,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[50 25 50]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]], 
  corpse              = [[DEAD]],

  customParams        = {
    description_pl = [[Poduszkowiec bojowy]],
    helptext       = [[The Trisula is a fairly fast, sturdy combatant armed with a scatter beam weapon that can erase multiple small targets or slag a single large one.]],
    helptext_pl    = [[Trisula to w miare szybki, wytrzymaly poduszkowiec uzbrojony w rozszczepiany promien, ktory moze zniszczyc kilka mniejszych jednostek lub mocno uszkodzic jedna wieksza.]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[hoverskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 1300,
  maxSlope            = 36,
  maxVelocity         = 2.5,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noChaseCategory     = [[TERRAFORM FIXEDWING SUB]],
  objectName          = [[hoverskirm.s3o]],
  onoffable           = true,
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
      [[custom:flashmuzzle1]],
    },

  },

  sightDistance       = 450,
  turninplace         = 0,
  turnRate            = 500,

  weapons             = {

    {
      def                = [[SCATTER_LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    SCATTER_LASER = {
      name                    = [[Scatter Beam]],
      areaOfEffect            = 32,
      beamDecay               = 0.85,
      beamTime                = 0.01,
      beamttl                 = 45,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 40,
        subs    = 2,
      },

      explosionGenerator      = [[custom:flash1red]],
      fireStarter             = 100,
      --impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 7.5,
      minIntensity            = 1,
      projectiles             = 9,
      range                   = 360,
      reloadtime              = 4,
      rgbColor                = [[1 0 0]],
      soundStart              = [[weapon/laser/mini_laser]],
      sprayangle              = 1640,
      thickness               = 4,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },

  },

  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Trisula]],
      blocking         = false,
      damage           = 1300,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 72,
      object           = [[hoverskirm_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 72,
    },


    HEAP  = {
      description      = [[Debris - Trisula]],
      blocking         = false,
      damage           = 1300,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 36,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 36,
    },

  },

}

return lowerkeys({ hoverskirm = unitDef })
