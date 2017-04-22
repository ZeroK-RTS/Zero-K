unitDef = {
  unitname              = [[corpyro]],
  name                  = [[Pyro]],
  description           = [[Raider/Riot Jumper]],
  acceleration          = 0.4,
  brakeRate             = 1.2,
  buildCostMetal        = 220,
  builder               = false,
  buildPic              = [[CORPYRO.png]],
  canAttack             = true,
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  canstop               = [[1]],
  category              = [[LAND FIREPROOF]],
  corpse                = [[DEAD]],

  customParams          = {
    canjump            = 1,
    jump_range         = 400,
    jump_speed         = 6,
    jump_reload        = 10,
    jump_from_midair   = 1,

    description_fr = [[Marcheur Pilleur r Jetpack]],
	description_de = [[Raider Jumpjet Roboter]],
    fireproof      = [[1]],
    helptext       = [[The Pyro is a cheap, fast walker with a flamethrower. The flamethrower deals increased damage to large units and can hit multiple targets at the same time. When killed, the Pyro sets surrounding units on fire. Additionally, Pyros also come with jetpacks, allowing them to jump over obstacles or get the drop on enemies.]],
    helptext_fr    = [[Le Pyro est un marcheur facile r produire et rapide. Son lanceflamme fait des ravage au corps r corps et son jetpack lui permet des attaques par des angles surprenants. Les dommages sont plus ?lev?s sur les cibles de gros calibres comme les b?timents, et il peut tirer sur plusieurs cibles r la fois. Attention cependant r ne pas les grouper, car le Pyro explose fortement et peut entrainer une r?action en chaine.]],
	helptext_de    = [[Der Pyro ist ein günstiger und schneller Roboter, der mit einem Flammenwerfer ausgestattet ist. Dieser fügt großen Zielen erheblichen Schaden zu und kleineren entsprechend weniger. Außerdem können mehrere Ziele gleichzeitig getroffen werden, welche auch im Feuer aufgehen können. Der Pyro explodiert brutalst, sobald er zerstört wird. Zusätzlich besitzt er noch ein Jetpack, welches ihm zum Beispiel das Springen über Hindernisse ermöglicht.]],
	stats_show_death_explosion = 1,
  },

  explodeAs             = [[PYRO_DEATH]],
  footprintX            = 2,
  footprintZ            = 2,
  iconType              = [[jumpjetraider]],
  idleAutoHeal          = 5,
  idleTime              = 1800,
  leaveTracks           = true,
  maxDamage             = 620,
  maxSlope              = 36,
  maxVelocity           = 3,
  maxWaterDepth         = 22,
  minCloakDistance      = 75,
  movementClass         = [[KBOT2]],
  noAutoFire            = false,
  noChaseCategory       = [[FIXEDWING GUNSHIP SUB]],
  objectName            = [[m-5.s3o]],
  script                = [[corpyro.lua]],
  selfDestructAs        = [[PYRO_DEATH]],
  selfDestructCountdown = 5,

  sfxtypes              = {

    explosiongenerators = {
      [[custom:PILOT]],
      [[custom:PILOT2]],
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
    },

  },

  sightDistance         = 420,
  trackOffset           = 0,
  trackStrength         = 8,
  trackStretch          = 1,
  trackType             = [[ComTrack]],
  trackWidth            = 22,
  turnRate              = 1800,
  upright               = true,
  workerTime            = 0,

  weapons               = {

    {
      def                = [[FLAMETHROWER]],
      badTargetCategory  = [[FIREPROOF]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },

  },


  weaponDefs            = {

    FLAMETHROWER = {
      name                    = [[Flamethrower]],
      areaOfEffect            = 64,
      avoidGround             = false,
      avoidFeature            = false,
      avoidFriendly           = false,
      collideFeature          = false,
      collideGround           = false,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,
      cegTag                  = [[flamer]],

      customParams            = {
        flamethrower = [[1]],
        setunitsonfire = "1",
        burntime = [[450]],
          
        light_camera_height = 2800,
        light_color = [[0.6 0.39 0.18]],
        light_radius = 260,
		light_fade_time = 10,
		light_beam_mult_frames = 5,
		light_beam_mult = 5,
      
        combatrange = 280,
      },
    
      damage                  = {
        default = 8.5,
        subs    = 0.01,
      },

      duration				  = 0.01,
      explosionGenerator      = [[custom:SMOKE]],
      fallOffRate             = 1,
      fireStarter             = 100,
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 0.3,
      interceptedByShieldType = 1,
      noExplode               = true,
      noSelfDamage            = true,
      --predictBoost          = 1,
      range                   = 260,
      reloadtime              = 0.16,
      rgbColor                = [[1 1 1]],
      soundStart              = [[weapon/flamethrower]],
      soundTrigger            = true,
      texture1                = [[flame]],
      thickness	              = 0,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 800,
    },

	PYRO_DEATH = {
		name                    = [[Napalm Blast]],
		areaofeffect            = 256,
		craterboost             = 1,
		cratermult              = 3.5,

		customparams        	  = {
			setunitsonfire = "1",
			burnchance     = "1",
			burntime       = 60,

			area_damage = 1,
			area_damage_radius = 128,
			area_damage_dps = 20,
			area_damage_duration = 13.3,
		},

		damage                  = {
			default = 50,
		},

		edgeeffectiveness       = 0.5,
		explosionGenerator      = [[custom:napalm_pyro]],
		impulseboost            = 0,
		impulsefactor           = 0,
		soundhit                = [[explosion/ex_med3]],
	},
  },

  featureDefs           = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[m-5_dead.s3o]],
    },

	
    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ corpyro = unitDef })
