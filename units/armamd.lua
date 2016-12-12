unitDef = {
  unitname                      = [[armamd]],
  name                          = [[Protector]],
  description                   = [[Strategic Nuke Interception System]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildCostEnergy               = 3000,
  buildCostMetal                = 3000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[antinuke_decal.dds]],
  buildPic                      = [[ARMAMD.png]],
  buildTime                     = 3000,
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[70 70 110]],
  collisionVolumeType           = [[CylZ]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Antinukleares System (Anti-Nuke)]],
    description_fr = [[Syst?me de D?fense Anti Missile (AntiNuke)]],
	description_pl = [[Tarcza Antyrakietowa]],
    helptext       = [[The Protector automatically intercepts enemy nuclear ICBMs aimed within its coverage radius.]],
    helptext_de    = [[Der Protector fängt automatisch gegnerische, atomare Interkontinentalraketen, welche in den, vom System abgedeckten, Bereich zielen, ab.]],
    helptext_fr    = [[Le Protector est un b?timent indispensable dans tout conflit qui dure. Il est toujours malvenu de voir sa base r?duite en cendres ? cause d'un missile nucl?aire. Le Protector est un syst?me de contre mesure capable de faire exploser en vol les missiles nucl?aires ennemis.]],
	helptext_pl    = [[Protector automatycznie wysy³a przeciwrakiety, aby zniszczyæ przelatuj¹ce nad jego obszarem ochrony g³owice nuklearne przeciwników.]],
	removewait     = 1,
    nuke_coverage  = 2500,
  },

  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 5,
  footprintZ                    = 8,
  iconType                      = [[antinuke]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  maxDamage                     = 3300,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  objectName                    = [[antinuke.s3o]],
  radarDistance                 = 2500,
  radarEmitHeight			    = 24,
  script                        = [[armamd.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  sightDistance                 = 660,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
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
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 8,
      object           = [[antinuke_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 5,
      footprintZ       = 8,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ armamd = unitDef })
