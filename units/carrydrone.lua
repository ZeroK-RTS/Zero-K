unitDef = {
  unitname            = [[carrydrone]],
  name                = [[Gull]],
  description         = [[Carrier Drone]],
  acceleration        = 0.3,
  airHoverFactor      = 4,
  amphibious          = true,
  bankscale           = [[1]],
  brakeRate           = 0.24,
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
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collisionVolumeOffsets   = [[0 0 0]],
  collisionVolumeScales    = [[26 26 26]],
  collisionVolumeType      = [[ellipsoid]],
  collide             = false,
  cruiseAlt           = 100,
  explodeAs           = [[TINY_BUILDINGEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hideDamage          = true,
  hoverAttack         = true,
  iconType            = [[smallgunship]],
  maneuverleashlength = [[900]],
  maxDamage           = 180,
  maxVelocity         = 8.56,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[carrydrone.s3o]],
  reclaimable         = false,
  script              = [[carrydrone.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[TINY_BUILDINGEX]],
  
  customParams        = {
	helptext       = [[Carrier drones accompany their parent ship, guarding it and sharing its attack targets. They cannot venture far from it on their own, however. The Carrier can produce a pair of drones every 15 seconds, up to a total of 8.]],
	description_de = [[Trägerdrohne]],
	helptext_de    = [[Die Drohnen schutzen den Traeger und teilen seine Ziele, aber sie koennen nicht zu weit allein gehen. Der Traeger herstellt ein Paar Drohnen jede 15 Sekunden, bis zu 8.]],

	is_drone = 1,
	modelradius    = [[13]],
  },
  
  
  sfxtypes            = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:emg_shells_m]],
    },

  },
  sightDistance       = 500,
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
  
      customParams			= {
		light_camera_height = 2000,
		light_color = [[0.95 0.91 0.48]],
		light_radius = 150,
      },

      damage                  = {
        default = 8,
        subs    = 0.4,
      },

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
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1000,
    },

  },

}

return lowerkeys({ carrydrone = unitDef })
