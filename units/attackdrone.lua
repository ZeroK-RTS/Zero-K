unitDef = {
  unitname            = [[attackdrone]],
  name                = [[Firefly]],
  description         = [[Attack Drone]],
  acceleration        = 0.3,
  airHoverFactor      = 4,
  amphibious          = true,
  brakeRate           = 0.3,
  buildCostEnergy     = 50,
  buildCostMetal      = 50,
  builder             = false,
  buildPic            = [[attackdrone.png]],
  buildTime           = 50,
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
  mass                = 84,
  maxDamage           = 180,
  maxVelocity         = 7,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[attackdrone.s3o]],
  reclaimable         = false,
  refuelTime          = 10,
  script              = [[attackdrone.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[TINY_BUILDINGEX]],
  
  customParams        = {
	description_de  = [[Kampfdrohne]],
	description_fr  = [[Drone d'attaque]],
	description_pl  = [[Dron bojowy]],
	helptext        = [[The Firefly is an attack drone with a weak high precision pulse laser. They can protect their parent unit from light enemy units. They do not share stealth with it though, so they can also betray the presence of a cloaked commander.]],
	helptext_de	    = [[Der Firefly ist eine Kampfdrohne, die seinen Besitzer schutzt.]],
	helptext_fr	    = [[La Luciole est un drone miniature d'attaque autonome équipé d'un faible laser pulsé. Un commandant en possède deux qui patrouillent autour de lui et le protêge efficacement des petites unités adverses. Néanmoins leur présence peut trahir un commandant invisible.]],
	helptext_pl     = [[Firefly to dron bojowy, ktory chroni wlasciciela przed lekkimi jednostkami swoim laserem pulsacyjnym.]],

	is_drone = 1,
  },
  
  
  sfxtypes            = {

    explosiongenerators = {
    },

  },

  side                = [[ARM]],
  sightDistance       = 500,
  stealth             = true,
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
      beamTime                = 0.01,
      beamttl                 = 60,
      coreThickness           = 0.25,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting      = 1,

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
      pitchtolerance          = 8192,
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
