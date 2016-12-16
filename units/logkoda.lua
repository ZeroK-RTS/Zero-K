unitDef = {
  unitname            = [[logkoda]],
  name                = [[Kodachi]],
  description         = [[Raider Tank]],
  acceleration        = 0.125,
  brakeRate           = 0.1375,
  buildCostEnergy     = 180,
  buildCostMetal      = 180,
  builder             = false,
  buildPic            = [[logkoda.png]],
  buildTime           = 180,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_de = [[Raiderpanzer]],
    fireproof      = [[1]],
    helptext       = [[The diminutive Kodachi is a unique raider. Its small yet agile chassis has enough armor and speed to get it close enough to fire its weapon, a napalm bomb. The Kodachi should run in, get a shot off, and withdraw before it takes significant damage. Damaged Kodachis regenerate out of combat.]],
	helptext_de    = [[Der kleine Kodachi ist ein einzigartiger Raider. Seine kleines, aber feines Fahrwerk hat genug Panzerung und Geschwindigkeit, um nahe genug an den Feind zu kommen, damit seine Waffe, eine Napalmstreubombe, abgefeuert werden kann. Er sollte dabei einen Schuß abgeben und sich danach solange wieder zurückziehen, bis der Nachladevorgang abgeschlossen ist.]],
	specialreloadtime = [[850]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[tankscout]],
  idleAutoHeal        = 10,
  idleTime            = 150,
  leaveTracks         = true,
  maxDamage           = 750,
  maxSlope            = 18,
  maxVelocity         = 3.65,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[logkoda.s3o]],
  script              = [[logkoda.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  sightDistance       = 600,
  trackOffset         = 6,
  trackStrength       = 5,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 30,
  turninplace         = 0,
  turnRate            = 750,
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
      accuracy				  = 1000,
      areaOfEffect            = 192,
      avoidFeature            = true,
      avoidFriendly           = true,
      burnblow                = true,
      cegTag                  = [[flamer]],
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        	  = {
	    setunitsonfire = "1",
		burnchance     = "1",

		area_damage = 1,
		area_damage_radius = 96,
		area_damage_dps = 20,
		area_damage_duration = 13.3,
		
		light_color = [[1.6 0.8 0.32]],
		light_radius = 320,
	  },
	  
      damage                  = {
        default = 120,
        planes  = 120,
        subs    = 1,
      },

      explosionGenerator      = [[custom:napalm_koda]],
      fireStarter             = 65,
      flameGfxTime            = 0.1,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      model                   = [[wep_b_fabby.s3o]],
      noSelfDamage            = true,
      range                   = 225,
      reloadtime              = 6,
      soundHit                = [[explosion/ex_med6]],
      soundHitVolume          = 4,
      soundStart              = [[weapon/cannon/cannon_fire3]],
      soundStartVolume        = 3,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 600,
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

return lowerkeys({ logkoda = unitDef })
