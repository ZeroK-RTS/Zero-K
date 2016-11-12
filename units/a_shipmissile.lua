unitDef = {
  unitname               = [[a_shipmissile]],
  name                   = [[Siren]],
  description            = [[Missile Frigate (Skirmisher)]],
  acceleration           = 0.039,
  activateWhenBuilt      = true,
  brakeRate              = 0.115,
  buildAngle             = 16384,
  buildCostEnergy        = 240,
  buildCostMetal         = 240,
  builder                = false,
  buildPic               = [[CORROY.png]],
  buildTime              = 240,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 10 0]],
  collisionVolumeScales  = [[48 48 110]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    helptext       = [[This Missile Frigate fires medium-range missiles, useful for bombarding sea and shore targets. Beware of subs and anything with enough speed to get close.]],
	turnatfullspeed = [[1]],
    modelradius     = [[24]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  floater                = true,
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[a_shipmissile]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  losEmitHeight          = 30,
  maxDamage              = 650,
  maxVelocity            = 2.5,
  minCloakDistance       = 350,
  minWaterDepth          = 10,
  movementClass          = [[BOAT4]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[logsiren2.s3o]],
  scale                  = [[0.6]],
  script		         = [[a_shipmissile.cob]],
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:MISSILE_EXPLOSION]],
      [[custom:MEDMISSILE_EXPLOSION]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 660,
  sonarDistance          = 660,
  smoothAnim             = true,
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
        default = 105,
        subs    = 10.5,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 20,
      flightTime              = 5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      impactOnly              = false,
      interceptedByShieldType = 2,
      model                   = [[wep_m_havoc.s3o]],
      noSelfDamage            = true,
      range                   = 610,
      reloadtime              = 2.8,
      smokeTrail              = false,
      soundHit                = [[explosion/ex_small13]],
      soundHitVolume          = 2.5,
      soundStart              = [[weapon/missile/missile_fire11]],
      soundStartVolume        = 2.5,
      startVelocity           = 300,
      tolerance               = 9000,
      tracks                  = true,
      trajectoryHeight        = 0.7,
      turnRate                = 6000,
      turret                  = true,
      weaponAcceleration      = 70,
      weaponTimer             = 8,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 500,
    },

  },


  featureDefs            = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[logsiren2_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ a_shipmissile = unitDef })
