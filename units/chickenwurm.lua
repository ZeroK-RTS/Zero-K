unitDef = {
  unitname            = [[chickenwurm]],
  name                = [[Wurm]],
  description         = [[Burrowing Flamer (Assault/Riot)]],
  acceleration        = 0.36,
  activateWhenBuilt   = true,
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickenwurm.png]],
  buildTime           = 350,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],

  customParams        = {
	fireproof	   = 1,
  },

  explodeAs           = [[jumpraid_PYRO_DEATH]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[spidergeneric]],
  idleAutoHeal        = 10,
  idleTime            = 600,
  leaveTracks         = true,
  maxDamage           = 1500,
  maxSlope            = 90,
  maxVelocity         = 1.8,
  maxWaterDepth       = 5000,
  minCloakDistance    = 75,
  movementClass       = [[ATKBOT3]],
  noAutoFire          = false,
  noChaseCategory     = [[SHIP FLOAT SWIM TERRAFORM FIXEDWING GUNSHIP SATELLITE STUPIDTARGET MINE]],
  objectName          = [[chickenwurm.s3o]],
  power               = 350,
  script              = [[chickenwurm.lua]],
  selfDestructAs      = [[jumpraid_PYRO_DEATH]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance       = 384,
  sonarDistance       = 384,
  stealth             = true,
  turnRate            = 806,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[NAPALM]],
      badTargetCategory  = [[GUNSHIP]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT GUNSHIP SHIP HOVER]],
    },
    {
      def                = [[UWGOO]], -- Fired when underwater.
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SUB GUNSHIP SHIP HOVER]],
    },
    {
      def                = [[UWGOO]], -- Above water, fired at submerged units.
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SINK SUB]],
    },

  },


  weaponDefs          = {

    NAPALM = {
      name                    = [[Napalm Blob]],
      areaOfEffect            = 128,
      burst                   = 1,
      burstrate               = 0.01,
      craterBoost             = 0,
      craterMult              = 0,
	  
	  customParams        	  = {
	    setunitsonfire = "1",
		burntime = 180,

		area_damage = 1,
		area_damage_radius = 128,
		area_damage_dps = 30,
		area_damage_duration = 20,
	  },

      damage                  = {
        default = 50,
        planes  = 50,
        subs    = 2.5,
      },

      explosionGenerator      = [[custom:napalm_firewalker]],
      fireStarter             = 120,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      range                   = 300,
      reloadtime              = 6,
      rgbColor                = [[0.8 0.3 0]],
      size                    = 4.5,
      sizeDecay               = 0,
      soundHit                = [[chickens/acid_hit]],
      soundStart              = [[chickens/acid_fire]],
      sprayAngle              = 1024,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 200,
    },

    UWGOO = {
      name                    = [[Blob]],
      areaOfEffect            = 128,
      craterBoost             = 0,
      craterMult              = 0,
	  
	  customParams        	  = {
	  },

      damage                  = {
        default = 250,
      },

      explosionGenerator      = [[custom:large_green_goo]],
      fireStarter             = 120,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      range                   = 300,
      reloadtime              = 6,
      rgbColor                = [[0.2 0.6 0]],
      size                    = 8,
      sizeDecay               = 0,
      soundHit                = [[chickens/acid_hit]],
      soundStart              = [[chickens/acid_fire]],
      tolerance               = 9000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 600,
      waterWeapon	      = true,
    },
  },

}

return lowerkeys({ chickenwurm = unitDef })
