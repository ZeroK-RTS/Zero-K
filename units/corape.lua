unitDef = {
  unitname               = [[corape]],
  name                   = [[Rapier]],
  description            = [[Multi-Role/AA Gunship]],
  acceleration           = 0.152,
  amphibious             = true,
  bankscale              = [[1]],
  brakeRate              = 3.563,
  buildCostEnergy        = 300,
  buildCostMetal         = 300,
  builder                = false,
  buildPic               = [[CORAPE.png]],
  buildTime              = 300,
  canAttack              = true,
  canFly                 = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collide                = true,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[32 32 32]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],
  cruiseAlt              = 140,

  customParams           = {
    description_bp = [[Aeronave flutuadora agressora]],
    description_fr = [[ADAV Pilleur]],
	description_de = [[Skirmisher/Flugabwehr Hubschrauber]],
    helptext       = [[The Rapier is a light combat gunship. Its missiles are accurate and hit air, and it is good against small targets and defending against other raiders.]],
    helptext_bp    = [[A aeronave flutuante agressora leve de Logos. Seus mísseis s?o precisos e pode atingir o ar, tornando-a útil contra alvos pequenos e outras aeronaves agressoras.]],
    helptext_fr    = [[des missiles pr?cis et une vitesse de vol appr?ciable, le Rapier saura vous d?fendre contre d'autres pilleurs ou mener des assauts rapides.]],
	helptext_de    = [[Der Rapier ist ein leichter Raiderhubschrauber. Seine Raketen sind akkurat und treffen auch Lufteinheiten. Des Weiteren erweist er sich gegen kleine Ziele und als Gegenwehr gegen andere Raider als sehr nützlich.]],
  },

  explodeAs              = [[GUNSHIPEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  hoverAttack            = true,
  iconType               = [[gunship]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 208,
  maxDamage              = 1300,
  maxVelocity            = 3.8,
  minCloakDistance       = 75,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[corape.s3o]],
  scale                  = [[1]],
  seismicSignature       = 0,
  selfDestructAs         = [[GUNSHIPEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:rapiermuzzle]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 550,
  smoothAnim             = true,
  turnRate               = 594,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[VTOL_ROCKET]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    VTOL_ROCKET = {
      name                    = [[Light Homing Missiles]],
      areaOfEffect            = 16,
      avoidFeature            = false,
      burnblow                = true,
      cegTag                  = [[missiletrailyellow]],
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 150,
        subs    = 5,
      },

      explosionGenerator      = [[custom:DEFAULT]],
      fireStarter             = 70,
      flightTime              = 2.2,
      guidance                = true,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_maverick.s3o]],
      pitchtolerance          = [[12000]],
      range                   = 300,
      reloadtime              = 4,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med11]],
      soundStart              = [[weapon/missile/rocket_fire]],
      soundTrigger            = true,
      startsmoke              = [[1]],
      startVelocity           = 250,
      texture2                = [[lightsmoketrail]],
      tolerance               = 32767,
      tracks                  = true,
      turnRate                = 60000,
      turret                  = false,
      weaponAcceleration      = 250,
      weaponTimer             = 6,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 1000,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Rapier]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1300,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 120,
      object           = [[rapier_d.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    
    HEAP  = {
      description      = [[Debris - Rapier]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1300,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 60,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corape = unitDef })
