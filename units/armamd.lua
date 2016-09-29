unitDef = {
  unitname                      = [[armamd]],
  name                          = [[Protector]],
  description                   = [[Strategic Nuke Interception System]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildAngle                    = 4096,
  buildCostEnergy               = 3000,
  buildCostMetal                = 3000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[antinuke_decal.dds]],
  buildPic                      = [[ARMAMD.png]],
  buildTime                     = 3000,
  category                      = [[FLOAT]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[70 70 110]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylZ]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Antinukleares System (Anti-Nuke)]],
    description_fr = [[Syst?me de D?fense Anti Missile (AntiNuke)]],
	description_pl = [[Tarcza Antyrakietowa]],
    helptext       = [[The Protector automatically intercepts enemy nuclear ICBMs aimed within its coverage radius.]],
    helptext_de    = [[Der Protector f�ngt automatisch gegnerische, atomare Interkontinentalraketen, welche in den, vom System abgedeckten, Bereich zielen, ab.]],
    helptext_fr    = [[Le Protector est un b?timent indispensable dans tout conflit qui dure. Il est toujours malvenu de voir sa base r?duite en cendres ? cause d'un missile nucl?aire. Le Protector est un syst?me de contre mesure capable de faire exploser en vol les missiles nucl?aires ennemis.]],
	helptext_pl    = [[Protector automatycznie wysy�a przeciwrakiety, aby zniszczy� przelatuj�ce nad jego obszarem ochrony g�owice nuklearne przeciwnik�w.]],
	removewait     = 1,
    nuke_coverage  = 2500,
  },

  explodeAs                     = [[LARGE_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 5,
  footprintZ                    = 8,
  iconType                      = [[antinuke]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  mass                          = 561,
  maxDamage                     = 3300,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  objectName                    = [[antinuke.s3o]],
  radarDistance                 = 2500,
  radarEmitHeight			    = 24,
  script                        = [[armamd.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  side                          = [[ARM]],
  sightDistance                 = 660,
  smoothAnim                    = true,
  TEDClass                      = [[FORT]],
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  waterline                     = 13,
  workerTime                    = 0,
  yardmap                       = "oooooooooooooooooooooooooooooooooooooooo",

  weapons                       = {

    {
      def = [[AMD_ROCKET]],
    },

  },


  weaponDefs                    = {

    AMD_ROCKET = {
      name                    = [[Anti-Nuke Missile Fake]],
      areaOfEffect            = 420,
      collideFriendly         = false,
      collideGround           = false,
      coverage                = 100000,
      craterBoost             = 1,
      craterMult              = 2,
	  
	  customParams            = {
        nuke_coverage = 2500,
	  },
	  
      damage                  = {
        default = 1500,
        subs    = 75,
      },

      explosionGenerator      = [[custom:ANTINUKE]],
      fireStarter             = 100,
      flightTime              = 20,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      interceptor             = 1,
      model                   = [[antinukemissile.s3o]],
      noSelfDamage            = true,
      range                   = 3800,
      reloadtime              = 6,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/missile_launch]],
      startVelocity           = 400,
      tolerance               = 4000,
      tracks                  = true,
      turnrate                = 65535,
      weaponAcceleration      = 800,
      weaponTimer             = 0.4,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1600,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Protector]],
      blocking         = true,
      damage           = 3300,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 8,
      metal            = 1200,
      object           = [[antinuke_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 1200,
    },


    HEAP  = {
      description      = [[Debris - Protector]],
      blocking         = false,
      damage           = 3300,
      energy           = 0,
      footprintX       = 5,
      footprintZ       = 8,
      metal            = 600,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 600,
    },

  },

}

return lowerkeys({ armamd = unitDef })
