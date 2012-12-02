unitDef = {
  unitname                      = [[dota_corllt_upd]],
  name                          = [[Lotus]],
  description                   = [[Light Laser Tower]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostEnergy               = 500,
  buildCostMetal                = 500,
  activateWhenBuilt   = true,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[corllt_aoplane.dds]],
  buildPic                      = [[CORLLT.png]],
  buildTime                     = 90,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[FLOAT TURRET]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[30 90 30]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],
	script=[[corllt.cob]],
	
  customParams                  = {
    description_fr = [[Tourelle Laser Légcre]],
	description_de = [[Leichter Laserturm]],
    helptext       = [[The Lotus is a basic turret. A versatile, solid anti-ground weapon, it does well versus scouts as well as being able to take on one or two raiders. Falls relatively easily to skirmishers, artillery or assault units unless supported.]],
    helptext_fr    = [[La Tourelle Laser Légcre aussi appellée LLT est une tourelle basique, peu solide mais utile pour se protéger des éclaireurs ou des pilleurs. Des tirailleurs ou de l'artillerie en viendrons rapidement r bout. ]],
	helptext_de    = [[Der Lotus ist einer der Basisgeschütztürme. Eine wendige, massive Anti-Boden Waffe ermöglicht ihm die Verteidigung gegen Aufklärer oder auch ein, oder zwei Raidern. Von Skirmishern, Artillerie oder Sturmeinheiten kann er allerdings ohne Schutz sehr schnell überwältigt werden.]],
    aimposoffset   = [[0 32 0]],
  },

  explodeAs                     = [[SMALL_BUILDINGEX]],
  footprintX                    = 2,
  footprintZ                    = 2,
  healtime                      = [[4]],
  iconType                      = [[defenseraider]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  mass                          = 128,
  maxDamage                     = 3000,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[llt.s3o]],
  seismicSignature              = 4,
  selfDestructAs                = [[SMALL_BUILDINGEX]],
	onoffable                     = false,
	noAutoFire          = false,

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_BLUE]],
    },

  },

  side                          = [[CORE]],
  sightDistance                 = 600,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  waterline                     = 5,
  workerTime                    = 0,
  yardMap                       = [[oooo]],

  weapons                       = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    {
      def = [[LLT_SHIELD]],
    },
  },


  weaponDefs                    = {
	LLT_SHIELD = {
      name                    = [[LLT Energy Shield]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      isShield                = true,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[1 0.1 0.1]],
      shieldGoodColor         = [[0.1 0.1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 2000,
      shieldPowerRegen        = 22,
      shieldPowerRegenEnergy  = 0,
      shieldRadius            = 300,
      shieldRepulser          = false,
      shieldStartingPower     = 1000,
      smartShield             = true,
      texture1                = [[shield3mist]],
      visibleShield           = true,
      visibleShieldHitFrames  = 4,
      visibleShieldRepulse    = true,
      weaponType              = [[Shield]],
    },


    LASER = {
      name                    = [[Laserbeam]],
      areaOfEffect            = 8,
      beamTime                = 0.1,
      coreThickness           = 0.4,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 35.0,
        subs    = 0.5,
      },

      explosionGenerator      = [[custom:FLASH1blue]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 2,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 0.1,
      rgbColor                = [[0 1 1]],
      soundStart              = [[weapon/laser/laser_burn8]],
      soundTrigger            = true,
      sweepfire               = false,
      targetMoveError         = 0.1,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 2,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Lotus]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 785,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 36,
      object           = [[lotus_d.s3o]],
      reclaimable      = true,
      reclaimTime      = 36,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Lotus]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 785,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 18,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 18,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ dota_corllt_upd = unitDef })
