unitDef = {
  unitname               = [[gunshipsupport]],
  name                   = [[Rapier]],
  description            = [[Multi-Role Support Gunship]],
  acceleration           = 0.152,
  amphibious             = true,
  brakeRate              = 0.152,
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
    airstrafecontrol = [[1]],
    description_bp = [[Aeronave flutuadora agressora]],
    description_fr = [[ADAV Pilleur]],
	description_de = [[Skirmisher/Flugabwehr Hubschrauber]],
	description_pl = [[Wielozadaniowy statek powietrzny]],
    helptext       = [[The Rapier is a light combat gunship. While its missiles are not the most damaging thing around, they are quite accurate and their disruption warheads slow down their targets.]],
    --helptext_bp    = [[A aeronave flutuante agressora leve de Logos. Seus mísseis s?o precisos e pode atingir o ar, tornando-a útil contra alvos pequenos e outras aeronaves agressoras.]],
    --helptext_fr    = [[des missiles pr?cis et une vitesse de vol appr?ciable, le Rapier saura vous d?fendre contre d'autres pilleurs ou mener des assauts rapides.]],
	--helptext_de    = [[Der Rapier ist ein leichter Raiderhubschrauber. Seine Raketen sind akkurat und treffen auch Lufteinheiten. Des Weiteren erweist er sich gegen kleine Ziele und als Gegenwehr gegen andere Raider als sehr nützlich.]],
	--helptext_pl    = [[Rapier to lekki statek bojowy, ktorego rakiety sa na tyle celne, ze dobrze radzi sobie z lekkimi, szybkimi jednostkami, a nawet z lotnictwem.]],
	modelradius    = [[16]],
  },

  explodeAs              = [[GUNSHIPEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  hoverAttack            = true,
  iconType               = [[gunshipears]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 208,
  maxDamage              = 1100,
  maxVelocity            = 3.9,
  minCloakDistance       = 75,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[rapier.s3o]],
  script                 = [[gunshipsupport.lua]],
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
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    VTOL_ROCKET = {
      name                    = [[Disruptor Missiles]],
      areaOfEffect            = 16,
      avoidFeature            = false,
      burnblow                = true,
      cegTag                  = [[missiletrailpurple]],
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 190,
        subs    = 9.5,
      },

      explosionGenerator      = [[custom:disruptor_missile_hit]],
      fireStarter             = 70,
      flightTime              = 2.2,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_maverick.s3o]],
      range                   = 360,
      reloadtime              = 5,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med11]],
      soundStart              = [[weapon/missile/rocket_fire]],
      soundTrigger            = true,
      startVelocity           = 250,
      texture2                = [[purpletrail]],
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
      damage           = 1100,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 120,
      object           = [[rapier_d.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
    },

    
    HEAP  = {
      description      = [[Debris - Rapier]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1100,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 60,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
    },

  },

}

return lowerkeys({ gunshipsupport = unitDef })
