unitDef = {
  unitname                      = [[seismic]],
  name                          = [[Quake]],
  description                   = [[Seismic Missile]],
  acceleration                  = 1,
  antiweapons                   = [[1]],
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildAngle                    = 8192,
  buildCostEnergy               = 500,
  buildCostMetal                = 500,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 3,
  buildingGroundDecalSizeY      = 3,
  buildingGroundDecalType       = [[seismic_aoplane.dds]],
  buildPic                      = [[seismic.png]],
  buildTime                     = 500,
  canAttack                     = true,
  canGuard                      = true,
  canstop                       = [[1]],
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 15 0]],
  collisionVolumeScales         = [[20 50 20]],
  collisionVolumeTest	        = 1,
  collisionVolumeType	        = [[CylY]],

  customParams                  = {
    description_de = [[Seismische Rakete]],
    helptext       = [[The Quake creates a powerful sonic shockwave that leaves massive craters in soil, while causing minimal harm to units made of metal and carbon nanotubes.]],
	helptext_de    = [[Die Rakete Quake erzeugt eine akustische Schockwelle, welche massive Krater im Boden hinerlässt, aber nur minimale Schäden an Einheiten aus Metall und Kohlenstoff-Nanoröhrchen verursacht.]],
    mobilebuilding = [[1]],
  },

  explodeAs                     = [[SMALL_UNITEX]],
  footprintX                    = 1,
  footprintZ                    = 1,
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  mass                          = 188,
  maxDamage                     = 1000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[wep_seismic.s3o]],
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
      def                = [[SEISMIC_WEAPON]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs                    = {

    SEISMIC_WEAPON = {
      name                    = [[Seismic]],
      areaOfEffect            = 512,
      avoidFriendly           = false,
	  cegTag                  = [[tactrail]],
      collideFriendly         = false,
      craterBoost             = 32,
      craterMult              = 1,

	  customParams            = {
	    gatherradius = [[416]],
		smoothradius = [[256]],
		smoothmult   = [[1]],
	  },
	  
      damage                  = {
        default = 20,
        planes  = 20,
        subs    = 1,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:large_green_goo]],
      fireStarter             = 0,
      guidance                = true,
      interceptedByShieldType = 1,
      levelGround             = false,
      lineOfSight             = true,
      model                   = [[wep_seismic.s3o]],
      noautorange             = [[1]],
      noSelfDamage            = true,
      propeller               = [[1]],
      range                   = 6000,
      reloadtime              = 10,
      renderType              = 1,
      selfprop                = true,
      shakeduration           = [[4]],
      shakemagnitude          = [[32]],
      smokedelay              = [[0.1]],
      smokeTrail              = false,
      soundHit                = [[explosion/ex_large4]],
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


  featureDefs                   = {
  },

}

return lowerkeys({ seismic = unitDef })
