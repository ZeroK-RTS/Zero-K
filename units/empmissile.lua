unitDef = {
  unitname                      = [[empmissile]],
  name                          = [[Shockley]],
  description                   = [[EMP missile]],
  acceleration                  = 1,
  antiweapons                   = [[1]],
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildAngle                    = 8192,
  buildCostEnergy               = 450,
  buildCostMetal                = 450,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 3,
  buildingGroundDecalSizeY      = 3,
  buildingGroundDecalType       = [[empmissile_aoplane.dds]],
  buildPic                      = [[empmissile.png]],
  buildTime                     = 450,
  canAttack                     = true,
  canGuard                      = true,
  canstop                       = [[1]],
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 35 0]],
  collisionVolumeScales         = [[20 80 20]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylY]],

  customParams                  = {
    helptext       = [[The Shockley disables units in a small area for up to 45 seconds.]],
    mobilebuilding = [[1]],
  },

  explodeAs                     = [[SMALL_UNITEX]],
  footprintX                    = 1,
  footprintZ                    = 1,
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  mass                          = 243,
  maxDamage                     = 2000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[wep_empmissile.s3o]],
  script                        = [[cruisemissile.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[SMALL_UNITEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
    },

  },

  side                          = [[CORE]],
  sightDistance                 = 200,
  smoothAnim                    = true,
  TEDClass                      = [[SPECIAL]],
  turnRate                      = 0,
  useBuildingGroundDecal        = false,
  workerTime                    = 0,
  yardMap                       = [[o]],

  weapons                       = {

    {
      def                = [[EMP_WEAPON]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER FIXEDWING GUNSHIP SUB]],
    },

  },


  weaponDefs                    = {

    EMP_WEAPON = {
      name                    = [[EMPMissile]],
      areaOfEffect            = 280,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default        = 36000,
        commanders     = 3600,
        empresistant75 = 9000,
        empresistant99 = 360,
        planes         = 36000,
      },

      edgeEffectiveness       = 1,
      energypershot           = [[0]],
      explosionGenerator      = [[custom:POWERPLANT_EXPLOSION]],
      fireStarter             = 0,
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      model                   = [[wep_empmissile.s3o]],
      noautorange             = [[1]],
      noSelfDamage            = true,
      paralyzer               = true,
      paralyzeTime            = 45,
      propeller               = [[1]],
      range                   = 3500,
      reloadtime              = 3,
      renderType              = 1,
      selfprop                = true,
      shakeduration           = [[1.5]],
      shakemagnitude          = [[32]],
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[weapon/missile/emp_missile_hit]],
      soundStart              = [[weapon/missile/tacnuke_launch]],
      startsmoke              = [[1]],
      tolerance               = 4000,
      tracks                  = true,
      turnrate                = 12000,
      vlaunch                 = true,
      weaponAcceleration      = 180,
      weaponTimer             = 5,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1200,
    },

  },


  featureDefs                   = {
  },

}

return lowerkeys({ empmissile = unitDef })
