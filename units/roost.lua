unitDef = {
  unitname          = [[roost]],
  name              = [[Roost]],
  description       = [[Spawns Chicken]],
  acceleration      = 0,
  activateWhenBuilt = true,
  brakeRate         = 0,
  buildAngle        = 4096,
  buildCostEnergy   = 340,
  buildCostMetal    = 340,
  builder           = false,
  buildPic          = [[roost.png]],
  buildTime         = 340,
  category          = [[UNARMED FLOAT]],
  energyMake        = 4,
  explodeAs         = [[NOWEAPON]],
  footprintX        = 3,
  footprintZ        = 3,
  iconType          = [[special]],
  idleAutoHeal      = 0,
  idleTime          = 1800,
  levelGround       = false,
  mass              = 226,
  maxDamage         = 1800,
  maxSlope          = 36,
  maxVelocity       = 0,
  metalMake         = 4,
  minCloakDistance  = 150,
  noAutoFire        = false,
  objectName        = [[roost]],
  seismicSignature  = 4,
  selfDestructAs    = [[NOWEAPON]],

  sfxtypes          = {

    explosiongenerators = {
      [[custom:dirt2]],
      [[custom:dirt3]],
    },

  },

  side              = [[THUNDERBIRDS]],
  sightDistance     = 273,
  smoothAnim        = true,
  TEDClass          = [[ENERGY]],
  turnRate          = 0,
  upright           = false,
  waterline         = 0,
  workerTime        = 0,
  yardMap           = [[ooooooooo]],

  weapons           = {

    {
      def                = [[AEROSPORES]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs        = {

    AEROSPORES = {
      name                    = [[Anti-Air Spores]],
      areaOfEffect            = 24,
      avoidFriendly           = false,
      burst                   = 4,
      burstrate               = 0.2,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 80,
        planes  = 80,
        subs    = 8,
      },

      dance                   = 60,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      fixedlauncher           = 1,
      flightTime              = 5,
      groundbounce            = 1,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[chickeneggblue.s3o]],
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 3,
      renderType              = 1,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      startsmoke              = [[1]],
      startVelocity           = 100,
      texture1                = [[]],
      texture2                = [[sporetrailblue]],
      tolerance               = 10000,
      tracks                  = true,
      turnRate                = 24000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 500,
      wobble                  = 32000,
    },

  },


  featureDefs       = {
  },

}

return lowerkeys({ roost = unitDef })
