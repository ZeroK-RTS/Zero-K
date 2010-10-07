unitDef = {
  unitname               = [[slowmissile]],
  name                   = [[Plodder]],
  description            = [[Slow Missile]],
  acceleration           = 1,
  antiweapons            = [[1]],
  bmcode                 = [[0]],
  brakeRate              = 0,
  buildAngle             = 8192,
  buildCostEnergy        = 500,
  buildCostMetal         = 500,
  builder                = false,
  buildPic               = [[napalmmissile.png]],
  buildTime              = 500,
  canAttack              = true,
  canGuard               = true,
  canstop                = [[1]],
  category               = [[SINK UNARMED]],
  collisionVolumeOffsets = [[0 35 0]],
  collisionVolumeScales  = [[20 80 20]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[CylY]],

  customParams           = {
    helptext = [[The Plodder increases reload times and reduces unit speed in an area for a minute]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 1,
  footprintZ             = 1,
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 350,
  maxDamage              = 2000,
  maxSlope               = 18,
  maxVelocity            = 0,
  maxWaterDepth          = 0,
  minCloakDistance       = 150,
  noAutoFire             = false,
  objectName             = [[wep_napalm.s3o]],
  script                 = [[cruisemissile.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 660,
  smoothAnim             = true,
  TEDClass               = [[SPECIAL]],
  turnRate               = 0,
  workerTime             = 0,
  yardMap                = [[o]],

  weapons                = {

    {
      def                = [[WEAPON]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    WEAPON = {
      name                    = [[Slow Missile]],
      areaOfEffect            = 1024,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 4,
      craterMult              = 3.5,

      damage                  = {
        default = 100,
        planes  = 100,
        subs    = 100,
      },

      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:napalmmissile]],
      fireStarter             = 75,
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      levelGround             = false,
      lineOfSight             = true,
      model                   = [[wep_napalm.s3o]],
      noautorange             = [[1]],
      noSelfDamage            = true,
      propeller               = [[1]],
      range                   = 3500,
      reloadtime              = 10,
      renderType              = 1,
      selfprop                = true,
      shakeduration           = [[1.5]],
      shakemagnitude          = [[32]],
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/tacnuke_launch]],
      startsmoke              = [[1]],
      tolerance               = 4000,
      twoPhase                = true,
      vlaunch                 = true,
      weaponAcceleration      = 180,
      weaponTimer             = 3,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1200,
    },

  },


  featureDefs            = {
  },

	buildingGroundDecalDecaySpeed=30,
	buildingGroundDecalSizeX=3,
	buildingGroundDecalSizeY=3,
	useBuildingGroundDecal = true,
	buildingGroundDecalType=[[slowmissile_aoplane.dds]],
}

return lowerkeys({ slowmissile = unitDef })
