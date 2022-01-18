return { gunshipbomb = {
  unitname               = [[gunshipbomb]],
  name                   = [[Blastwing]],
  description            = [[Flying Bomb/Scout (Burrows)]],
  acceleration           = 0.25,
  brakeRate              = 0.2,
  buildCostMetal         = 45,
  builder                = false,
  buildPic               = [[gunshipbomb.png]],
  canFly                 = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collide                = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[20 20 20]],
  collisionVolumeType    = [[ellipsoid]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[32 32 32]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],
  cruiseAlt              = 30,

  customParams           = {
    landflystate   = [[1]],
    idle_cloak = 1,
  },

  explodeAs              = [[gunshipbomb_EXPLOSION]],
  --fireState              = 0,
  floater                = true,
  footprintX             = 2,
  footprintZ             = 2,
  hoverAttack            = true,
  iconType               = [[gunshipspecial]],
  kamikaze               = true,
  kamikazeDistance       = 60,
  kamikazeUseLOS         = true,
  maneuverleashlength    = [[1240]],
  maxDamage              = 100,
  maxSlope               = 36,
  maxVelocity            = 8.2,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[f-1.s3o]],
  script                 = [[gunshipbomb.lua]],
  selfDestructAs         = [[gunshipbomb_EXPLOSION]],
  selfDestructCountdown  = 0,
  sightDistance          = 500,
  turnRate               = 1144,
  upright                = false,
  workerTime             = 0,
  
  featureDefs            = {

    DEAD      = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[wreck2x2b.s3o]],
    },

    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

  weaponDefs = {
    gunshipbomb_EXPLOSION = {
      name               = "Blastwing Explosion",
      areaOfEffect       = 256,
      craterBoost        = 1,
      craterMult         = 3.5,

      customParams          = {
        setunitsonfire = "1",
        burntime = 30,

        area_damage = 1,
        area_damage_radius = 128,
        area_damage_dps = 25,
        area_damage_duration = 25,

        --lups_heat_fx = [[firewalker]],
      },

      damage = {
        default = 40,
        planes  = 40,
      },

      edgeeffectiveness  = 0.7,
      explosionGenerator = [[custom:napalm_gunshipbomb]],
      explosionSpeed     = 10000,
      firestarter        = 180,
      impulseBoost       = 0,
      impulseFactor      = 0.4,
      soundHit           = "explosion/ex_med17",
    },
  }
} }
