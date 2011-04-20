unitDef = {
  unitname                      = [[chickenspire]],
  name                          = [[Chicken Spire]],
  description                   = [[Static Artillery]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildCostEnergy               = 0,
  buildCostMetal                = 0,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[chickenspire_aoplane.dds]],
  buildPic                      = [[chickenspire.png]],
  buildTime                     = 2500,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 48 0]],
  collisionVolumeScales         = [[58 176 58]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylY]],

  customParams                  = {
    description_fr = [[Artillerie statique]],
	description_de = [[Stationäre Artillerie]],
    helptext       = [[Long range static artillery.]],
    helptext_fr    = [[La terreur verte projette des amas commpos?s de d'acides corrosifs et de germes sur de tr?s longues distances.]],
	helptext_de    = [[Weitreichende, stationäre Artillerie.]],
  },

  defaultmissiontype            = [[GUARD_NOMOVE]],
  energyMake                    = 0,
  explodeAs                     = [[NOWEAPON]],
  floater                       = true,
  footprintX                    = 4,
  footprintZ                    = 4,
  iconType                      = [[staticarty]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  mass                          = 344,
  maxDamage                     = 1500,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  maxWaterDepth                 = 20,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[spire.s3o]],
  onoffable                     = true,
  power                         = 2500,
  seismicSignature              = 4,
  selfDestructAs                = [[NOWEAPON]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side                          = [[THUNDERBIRDS]],
  sightDistance                 = 512,
  smoothAnim                    = true,
  TEDClass                      = [[METAL]],
  turnRate                      = 0,
  upright                       = false,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooooooooooooooo]],

  weapons                       = {

    {
      def                = [[SLAMSPORE]],
      onlyTargetCategory = [[LAND SINK SHIP SWIM FLOAT HOVER]],
    },

  },


  weaponDefs                    = {

    SLAMSPORE = {
      name                    = [[Slammer Spore]],
      areaOfEffect            = 128,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 1000,
      },

      dance                   = 60,
      explosionGenerator      = [[custom:large_green_goo]],
      fireStarter             = 0,
      flightTime              = 30,
      groundbounce            = 1,
      guidance                = true,
      heightmod               = 0.5,
      impactOnly              = false,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[chickenegggreen_big.s3o]],
      noSelfDamage            = true,
      range                   = 4500,
      reloadtime              = 10,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      startsmoke              = [[1]],
      startVelocity           = 40,
      texture1                = [[none]],
      texture2                = [[sporetrail2]],
      tolerance               = 10000,
      tracks                  = true,
      trajectoryHeight        = 2,
      turnRate                = 10000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 40,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
    },

  },

}

return lowerkeys({ chickenspire = unitDef })
