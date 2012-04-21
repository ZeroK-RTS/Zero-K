unitDef = {
  unitname                      = [[raveparty]],
  name                          = [[Disco Rave Party]],
  description                   = [[Rainbow Surprise Superweapon]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostEnergy               = 35000,
  buildCostMetal                = 35000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[armbrtha_aoplane.dds]],
  buildPic                      = [[raveparty.png]],
  buildTime                     = 35000,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[70 194 70]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[cylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    helptext       = [[The Disco Rave Party throws six different party shots at your enemy for a different surprise each time. Fun for the whole family!]],
    helptext_de    = [[Der Disco Rave Party verschießt sechs verschiedene Partygeschosse auf deinen Feind, wobei jedes Geschoss eine Überraschung darstellt. Ein Spaß für die ganze Familie!]],
    description_de = [[Regenbogen-Überraschungs Superwaffe]],


  },

  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 7,
  footprintZ                    = 7,
  iconType                      = [[mahlazer]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  mass                          = 791,
  maxDamage                     = 16000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[raveparty.s3o]],
  --onoffable						= true,
  script						= [[raveparty.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[ATOMIC_BLAST]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:ARMBRTHA_SHOCKWAVE]],
      [[custom:ARMBRTHA_SMOKE]],
      [[custom:ARMBRTHA_FLARE]],
    },

  },

  side                          = [[ARM]],
  sightDistance                 = 660,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooooooooooooooo]],

  weapons                       = {

    {
      def                = [[RED_KILLER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },
    {
      def                = [[ORANGE_ROASTER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },
    {
      def                = [[YELLOW_SLAMMER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },
	{
      def                = [[GREEN_STAMPER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },	
	{
      def                = [[BLUE_SHOCKER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },	
	{
      def                = [[VIOLET_SLUGGER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },		
  },


  weaponDefs                    = {

    RED_KILLER = {
      name                    = [[Red Killer]],
      accuracy                = 750,
      avoidFeature            = false,
      areaOfEffect            = 192,
      craterBoost             = 4,
      craterMult              = 3,

      damage                  = {
        default = 3000,
        planes  = 3000,
        subs    = 300,
      },

      explosionGenerator      = [[custom:NUKE_150]],
      impulseBoost            = 0.5,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      range                   = 6200,
	  rgbColor                = [[1 0.1 0.1]],
      reloadtime              = 1,
	  size					  = 15,
	  sizeDecay				  = 0.03,
      soundHit                = [[explosion/mini_nuke]],
      soundStart              = [[weapon/cannon/big_begrtha_gun_fire]],
	  stages				  = 30,
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },
	
    ORANGE_ROASTER = {
      name                    = [[Orange Roaster]],
      accuracy                = 750,
      areaOfEffect            = 512,
      avoidFeature            = false,
      craterBoost             = 0.25,
      craterMult              = 0.5,
	  
	  customParams        	  = {
	    setunitsonfire = "1",
		burntime = 240,
	  },

      damage                  = {
        default = 300,
        planes  = 300,
        subs    = 15,
      },

      explosionGenerator      = [[custom:napalm_drp]],
      impulseBoost            = 0.2,
      impulseFactor           = 0.1,
      interceptedByShieldType = 1,
      range                   = 6200,
	  rgbColor                = [[0.9 0.3 0]],
      reloadtime              = 1,
	  size					  = 15,
	  sizeDecay				  = 0.03,
      soundHit                = [[weapon/missile/nalpalm_missile_hit]],
      soundStart              = [[weapon/cannon/big_begrtha_gun_fire]],
	  stages				  = 30,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },
	
    YELLOW_SLAMMER = {
      name                    = [[Yellow Slammer]],
      accuracy                = 750,
      areaOfEffect            = 384,
      avoidFeature            = false,
      craterBoost             = 0.5,
      craterMult              = 1,

      damage                  = {
        default = 0.1,
        planes  = 0.1,
        subs    = 0.1,
      },

      explosionGenerator      = [[custom:330rlexplode]],
      impulseBoost            = 20,
      impulseFactor           = 150,
      interceptedByShieldType = 1,
      range                   = 6200,
	  rgbColor                = [[0.7 0.7 0]],
      reloadtime              = 1,
	  size					  = 15,
	  sizeDecay				  = 0.03,
      soundHit                = [[weapon/cannon/earthshaker]],
      soundStart              = [[weapon/cannon/big_begrtha_gun_fire]],
	  stages				  = 30,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },	

    GREEN_STAMPER = {
      name                    = [[Green Stamper]],
      accuracy                = 750,
      areaOfEffect            = 300,
      avoidFeature            = false,
      craterBoost             = 32,
      craterMult              = 1,

	  customParams            = {
	    gatherradius = [[225]],
	    smoothradius = [[150]],
		smoothmult   = [[0.7]],
	  },
	  
      damage                  = {
        default = 400,
        planes  = 400,
        subs    = 20,
      },

      explosionGenerator      = [[custom:blobber_goo]],
      impulseBoost            = 0.7,
      impulseFactor           = 0.5,
      interceptedByShieldType = 1,
      range                   = 6200,
	  rgbColor                = [[0.1 1 0.1]],
      reloadtime              = 1,
	  size					  = 15,
	  sizeDecay				  = 0.03,
      soundHit                = [[explosion/ex_large4]],
      soundStart              = [[weapon/cannon/big_begrtha_gun_fire]],
	  stages				  = 30,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },	

    BLUE_SHOCKER = {
      name                    = [[Blue Shocker]],
      accuracy                = 750,
      areaOfEffect            = 320,
      avoidFeature            = false,
      craterBoost             = 0.25,
      craterMult              = 0.5,

      damage                  = {
        default        = 7000,
        empresistant75 = 1750,
        empresistant99 = 70,
      },

	  edgeEffectiveness       = 0.75,
      explosionGenerator      = [[custom:POWERPLANT_EXPLOSION]],
      holdtime                = [[1]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      paralyzer               = true,
      paralyzeTime            = 10,
      range                   = 6200,
	  rgbColor                = [[0.1 0.1 1]],
      reloadtime              = 1,
	  size					  = 15,
	  sizeDecay				  = 0.03,
      soundHit                = [[weapon/more_lightning]],
      soundStart              = [[weapon/cannon/big_begrtha_gun_fire]],
	  stages				  = 30,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },

    VIOLET_SLUGGER = {
      name                    = [[Violet Slugger]],
      accuracy                = 750,
      areaOfEffect            = 720,
      avoidFeature            = false,
      craterBoost             = 0.25,
      craterMult              = 0.5,

      damage                  = {
        default = 450,
        planes  = 450,
        subs    = 22.5,
      },

      explosionGenerator      = [[custom:riotballplus2_purple]],
      holdtime                = [[1]],
      impulseBoost            = 0.2,
      impulseFactor           = 0.1,
      interceptedByShieldType = 1,
      range                   = 6200,
	  rgbColor                = [[0.7 0 0.7]],
      reloadtime              = 1,
	  size					  = 15,
	  sizeDecay				  = 0.03,
      soundHit                = [[weapon/aoe_aura]],
      soundStart              = [[weapon/cannon/big_begrtha_gun_fire]],
	  stages				  = 30,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },	
	
  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Disco Rave Party]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 16000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 14000,
      object           = [[raveparty_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 14000,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP  = {
      description      = [[Debris - Disco Rave Party]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 16000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 7000,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 7000,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ raveparty = unitDef })
