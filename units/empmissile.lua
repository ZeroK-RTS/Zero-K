unitDef = {
  unitname               = [[empmissile]],
  name                   = [[Shockley]],
  description            = [[EMP missile]],
  acceleration           = 1,
  brakeRate              = 0,
  buildAngle             = 8192,
  buildCostEnergy        = 600,
  buildCostMetal         = 600,
  builder                = false,
  buildPic               = [[empmissile.png]],
  buildTime              = 600,
  canAttack              = true,
  canGuard               = true,
  canstop                = [[1]],
  category               = [[SINK UNARMED]],
  collisionVolumeOffsets = [[0 15 0]],
  collisionVolumeScales  = [[20 50 20]],
  collisionVolumeTest	 = 1,
  collisionVolumeType	 = [[CylY]],

  customParams           = {
    description_de = [[EMP Rakete]],
    helptext       = [[The Shockley disables units in a small area for up to 45 seconds.]],
	helptext_de    = [[Der Shockley paralysiert Einheiten in seiner kleinen Reichweite für bis zu 45 Sekunden.]],
    mobilebuilding = [[1]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 1,
  footprintZ             = 1,
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 217,
  maxDamage              = 1000,
  maxSlope               = 18,
  maxVelocity            = 0,
  maxWaterDepth          = 0,
  minCloakDistance       = 150,
  noAutoFire             = false,
  objectName             = [[wep_empmissile.s3o]],
  script                 = [[cruisemissile.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 0,
  turnRate               = 0,
  useBuildingGroundDecal = false,
  workerTime             = 0,
  yardMap                = [[o]],

  weapons                = {

    {
      def                = [[EMP_WEAPON]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP SUB]],
    },

  },


  weaponDefs             = {

    EMP_WEAPON = {
      name                    = [[EMP Missile]],
      areaOfEffect            = 280,
      avoidFriendly           = false,
	  cegTag                  = [[bigemptrail]],
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default        = 30000,
        empresistant75 = 7500,
        empresistant99 = 300,
      },

      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:POWERPLANT_EXPLOSION]],
      fireStarter             = 0,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      model                   = [[wep_empmissile.s3o]],
      paralyzer               = true,
      paralyzeTime            = 45,
      propeller               = [[1]],
      range                   = 3500,
      reloadtime              = 3,
      smokedelay              = [[0.1]],
      smokeTrail              = false,
      soundHit                = [[weapon/missile/emp_missile_hit]],
      soundStart              = [[weapon/missile/tacnuke_launch]],
      startsmoke              = [[1]],
      tolerance               = 4000,
      tracks                  = false,
      turnrate                = 12000,
      weaponAcceleration      = 180,
      weaponTimer             = 5,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1200,
    },

  },


  featureDefs            = {
  },

}

return lowerkeys({ empmissile = unitDef })
