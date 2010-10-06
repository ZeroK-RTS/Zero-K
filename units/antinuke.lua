unitDef = {
  unitname               = [[antinuke]],
  name                   = [[Interceptor]],
  description            = [[Anti-Nuke]],
  acceleration           = 1,
  antiweapons            = [[1]],
  bmcode                 = [[0]],
  brakeRate              = 0,
  buildAngle             = 8192,
  buildCostEnergy        = 300,
  buildCostMetal         = 300,
  builder                = false,
  buildPic               = [[antinuke.png]],
  buildTime              = 300,
  canAttack              = true,
  canstop                = [[1]],
  category               = [[SINK UNARMED]],
  collisionVolumeOffsets = [[0 -10 0]],
  collisionVolumeScales  = [[10 40 10]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[box]],

  customParams           = {
    description_fr = [[Lance Missile Nucléaire Tactique]],
    helptext       = [[A long-range precision strike weapon, the Logos Catalyst can pick off high-value targets from a safe distance with its tactical nuclear warheads.]],
    helptext_fr    = [[Le Catalyst est un lance missile nucléaire tactique. Les tetes nucléaires ne sont pas aussi lourdes que celles du Silencer et la portée moindre. Mais bien placé, il peut faire des ravages, et présente un rapport cout/efficacité plus qu'interressant.]],
    mobilebuilding = [[1]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 1,
  footprintZ             = 1,
  iconType               = [[cruisemissile]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 150,
  maxDamage              = 2000,
  maxSlope               = 18,
  maxVelocity            = 0,
  maxWaterDepth          = 0,
  minCloakDistance       = 150,
  noAutoFire             = false,
  objectName             = [[wep_antinuke.s3o]],
  radarDistance          = 2000,
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 660,
  smoothAnim             = true,
  TEDClass               = [[SPECIAL]],
  turnRate               = 0,
  workerTime             = 0,
  yardMap                = [[o]],

  weapons                = {

    {
      def = [[Antinuke]],
    },

  },


  weaponDefs             = {

    Antinuke = {
      name                    = [[Anti-Nuke Missile]],
      areaOfEffect            = 420,
      avoidFriendly           = false,
      collideFriendly         = false,
      coverage                = 2000,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 1500,
        subs    = 75,
      },

      explosionGenerator      = [[custom:ANTINUKE]],
      fireStarter             = 100,
      flighttime              = 100,
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      interceptor             = 1,
      lineOfSight             = true,
      model                   = [[wep_antinuke.s3o]],
      noautorange             = [[1]],
      noSelfDamage            = true,
      range                   = 4000,
      reloadtime              = 6,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/tacnuke_launch]],
      startsmoke              = [[1]],
      startVelocity           = 400,
      tolerance               = 4000,
      tracks                  = true,
      turnrate                = 65535,
      twoPhase                = true,
      vlaunch                 = true,
      weaponAcceleration      = 400,
      weaponTimer             = 0.2,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1300,
    },

  },


  featureDefs            = {
  },

}

return lowerkeys({ antinuke = unitDef })
