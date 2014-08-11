unitDef = {
  unitname                      = [[armamd]],
  name                          = [[Protector]],
  description                   = [[Anti-Nuke System]],
  activateWhenBuilt             = true,
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
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylZ]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Antinukleares System (Anti-Nuke)]],
    description_fr = [[Syst?me de D?fense Anti Missile (AntiNuke)]],
    description_pl = [[Tarcza antyrakietowa]],
    helptext       = [[The Protector automatically intercepts enemy nuclear ICBMs aimed within its coverage radius.]],
    helptext_de    = [[Der Protector fängt automatisch gegnerische, atomare Interkontinentalraketen, welche in den, vom System abgedeckten, Bereich zielen, ab.]],
    helptext_fr    = [[Le Protector est un b?timent indispensable dans tout conflit qui dure. Il est toujours malvenu de voir sa base r?duite en cendres ? cause d'un missile nucl?aire. Le Protector est un syst?me de contre mesure capable de faire exploser en vol les missiles nucl?aires ennemis.]],
    helptext_pl    = [[Protector automatycznie wysyla przeciwrakiety, aby zniszczyc przelatujace nad jego obszarem ochrony glowice nuklearne przeciwnikow.]],
  },

  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 5,
  footprintZ                    = 8,
  iconType                      = [[antinuke]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 3300,
  maxSlope                      = 18,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  objectName                    = [[antinuke.s3o]],
  radarDistance                 = 2500,
  script                        = [[armamd.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  sightDistance                 = 660,
  useBuildingGroundDecal        = true,

  weapons                       = {

    {
      def = [[AMD_ROCKET]],
    },

  },

  weaponDefs                    = {

    AMD_ROCKET = {
      name                    = [[Anti-Nuke Missile]],
      areaOfEffect            = 420,
      collideFriendly         = false,
      coverage                = 2500,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 1500,
        subs    = 75,
      },

      explosionGenerator      = [[custom:ANTINUKE]],
      fireStarter             = 100,
      flighttime              = 100,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      interceptor             = 1,
      model                   = [[antinukemissile.s3o]],
      noSelfDamage            = true,
      range                   = 4500,
      reloadtime              = 6,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/missile_launch]],
      startVelocity           = 400,
      tolerance               = 4000,
      tracks                  = true,
      turnrate                = 65535,
      weaponAcceleration      = 400,
      weaponTimer             = 1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1300,
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
      featurereclamate = [[SMUDGE01]],
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
