return { shipcarrier = {
  unitname               = [[shipcarrier]],
  name                   = [[Reef]],
  description            = [[Aircraft Carrier (Bombardment), stockpiles disarm missiles at 5 m/s]],
  acceleration           = 0.21,
  activateWhenBuilt      = true,
  brakeRate              = 0.56,
  buildCostMetal         = 3000,
  builder                = false,
  buildPic               = [[shipcarrier.png]],
  canMove                = true,
  canManualFire          = true,
  cantBeTransported      = true,
  category               = [[SHIP]],
  CollisionSphereScale   = 0.6,
  collisionVolumeOffsets = [[10 -10 0]],
  collisionVolumeScales  = [[80 80 240]],
  collisionVolumeType    = [[CylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    midposoffset   = [[0 -10 0]],
    modelradius    = [[80]],
    stockpiletime  = [[30]],
    stockpilecost  = [[150]],
    priority_misc = 2, -- High
    extradrawrange = 3000,
    ispad         = 1,
    pad_count     = 2,

    outline_x = 300,
    outline_y = 300,
    outline_yoff = 55,
  },

  explodeAs              = [[ATOMIC_BLASTSML]],
  floater                = true,
  footprintX             = 5,
  footprintZ             = 5,
  iconType               = [[shipcarrier]],
  maxDamage              = 7500,
  maxVelocity            = 2.75,
  minWaterDepth          = 10,
  movementClass          = [[BOAT5]],
  objectName             = [[shipcarrier.dae]],
  script                 = [[shipcarrier.lua]],
  radarEmitHeight        = 48,
  selfDestructAs         = [[ATOMIC_BLASTSML]],
  sfxtypes               = {
    explosiongenerators = {
      [[custom:xamelimpact]],
      [[custom:ROACHPLOSION]],
      [[custom:shellshockflash]],
    },
  },
  showNanoSpray          = false,
  sightDistance          = 660,
  sonarDistance          = 660,
  turninplace            = 0,
  turnRate               = 372,
  waterline              = 20,

  weapons                = {

    {
      def                = [[carriertargeting]],
      badTargetCategory  = [[SINK]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

    {
      def                = [[DISARM_ROCKET]],
      badTargetCategory  = [[SWIM LAND SUB SHIP HOVER GUNSHIP FIXEDWING]],
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },
    
  },

  weaponDefs             = {

    DISARM_ROCKET        = {
      name                    = [[Disarm Missile]],
      areaOfEffect            = 280,
      collideFriendly         = false,
      cegTag                  = [[bigdisarmtrail]],
      commandfire             = true,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        burst = Shared.BURST_RELIABLE,

        combatrange = 950,
        disarmDamageMult = 1.0,
        disarmDamageOnly = 1,
        disarmTimer      = 10, -- seconds
        radar_homing_distance = 600,

        light_color = [[1 1 1]],
      },
      
      damage                  = {
        default = 15000,
      },

      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:DISARMMISSILE_EXPLOSION]],
      fireStarter             = 0,
      flightTime              = 10,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      model                   = [[wep_empmissile.s3o]],
      noSelfDamage            = true,
      range                   = 3000,
      reloadtime              = 5,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/emp_missile_hit]],
      soundStart              = [[weapon/missile/tacnuke_launch]],
      stockpile               = true,
      stockpileTime           = 10^5,
      tolerance               = 4000,
      tracks                  = true,
      startVelocity           = 200,
      turnrate                = 30000,
      waterWeapon             = false,
      weaponAcceleration      = 400,
      weaponTimer             = 1.4,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1200,
    },

    carriertargeting   = {
      name                    = [[Fake Targeting Weapon]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1E-06,
        planes  = 1E-06,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      flightTime              = 1,
      impactOnly              = true,
      interceptedByShieldType = 1,
      range                   = 1000,
      reloadtime              = 1.233,
      size                    = 1E-06,
      smokeTrail              = false,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turnrate                = 1000000000,
      turret                  = true,
      weaponAcceleration      = 20000,
      weaponTimer             = 0.5,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 20000,
    },

  },

  featureDefs            = {

    DEAD  = {
      CollisionSphereScale   = 0.6,
      collisionVolumeOffsets = [[-5 -10 0]],
      collisionVolumeScales  = [[80 80 240]],
      collisionVolumeType    = [[CylZ]],
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[shipcarrier_dead.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4b.s3o]],
    },

  },

} }
