unitDef = {
  unitname                      = [[seismic]],
  name                          = [[Quake]],
  description                   = [[Seismic Missile]],
  buildCostEnergy               = 400,
  buildCostMetal                = 400,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 3,
  buildingGroundDecalSizeY      = 3,
  buildingGroundDecalType       = [[seismic_aoplane.dds]],
  buildPic                      = [[seismic.png]],
  buildTime                     = 400,
  canAttack                     = true,
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 15 0]],
  collisionVolumeScales         = [[20 50 20]],
  collisionVolumeTest	        = 1,
  collisionVolumeType	        = [[CylY]],

  customParams                  = {
    description_de = [[Seismische Rakete]],
    description_pl = [[Rakieta Sejsmiczna]],
    helptext       = [[The Quake creates a powerful seismic shockwave that smooths a wide area of terrain, while causing minimal harm to units.]],
    helptext_de    = [[Die Rakete Quake erzeugt eine akustische Schockwelle, welche die anliegend Boden glatt macht, aber nur minimale Schäden an Einheiten aus Metall und Kohlenstoff-Nanoröhrchen verursacht.]],
    helptext_pl    = [[Jednorazowa rakieta sejsmiczna dalekiego zasiegu. Nie zadaje obrazen, ale wyrownuje okoliczny teren.]],
    mobilebuilding = [[1]],
  },

  explodeAs                     = [[SEISMIC_WEAPON]],
  footprintX                    = 1,
  footprintZ                    = 1,
  iconType                      = [[cruisemissilesmall]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 1000,
  maxSlope                      = 18,
  minCloakDistance              = 150,
  objectName                    = [[wep_seismic.s3o]],
  script                        = [[cruisemissile.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[SEISMIC_WEAPON]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
    },

  },

  sightDistance                 = 0,
  useBuildingGroundDecal        = false,
  yardMap                       = [[o]],

  weapons                       = {

    {
      def                = [[SEISMIC_WEAPON]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },

  weaponDefs                    = {

    SEISMIC_WEAPON = {
      name                    = [[Seismic Missile]],
      areaOfEffect            = 512,
      avoidFriendly           = false,
      cegTag                  = [[seismictrail]],
      collideFriendly         = false,
      craterBoost             = 32,
      craterMult              = 1,

      customParams            = {
        gatherradius = [[416]],
        smoothradius = [[256]],
        detachmentradius = [[256]],
        smoothmult   = [[1]],
      },
	  
      damage                  = {
        default = 20,
        subs    = 1,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:bull_fade]],
      fireStarter             = 0,
      flightTime              = 100,
      interceptedByShieldType = 1,
      levelGround             = false,
      model                   = [[wep_seismic.s3o]],
      noSelfDamage            = true,
      range                   = 6000,
      reloadtime              = 10,
      shakeduration           = [[4]],
      shakemagnitude          = [[32]],
      smokeTrail              = false,
      soundHit                = [[explosion/ex_large4]],
      soundStart              = [[weapon/missile/tacnuke_launch]],
      tolerance               = 4000,
      turnrate                = 18000,
      waterWeapon             = true,
      weaponAcceleration      = 180,
      weaponTimer             = 3,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1200,
    },

  },

  featureDefs                   = {
  },

}

return lowerkeys({ seismic = unitDef })
