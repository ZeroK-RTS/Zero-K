unitDef = {
  unitname               = [[wolverine_mine]],
  name                   = [[Claw]],
  description            = [[Wolverine Mine]],
  acceleration           = 0,
  activateWhenBuilt      = false,
  brakeRate              = 0,
  buildCostEnergy        = 5,
  buildCostMetal         = 5,
  builder                = false,
  buildPic               = [[wolverine_mine.png]],
  buildTime              = 5,
  canAttack              = true,
  canGuard               = false,
  canMove                = false,
  canPatrol              = false,
  canstop                = [[0]],
  category               = [[FLOAT MINE]],
  cloakCost              = 0,
  collisionVolumeOffsets = [[0 -4 0]],
  collisionVolumeScales  = [[20 20 20]],
  collisionVolumeType    = [[ellipsoid]],

  customParams           = {
    helptext       = [[This mine doesn't explode - instead, it releases a flurry of bomblets at trespassing enemies. It deactivates after one minute.]],
    description_de = [[Mine]],
    helptext_de    = [[Statt explodieren, diese Mine schiesst Projektile an Eindringlingen.]],
    dontcount = [[1]],
	mobilebuilding = [[1]],
	idle_cloak = 1,
  },

  explodeAs              = [[NOWEAPON]],
  footprintX             = 1,
  footprintZ             = 1,
  levelGround            = false,
  iconType               = [[mine]],
  idleAutoHeal           = 10,
  idleTime               = 300,
  initCloaked            = true,
  kamikaze               = true,
  kamikazeDistance       = 0,
  kamikazeUseLOS         = true,
  maxDamage              = 40,
  maxSlope               = 255,
  maxVelocity            = 0,
  minCloakDistance       = 50,
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[claw.s3o]],
  onoffable              = false,
  reclaimable            = false,
  script                 = [[wolverine_mine.lua]],
  seismicSignature       = 16,
  selfDestructAs         = [[NOWEAPON]],
  selfDestructCountdown  = 0,
  sightDistance          = 64,
  stealth                = true,
  turnRate               = 0,
  waterline              = 1,
  workerTime             = 0,
  yardMap                = [[y]],

  weapons                = {

    {
      def                = [[BOMBLET]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER GUNSHIP]],
    },

  },


  weaponDefs             = {

    BOMBLET = {
      name                    = [[Bomblet]],
      areaOfEffect            = 16,
      burst                   = 5,
      burstrate               = 0.01,
      craterBoost             = 0,
      craterMult              = 0,

	  customparams = {
		stats_hide_dps = 1, -- one use
		stats_hide_reload = 1,
	  },
	  
      damage                  = {
        default = 40,
        planes  = 40,
        subs    = 4,
      },

      explosionGenerator      = [[custom:DEFAULT]],
      fireStarter             = 70,
      fixedlauncher           = 1,
      flightTime              = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_b_fabby.s3o]],
      range                   = 115,
      reloadtime              = 20,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 5,
      soundStart              = [[weapon/missile/sabot_fire_short]],
      soundStartVolume        = 9,
      soundTrigger            = 1,
      startVelocity           = 50,
      texture2                = [[darksmoketrail]],
      tracks                  = true,
      turnRate                = 36000,
      turret                  = true,
      weaponAcceleration      = 200,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 300,
    },

  },

}

return lowerkeys({ wolverine_mine = unitDef })
