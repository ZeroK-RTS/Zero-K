unitDef = {
  unitname               = [[nebula]],
  name                   = [[Nebula]],
  description            = [[Atmospheric Mothership]],
  acceleration           = 0.04,
  activateWhenBuilt      = true,
  airStrafe              = 0,
  amphibious             = true,
  bankingAllowed         = false,
  brakeRate              = 0.48,
  buildCostEnergy        = 6000,
  buildCostMetal         = 6000,
  builder                = false,
  buildPic               = [[nebula.png]],
  buildTime              = 6000,
  canAttack              = true,
  canFly                 = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collide                = true,
  collisionVolumeOffsets = [[0 00 0]],
  collisionVolumeScales  = [[40 50 220]],
  collisionVolumeType    = [[box]],

  corpse                 = [[DEAD]],
  cruiseAlt              = 300,

  customParams           = {
    cantuseairpads = 1,
   -- description_fr = [[Forteresse Volante]],
    description_de = [[Lufttraeger]], -- "aerial carrier"
    helptext       = [[As maneuverable as a brick and only modestly armed itself, the Nebula is still a fearsome force due to its ability to survive long-range attacks due to its shield, as well as shred lesser foes with its fighter-drone complement.]],
   -- helptext_fr    = [[La Forteresse Volante est l'ADAV le plus solide jamais construit, est ?quip?e de nombreuses tourelles laser, elle est capable de riposter dans toutes les directions et d'encaisser des d?g?ts importants. Id?al pour un appuyer un assaut lourd ou monopiler l'Anti-Air pendant une attaque a?rienne.]],
    helptext_de    = [[Die Nebula ist stark und ungeschickt, aber sie hat ein Schild um sich zu schutzen und kann seine einige Jaegerdrohne herstellen.]],
    modelradius    = [[40]],
  },

  explodeAs              = [[LARGE_BUILDINGEX]],
  floater                = true,
  footprintX             = 5,
  footprintZ             = 5,
  hoverAttack            = true,
  iconType               = [[nebula]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 11000,
  maxVelocity            = 3.3,
  minCloakDistance       = 150,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[nebula.s3o]],
  script                 = [[nebula.lua]],
  seismicSignature       = 0,
  selfDestructAs         = [[LARGE_BUILDINGEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:plasma_hit_96]],
      [[custom:EXP_MEDIUM_BUILDING_SMALL]],
    },

  },
  sightDistance          = 633,
  turnRate               = 100,
  upright                = true,
  workerTime             = 0,
  
  weapons                = {

    {
      def                = [[CANNON]],
      mainDir            = [[0 1 0]],	-- top
      maxAngleDif        = 210,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    {
      def                = [[CANNON]],
      mainDir            = [[0 -1 0]],	-- bottom
      maxAngleDif        = 210,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    {
      def                = [[CANNON]],
      mainDir            = [[-1 0 0]],	-- left
      maxAngleDif        = 210,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    {
      def                = [[CANNON]],
      mainDir            = [[1 0 0]],	-- right
      maxAngleDif        = 210,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def         = [[SHIELD]],
    },
  },


  weaponDefs             = {

    CANNON = {
      name                    = [[Kinetic Driver]],
      alphaDecay              = 0.1,
      areaOfEffect            = 32,
      colormap                = [[1 0.95 0.4 1   1 0.95 0.4 1    0 0 0 0.01    1 0.7 0.2 1]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 40,
        subs    = 2,
      },

      explosionGenerator      = [[custom:plasma_hit_32]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noGap                   = false,
      noSelfDamage            = true,
      range                   = 450,
      reloadtime              = 0.4,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 2,
      size                    = 2.5,
      sizeDecay               = 0,
      soundStart              = [[weapon/cannon/cannon_fire8]],
      soundHit                = [[explosion/ex_small14]],
      sprayAngle              = 360,
      stages                  = 12,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1200,
    },

    SHIELD = {
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


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      collisionVolumeOffsets = [[0 0 0]],
      collisionVolumeScales  = [[40 50 220]],
      collisionVolumeType    = [[box]],	  
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[nebula_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ nebula = unitDef })
