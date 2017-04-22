unitDef = {
  unitname               = [[shipskirm]],
  name                   = [[Mistral]],
  description            = [[Rocket Boat (Skirmisher)]],
  acceleration           = 0.039,
  activateWhenBuilt      = true,
  brakeRate              = 0.115,
  buildCostMetal         = 240,
  builder                = false,
  buildPic               = [[shipskirm.png]],
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 2 0]],
  collisionVolumeScales  = [[24 24 60]],
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    helptext       = [[This Rocket Boat fires a salvo of four medium-range rockets, useful for bombarding sea and shore targets. Beware of subs and anything with enough speed to get close.]],
	turnatfullspeed = [[1]],
    modelradius     = [[24]],
  },


  explodeAs              = [[SMALL_UNITEX]],
  floater                = true,
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[shipskirm]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  losEmitHeight          = 30,
  maxDamage              = 650,
  maxVelocity            = 2.3,
  minCloakDistance       = 350,
  minWaterDepth          = 10,
  movementClass          = [[BOAT3]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[shipskirm.s3o]],
  script		         = [[shipskirm.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],
  sfxtypes               = {

    explosiongenerators = {
      [[custom:MISSILE_EXPLOSION]],
      [[custom:MEDMISSILE_EXPLOSION]],
    },

  },

  sightDistance          = 720,
  sonarDistance          = 720,
  turninplace            = 0,
  turnRate               = 400,
  waterline              = 4,
  workerTime             = 0,

  weapons                = {

	{
      def                = [[ROCKET]], 
	  badTargetCategory	 = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
	
  },


  weaponDefs             = {

     ROCKET = {
      name                    = [[Unguided Rocket]],
      areaOfEffect            = 75,
	  burst                   = 4,
	  burstRate               = 0.3,
      cegTag                  = [[missiletrailred]],
      craterBoost             = 1,
      craterMult              = 2,

      customParams        = {
		light_camera_height = 1800,
      },
	  
      damage                  = {
        default = 280,
        planes  = 280,
        subs    = 28,
      },

      fireStarter             = 70,
      flightTime              = 3.5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_hailstorm.s3o]],
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 610,
      reloadtime              = 8.0,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med4]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/missile2_fire_bass]],
      soundStartVolume        = 7,
      startVelocity           = 230,
      texture2                = [[darksmoketrail]],
      tracks                  = false,
      trajectoryHeight        = 0.6,
      turnrate                = 1000,
      turret                  = true,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 230,
	  wobble                  = 5000,
    },

  },


  featureDefs            = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],

      footprintX       = 2,
      footprintZ       = 2,
      object           = [[shipskirm_dead.s3o]],
    },


    HEAP = {
      blocking         = false,

      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ shipskirm = unitDef })
