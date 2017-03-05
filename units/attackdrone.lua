unitDef = {
  unitname            = [[attackdrone]],
  name                = [[Firefly]],
  description         = [[Attack Drone]],
  acceleration        = 0.3,
  airHoverFactor      = 4,
  brakeRate           = 0.24,
  buildCostMetal      = 50,
  builder             = false,
  buildPic            = [[attackdrone.png]],
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collide             = false,
  cruiseAlt           = 100,
  explodeAs           = [[TINY_BUILDINGEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverAttack         = true,
  iconType            = [[fighter]],
  maxDamage           = 180,
  maxVelocity         = 7,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[attackdrone.s3o]],
  reclaimable         = false,
  refuelTime          = 10,
  script              = [[attackdrone.lua]],
  selfDestructAs      = [[TINY_BUILDINGEX]],
  
  customParams        = {
	description_de  = [[Kampfdrohne]],
	description_fr  = [[Drone d'attaque]],
	helptext        = [[The Firefly is an attack drone with a weak high precision pulse laser. They can protect their parent unit from light enemy units. They do not share stealth with it though, so they can also betray the presence of a cloaked commander.]],
	helptext_de	    = [[Der Firefly ist eine Kampfdrohne, die seinen Besitzer schutzt.]],
	helptext_fr	    = [[La Luciole est un drone miniature d'attaque autonome équipé d'un faible laser pulsé. Un commandant en possède deux qui patrouillent autour de lui et le protêge efficacement des petites unités adverses. Néanmoins leur présence peut trahir un commandant invisible.]],

	is_drone = 1,
  },
  
  
  sfxtypes            = {

    explosiongenerators = {
    },

  },
  sightDistance       = 500,
  turnRate            = 792,
  upright             = true,

  weapons             = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 90,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    LASER      = {
      name                    = [[Light Particle Beam]],
      beamDecay               = 0.9,
      beamTime                = 1/30,
      beamttl                 = 60,
      coreThickness           = 0.25,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,
  
      customParams			= {
		light_camera_height = 1800,
		light_color = [[0.25 1 0.25]],
		light_radius = 130,
      },

      damage                  = {
        default = 32,
        subs    = 1.6,
      },

      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.25,
      minIntensity            = 1,
      range                   = 250,
      reloadtime              = 0.8,
      rgbColor                = [[0 1 0]],
      soundStart              = [[weapon/laser/mini_laser]],
      soundStartVolume        = 4,
      thickness               = 2.165,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },
  },

}

return lowerkeys({ attackdrone = unitDef })
