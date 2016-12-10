unitDef = {
  unitname               = [[shipskirm]],
  name                   = [[Mistral]],
  description            = [[Missile Boat (Skirmisher)]],
  acceleration           = 0.039,
  activateWhenBuilt      = true,
  brakeRate              = 0.115,
  buildCostEnergy        = 240,
  buildCostMetal         = 240,
  builder                = false,
  buildPic               = [[shipskirm.png]],
  buildTime              = 240,
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
       helptext       = [[This Missile Boat fires medium-range missiles, useful for bombarding sea and shore targets. Beware of subs and anything with enough speed to get close.]],
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
  maxVelocity            = 2.5,
  minCloakDistance       = 350,
  minWaterDepth          = 10,
  movementClass          = [[BOAT3]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[shipskirm.s3o]],
  scale                  = [[0.6]],
  script		         = [[shipskirm.lua]],
  seismicSignature       = 4,
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
      def                = [[MISSILE]],
	  badTargetCategory	 = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    MISSILE = {

      name                    = [[Guided Missile]],
      areaOfEffect            = 10,
      cegTag                  = [[missiletrailyellow]],
      craterBoost             = 1,
      craterMult              = 2,


      damage                  = {

        default = 130,
        subs    = 13,
      },

      edgeEffectiveness       = 0.4,

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 20,
      flightTime              = 3,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      impactOnly              = false,
      interceptedByShieldType = 2,
      model                   = [[hobbes.s3o]],
      noSelfDamage            = true,
      range                   = 650,
      reloadtime              = 2.5,
      smokeTrail              = false,
      soundHit                = [[explosion/ex_small13]],
	  soundStart              = [[weapon/missile/missile_fire11]],
      startVelocity           = 400,
      tolerance               = 9000,
      tracks                  = true,
      trajectoryHeight        = 0.7,
      turnRate                = 6000,
      turret                  = true,
      weaponAcceleration      = 300,
      weaponTimer             = 5,
      weaponType              = [[MissileLauncher]],

      weaponVelocity          = 750,
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
