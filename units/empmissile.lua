unitDef = {
  unitname               = [[empmissile]],
  name                   = [[Shockley]],
  description            = [[EMP missile]],
  buildCostEnergy        = 600,
  buildCostMetal         = 600,
  builder                = false,
  buildPic               = [[empmissile.png]],
  buildTime              = 600,
  canAttack              = true,
  category               = [[SINK UNARMED]],
  collisionVolumeOffsets = [[0 15 0]],
  collisionVolumeScales  = [[20 50 20]],
  collisionVolumeTest	 = 1,
  collisionVolumeType	 = [[CylY]],

  customParams           = {
    description_de = [[EMP Rakete]],
    description_pl = [[Rakieta EMP]],
    helptext       = [[The Shockley disables units in a small area for up to 45 seconds.]],
    helptext_de    = [[Der Shockley paralysiert Einheiten in seiner kleinen Reichweite für bis zu 45 Sekunden.]],
    helptext_pl    = [[Jednorazowa rakieta dalekiego zasiegu, ktora paralizuje trafione jednostki do 45 sekund.]],
    mobilebuilding = [[1]],
  },

  explodeAs              = [[EMP_WEAPON]],
  footprintX             = 1,
  footprintZ             = 1,
  iconType               = [[cruisemissilesmall]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 1000,
  maxSlope               = 18,
  minCloakDistance       = 150,
  objectName             = [[wep_empmissile.s3o]],
  script                 = [[cruisemissile.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[EMP_WEAPON]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]]
    },

  },

  sightDistance          = 0,
  useBuildingGroundDecal = false,
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
        default = 30000,
      },

      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:EMPMISSILE_EXPLOSION]],
      fireStarter             = 0,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      model                   = [[wep_empmissile.s3o]],
      paralyzer               = true,
      paralyzeTime            = 45,
      range                   = 3500,
      reloadtime              = 3,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/emp_missile_hit]],
      soundStart              = [[weapon/missile/tacnuke_launch]],
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
