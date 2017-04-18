unitDef = {
  unitname               = [[armsnipe]],
  name                   = [[Spectre]],
  description            = [[Cloaked Skirmish/Anti-Heavy Artillery Bot]],
  acceleration           = 0.3,
  brakeRate              = 0.2,
  buildCostMetal         = 750,
  buildPic               = [[ARMSNIPE.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  cloakCost              = 1,
  cloakCostMoving        = 5,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[30 60 30]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Scharfschützen Walker (Skirmish/Anti-Heavy)]],
    description_fr = [[Marcheur Sniper]],
    helptext       = [[The Spectre's energy rifle inflicts heavy damage to a single target. It can fire while cloaked; however its visible round betrays its position. It requires quite a bit of energy to keep cloaked, especially when moving. The best way to locate a Spectre is by sweeping the area with many cheap units.]],
    helptext_de    = [[Sein energetisches Gewehr richtet riesigen Schaden bei einzelnen Zielen an. Er kann auch schießen, wenn er getarnt ist. Dennoch verrät ihn sein sichtbarer Schuss. Um getarnt zu bleiben und schießen zu können, benötigt der Scharfschütze eine Menge Energie. Die einfachst Möglichkeit einen Scharfschützen ausfindig zu machen, ist die, indem man ein Gebiet mit vielen billigen überschwemmt.]],
    helptext_fr    = [[Le Spectre est une unit? d'artillerie furtive, camouflable et coutant tres cher. Il peut faire feu tout en restant camoufl?. Son tir tres visible peut cependant r?veler sa position. La quantit?e d'?nergie qu'il n?cessite pour tirer et rester camoufler en m?me temps est ?lev?e. Sa destruction ?met une onde de choque EMP qui immobilise les unit?s qui se trouve a proximit?. Il est le plus utile en tant que tireur isol?.]],
	modelradius    = [[15]],
	dontfireatradarcommand = '1',
  },

  decloakOnFire          = false,
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[sniper]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  losEmitHeight          = 40,
  initCloaked            = true,
  maxDamage              = 560,
  maxSlope               = 36,
  maxVelocity            = 1.45,
  maxWaterDepth          = 22,
  minCloakDistance       = 155,
  movementClass          = [[KBOT3]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP SUB]],
  objectName             = [[sharpshooter.s3o]],
  script                 = [[armsnipe.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:WEAPEXP_PUFF]],
      [[custom:MISSILE_EXPLOSION]],
    },

  },

  sightDistance          = 400,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 2600,
  upright                = true,

  weapons                = {

    {
      def                = [[SHOCKRIFLE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    SHOCKRIFLE = {
      name                    = [[Pulsed Particle Projector]],
      areaOfEffect            = 16,
      colormap                = [[0 0 0.4 0   0 0 0.6 0.3   0 0 0.8 0.6   0 0 0.9 0.8   0 0 1 1   0 0 1 1]],
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        	  = {
		light_radius = 0,
	  },
	  
      damage                  = {
        default = 1500.1,
        planes  = 1500.1,
        subs    = 75,
      },

      explosionGenerator      = [[custom:spectre_hit]],
      fireTolerance           = 512, -- 2.8 degrees
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 700,
      reloadtime              = 17,
      rgbColor                = [[1 0.2 0.2]],
      separation              = 1.5,
      size                    = 5,
      sizeDecay               = 0,
      soundHit                = [[weapon/laser/heavy_laser6]],
      soundStart              = [[weapon/gauss_fire]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 850,
    },

  },

  featureDefs            = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[sharpshooter_dead.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

}

return lowerkeys({ armsnipe = unitDef })
