unitDef = {
  unitname            = [[tankraid]],
  name                = [[Kodachi]],
  description         = [[Raider Tank]],
  acceleration        = 0.125,
  brakeRate           = 0.1375,
  buildCostMetal      = 160,
  builder             = false,
  buildPic            = [[tankraid.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[42 42 42]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    fireproof      = [[1]],
	specialreloadtime = [[850]],
    aimposoffset      = [[0 5 0]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[tankscout]],
  idleAutoHeal        = 10,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 860,
  maxSlope            = 18,
  maxVelocity         = 4,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[logkoda.s3o]],
  script              = [[tankraid.lua]],
  selfDestructAs      = [[BIG_UNITEX]],
  sightDistance       = 600,
  trackOffset         = 6,
  trackStrength       = 5,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 30,
  turninplace         = 0,
  turnRate            = 880,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[NAPALM_BOMBLET]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER GUNSHIP]],
    },
	
	--{
    --  def                = [[BOGUS_FAKE_NAPALM_BOMBLET]],
    --  badTargetCategory  = [[GUNSHIP]],
    --  onlyTargetCategory = [[]],
    --},

  },


  weaponDefs          = {

    NAPALM_BOMBLET = {
      name                    = [[Flame Bomb]],
      accuracy                = 200,
      areaOfEffect            = 216,
      avoidFeature            = true,
      avoidFriendly           = true,
      burnblow                = true,
      cegTag                  = [[flamer]],
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        	  = {
	    setunitsonfire = "1",
		burnchance     = "1",
		burntime       = 60,

		area_damage = 1,
		area_damage_radius = 108,
		area_damage_dps = 36,
		area_damage_duration = 16,
		
		light_color = [[1.6 0.8 0.32]],
		light_radius = 320,
	  },
	  
      damage                  = {
        default = 70,
        planes  = 70,
        subs    = 3.5,
      },

      explosionGenerator      = [[custom:napalm_koda]],
      fireStarter             = 65,
      flameGfxTime            = 0.1,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      model                   = [[wep_b_fabby.s3o]],
      myGravity               = 0.1,
      noSelfDamage            = true,
      range                   = 175,
      reloadtime              = 4.2,
      soundHit                = [[explosion/ex_med6]],
      soundHitVolume          = 4,
      soundStart              = [[weapon/cannon/cannon_fire3]],
      soundStartVolume        = 3,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 800,
    },
	
	BOGUS_FAKE_NAPALM_BOMBLET = {
      name                    = [[Fake Flame Bomb]],
	  accuracy				  = 1000,
      areaOfEffect            = 64,
	  canattackground         = false,
      craterBoost             = 0,
      craterMult              = 0,
      cegTag                  = [[flamer]],

	  customParams        	  = {
	    setunitsonfire = "1",
		burnchance = 0.8,
		burntime = 600,
	  },
	  
      damage                  = {
        default = 20,
        planes  = 20,
        subs    = 1,
      },

      explosionGenerator      = [[custom:napalm_koda_small]],
      fireStarter             = 65,
      flameGfxTime            = 0.1,
	  flightTime              = 0.1,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 2,
      model                   = [[wep_b_fabby.s3o]],
	  myGravity               = 0.5,
      projectiles             = 1,
      range                   = 0,
      reloadtime              = 6,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med6]],
      soundHitVolume          = 4,
      soundStart              = [[weapon/cannon/cannon_fire3]],
      --soundStartVolume        = 2,
	  soundTrigger			  = false,
      sprayangle              = 300,
      startVelocity           = 10,
      texture2                = [[darksmoketrail]],
	  tracks                  = false,
      trajectoryHeight        = 0.2,
	  turnrate                = 500,
      turret                  = true,
      weaponAcceleration      = 190,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 10,
    },

  },


  featureDefs         = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[logkoda_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ tankraid = unitDef })
