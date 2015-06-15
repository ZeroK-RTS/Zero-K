unitDef = {
  unitname                      = [[armpb]],
  name                          = [[Gauss]],
  description                   = [[Gauss Turret, 20 health/s when closed]],
  buildCostEnergy               = 400,
  buildCostMetal                = 400,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[armpb_aoplane.dds]],
  buildPic                      = [[ARMPB.png]],
  buildTime                     = 400,
  canAttack                     = true,
  canMove                       = false,
  canstop                       = [[1]],
  category                      = [[SINK TURRET]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[28 80 28]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Versteckter Gaussturm]],
    description_pl = [[Dzialo Gaussa]],
    helptext       = [[The Gauss is a compact, resilent turret with a medium-range gauss cannon. When popped down, it recieves a quarter of incoming damage as well as small amount of health regeneration. It can also attack underwater targets.]],
    helptext_de	   = [[Der Gauss ist ein kompakter Turm mit einem Gausswerfer mittleren Bereichs. Wenn er sich in seine Panzerung zurückgezogen hat, ist es viermal schwerer ihn zu zerstören, was ihn effektive gegen gegnerische Artillerie macht. Es kann auch U-Booten schiessen.]],
    helptext_pl	   = [[Dzialo Gaussa to wszechstronna wiezyczka, ktora otrzymuje tylko cwierc obrazen, gdy sama nie prowadzi ostrzalu. Jest w stanie atakowac cele podwodne.]],
    modelradius    = [[15]],
	aimposoffset   = [[0 25 0]],
    armored_regen  = [[20]],
  },

  damageModifier                = 0.25,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defense]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  mass                          = 252,
  maxDamage                     = 3000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[gauss_91.dae]],
  script                 		= [[armpb.lua]],
  seismicSignature              = 16,
  selfDestructAs                = [[SMALL_BUILDINGEX]],
 
  sfxtypes               = {
    explosiongenerators = {
      [[custom:flashmuzzle1]],
    },
  }, 

  sightDistance                 = 660,
  smoothAnim                    = true,
  useBuildingGroundDecal        = true,

  weapons                       = {

    {
      def                = [[GAUSS]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SUB SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

    GAUSS = {
      name                    = [[Light Gauss Cannon]],
      alphaDecay              = 0.12,
      areaOfEffect            = 16,
	  avoidfeature            = false,
      bouncerebound           = 0.15,
      bounceslip              = 1,
      cegTag                  = [[gauss_tag_l]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 200,
        planes  = 200,
      },

      customParams = {
        single_hit = true,
      },
      
      explosionGenerator      = [[custom:gauss_hit_m]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      noExplode               = true,
      noSelfDamage            = true,
      numbounce               = 40,
      range                   = 560,
      reloadtime              = 2,
      rgbColor                = [[0.5 1 1]],
      separation              = 0.5,
      size                    = 0.8,
      sizeDecay               = -0.1,
      soundHit                = [[weapon/gauss_hit]],
      soundHitVolume          = 3,
      soundStart              = [[weapon/gauss_fire]],
      soundStartVolume        = 2.5,
      stages                  = 32,
      turret                  = true,
      waterweapon			  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2200,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Gauss]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 3000,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[15]],
      hitdensity       = [[100]],
      metal            = 160,
      object           = [[gauss_91_dead1.dae]],
      reclaimable      = true,
      reclaimTime      = 160,
    },


    HEAP  = {
      description      = [[Debris - Gauss]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 3000,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 80,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
    },

  },

}

return lowerkeys({ armpb = unitDef })
