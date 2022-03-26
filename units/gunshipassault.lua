return { gunshipassault = {
  unitname            = [[gunshipassault]],
  name                = [[Revenant]],
  description         = [[Heavy Raider/Assault Gunship]],
  acceleration        = 0.15,
  brakeRate           = 0.13,
  buildCostMetal      = 850,
  builder             = false,
  buildPic            = [[gunshipassault.png]],
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collide             = true,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[50 15 50]],
  collisionVolumeType    = [[cylY]],
  corpse              = [[DEAD]],
  cruiseAlt           = 135,

  customParams        = {
    bait_level_default = 1,
    airstrafecontrol = [[1]],
    modelradius    = [[10]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  hoverAttack         = true,
  iconType            = [[heavygunshipassault]],
  maxDamage           = 3600,
  maxVelocity         = 4.5,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[Black_Dawn.s3o]],
  script              = [[gunshipassault.lua]],
  selfDestructAs      = [[GUNSHIPEX]],
  sightDistance       = 585,
  turnRate            = 1000,

  weapons             = {

    {
      def                = [[VTOL_SALVO]],
      mainDir            = [[0 -0.35 1]],
      maxAngleDif        = 90,
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP FIXEDWING HOVER]],
    },

  },


  weaponDefs          = {

    VTOL_SALVO = {
      name                    = [[Rocket Salvo]],
      areaOfEffect            = 96,
      avoidFeature            = false,
      avoidFriendly           = false,
      burst                   = 8,
      burstrate               = 2/30,
      cegTag                  = [[BANISHERTRAIL]],
      collideFriendly         = false,
      craterBoost             = 0.123,
      craterMult              = 0.246,

      customparams = {
        burst = Shared.BURST_UNRELIABLE,

        light_camera_height = 2500,
        light_color = [[0.55 0.27 0.05]],
        light_radius = 360,
        
        combatrange = 160,
      },

      damage                  = {
        default = 220.5,
      },

      dance                   = 30,
      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:MEDMISSILE_EXPLOSION]],
      fireStarter             = 70,
      flightTime              = 5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[hobbes_nohax.s3o]],
      noSelfDamage            = true,
      range                   = 270,
      reloadtime              = 9,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/rapid_rocket_hit]],
      soundStart              = [[weapon/missile/rapid_rocket_fire]],
      startVelocity           = 150,
      tolerance               = 15000,
      tracks                  = true,
      turnRate                = 1400,
      turret                  = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 250,
      wobble                  = 8000,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      collisionVolumeScales  = [[65 20 65]],
      collisionVolumeType    = [[CylY]],
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[blackdawn_d.dae]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
