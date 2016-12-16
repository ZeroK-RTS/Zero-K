unitDef = {
  unitname               = [[gunshipsupport]],
  name                   = [[Rapier]],
  description            = [[Multi-Role Support Gunship]],
  acceleration           = 0.152,
  brakeRate              = 0.1216,
  buildCostEnergy        = 300,
  buildCostMetal         = 300,
  builder                = false,
  buildPic               = [[CORAPE.png]],
  buildTime              = 300,
  canAttack              = true,
  canFly                 = true,
  canMove                = true,
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collide                = true,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[32 32 32]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],
  cruiseAlt              = 140,

  customParams           = {
    airstrafecontrol = [[1]],
    description_fr = [[ADAV Pilleur]],
    description_de = [[Skirmisher/Flugabwehr Hubschrauber]],
    helptext       = [[The Rapier is a light combat gunship. While its missiles are not the most damaging thing around, they are quite accurate and their disruption warheads slow down their targets.]],
    --helptext_fr    = [[des missiles pr?cis et une vitesse de vol appr?ciable, le Rapier saura vous d?fendre contre d'autres pilleurs ou mener des assauts rapides.]],
    --helptext_de    = [[Der Rapier ist ein leichter Raiderhubschrauber. Seine Raketen sind akkurat und treffen auch Lufteinheiten. Des Weiteren erweist er sich gegen kleine Ziele und als Gegenwehr gegen andere Raider als sehr nützlich.]],
    modelradius    = [[16]],
  },

  explodeAs              = [[GUNSHIPEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  hoverAttack            = true,
  iconType               = [[gunshipskirm]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 1100,
  maxVelocity            = 3.9,
  minCloakDistance       = 75,
  noChaseCategory        = [[TERRAFORM SUB]],
  objectName             = [[rapier.s3o]],
  script                 = [[gunshipsupport.lua]],
  seismicSignature       = 0,
  selfDestructAs         = [[GUNSHIPEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:rapiermuzzle]],
    },

  },

  sightDistance          = 550,
  turnRate               = 594,

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

      customparams = {
        timeslow_damagefactor = 3,
		
		light_camera_height = 2500,
		light_color = [[1.3 0.5 1.6]],
		light_radius = 220,
      },

      damage                  = {
        default = 200.1,
        subs    = 10,
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
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 1000,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[rapier_d.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ gunshipsupport = unitDef })
