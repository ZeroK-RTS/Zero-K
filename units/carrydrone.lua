unitDef = {
  unitname            = [[carrydrone]],
  name                = [[Gull]],
  description         = [[Carrier Drone]],
  acceleration        = 0.3,
  airHoverFactor      = 4,
  amphibious          = true,
  bankscale           = [[1]],
  bmcode              = [[1]],
  brakeRate           = 4.18,
  buildCostEnergy     = 75,
  buildCostMetal      = 75,
  builder             = false,
  buildPic            = [[carrydrone.png]],
  buildTime           = 75,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collide             = false,
  
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[18 14 28]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[ellipsoid]],  
  
  cruiseAlt           = 100,
  defaultmissiontype  = [[VTOL_standby]],
  explodeAs           = [[TINY_BUILDINGEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hideDamage          = true,
  hoverAttack         = true,
  iconType            = [[smallgunship]],
  maneuverleashlength = [[900]],
  mass                = 84,
  maxDamage           = 200,
  maxfuel             = 70,
  maxVelocity         = 8.56,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[carrydrone.s3o]],
  RefuelTime          = 10,
  scale               = [[1]],
  script              = [[carrydrone.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[TINY_BUILDINGEX]],
  
  customParams        = {
	description_de = [[Trägerdrohne]],
	helptext_de    = [[]],
  },
  
  
  sfxtypes            = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:emg_shells_m]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 500,
  smoothAnim          = true,
  stealth             = true,
  steeringmode        = [[1]],
  TEDClass            = [[VTOL]],
  turnRate            = 792,
  upright             = true,

  weapons             = {

    {
      def                = [[ARM_DRONE_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 90,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    ARM_DRONE_WEAPON = {
      name                    = [[Drone EMG]],
      areaOfEffect            = 8,
      burst                   = 3,
      burstrate               = 0.1,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 8,
        subs    = 0.4,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:EMG_HIT]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      range                   = 360,
      reloadtime              = 0.3,
      rgbColor                = [[1 0.95 0.4]],
      size                    = 1.75,
      soundStart              = [[weapon/emg]],
      soundStartVolume        = 2,
      sprayAngle              = 512,
      startsmoke              = [[0]],
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1000,
    },

  },

}

return lowerkeys({ carrydrone = unitDef })
