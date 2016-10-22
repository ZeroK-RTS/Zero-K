unitDef = {
  unitname            = [[shiptorp]],
  name                = [[Hunter]],
  description         = [[Torpedo Riot Frigate]],
  acceleration        = 0.048,
  activateWhenBuilt   = true,
  brakeRate           = 0.043,
  buildCostEnergy     = 350,
  buildCostMetal      = 350,
  builder             = false,
  buildPic            = [[DCLSHIP.png]],
  buildTime           = 350,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[SHIP]],
  collisionVolumeOffsets = [[0 -7 0]],
  collisionVolumeScales  = [[34 34 80]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylZ]],
  corpse              = [[DEAD]],

  customParams        = {
    description_de = [[Torpedofregatte]],
    description_pl = [[Fregata torpedowa]],
    helptext       = [[The Hunter is a mobile anti-submarine unit. It boasts a massive area of effect.]],
	helptext_de    = [[Die relativ günstige Torpedofregatte besitzt eine Waffe speziell zur U-Jagd, die auch im Stande ist Schiffe zu treffen.]],
	helptext_pl    = [[Fregata torpedowa to odpowiedz na jednostki podwodne; moze tez strzelac w statki.]],
	modelradius    = [[14]],
	turnatfullspeed = [[1]],
  },

  explodeAs           = [[BIG_UNITEX]],
  floater             = true,
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[hunter]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1280]],
  mass                = 240,
  maxDamage           = 1200,
  maxVelocity         = 2.2,
  minCloakDistance    = 75,
  minWaterDepth       = 5,
  movementClass       = [[BOAT4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE HOVER]],
  objectName          = [[DCLSHIP]],
  script              = [[shiptorp.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  side                = [[ARM]],
  sightDistance       = 390,
  smoothAnim          = true,
  sonarDistance       = 450,
  turninplace         = 0,
  turnRate            = 420,
  waterline           = 4,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    TORPEDO = {
      name                    = [[Concussion Torpedo]],
      areaOfEffect            = 160,
      avoidFriendly           = false,
      bouncerebound           = 0.5,
      bounceslip              = 0.5,
	  burnblow                = 1,
      burst		              = 3,
      burstRate		          = 0.15,
      canAttackGround		  = false,	-- workaround for range hax
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 62,
        subs    = 62,
      },

      edgeEffectiveness       = 0.6,
      explosionGenerator      = [[custom:TORPEDO_HIT_LARGE_WEAK]],
      fixedLauncher           = true,
      groundbounce            = 1,
      impulseBoost            = 1,
      impulseFactor           = 0.9,
      interceptedByShieldType = 1,
	  flightTime              = 0.9,
	  leadlimit               = 0,
      model                   = [[wep_m_ajax.s3o]],
      myGravity               = 10.1,
      numbounce               = 4,
      noSelfDamage            = true,
      range                   = 350,
      reloadtime              = 2.2,
      soundHit                = [[TorpedoHitVariable]],
      soundHitVolume          = 2.8,
      soundStart              = [[weapon/torp_land]],
      soundStartVolume        = 0.8,
      startVelocity           = 20,
      tolerance               = 100000,
      tracks                  = true,
      turnRate                = 200000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 440,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 400,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[hunter_d.3ds]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ shiptorp = unitDef })
